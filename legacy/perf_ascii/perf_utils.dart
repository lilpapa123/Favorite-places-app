// Shared helpers for the performance benchmarks in this folder.
//
// Important caveats, also documented in test/perf/README.md:
//  * `flutter test` runs in DEBUG mode (JIT, all assertions, no AOT). Absolute
//    millisecond values are therefore upper bounds and are much slower than a
//    profile/release build on a real device. Use them for A/B comparisons and
//    for memory numbers (memory is mode-independent).
//  * `flutter test` runs with a software renderer: `pump()` measures
//    build + layout + paint, but no GPU rasterisation.
//  * The default test surface is 800x600 logical px at devicePixelRatio 3.0.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A realistic photo: what `image_picker(maxWidth: 1200, imageQuality: 85)`
/// produces on a modern phone (1200x900, 4:3).
const String fixturePhoto1200 = 'test/perf/fixtures/photo_1200x900.jpg';

/// The same photo pre-scaled to the thumbnail's physical size
/// (56 logical px * DPR 3 = 168px wide). Used as the "correctly sized decode"
/// comparison without touching app code.
const String fixturePhoto168 = 'test/perf/fixtures/photo_168x126.jpg';

/// Emits a machine-readable benchmark line. Kept greppable so results can be
/// captured with: flutter test test/perf | grep '^BENCH|'
String bench(String name, Object value, String unit) =>
    'BENCH|$name|$value|$unit';

double _sorted(List<double> xs) {
  final copy = List<double>.of(xs)..sort();
  return copy.isEmpty ? 0 : copy[copy.length ~/ 2];
}

double median(List<double> xs) => _sorted(xs);

double percentile(List<double> xs, double p) {
  if (xs.isEmpty) return 0;
  final copy = List<double>.of(xs)..sort();
  final index = ((copy.length - 1) * p).round().clamp(0, copy.length - 1);
  return copy[index];
}

/// Times one synchronous frame (build + layout + paint) in wall-clock
/// milliseconds.
Future<double> timedPump(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 16),
}) async {
  final stopwatch = Stopwatch()..start();
  await tester.pump(duration);
  stopwatch.stop();
  return stopwatch.elapsedMicroseconds / 1000;
}

/// Measures the wall-clock cost of the first frame for [builder], [runs] times.
/// Each run tears down the previous tree first so the tree build is fresh.
Future<List<double>> timeFirstFrames(
  WidgetTester tester,
  Widget Function() builder, {
  int runs = 5,
}) async {
  final samples = <double>[];
  for (var i = 0; i < runs; i++) {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final stopwatch = Stopwatch()..start();
    await tester.pumpWidget(builder());
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds / 1000);
  }
  return samples;
}

/// Lets real asynchronous work (image decode / disk IO) complete, then pumps a
/// frame. `Image.file` decoding needs `runAsync`; plain `pump` cannot advance
/// real IO futures.
Future<void> settleImages(WidgetTester tester, {int iterations = 12}) async {
  for (var i = 0; i < iterations; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 8)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Scrolls the enclosing scrollable by [frames] * [delta] while timing every
/// frame. Returns per-frame wall-clock milliseconds.
Future<List<double>> timedScroll(
  WidgetTester tester, {
  required double delta,
  int frames = 30,
}) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(Scrollable).first),
  );
  final samples = <double>[];
  for (var i = 0; i < frames; i++) {
    await gesture.moveBy(Offset(0, delta));
    samples.add(await timedPump(tester));
  }
  await gesture.up();
  await tester.pump();
  return samples;
}

String formatSamples(List<double> samples) {
  final mean = samples.reduce((a, b) => a + b) / samples.length;
  return 'n=${samples.length} mean=${mean.toStringAsFixed(2)} '
      'median=${median(samples).toStringAsFixed(2)} '
      'p90=${percentile(samples, 0.9).toStringAsFixed(2)} '
      'max=${samples.reduce(math.max).toStringAsFixed(2)}';
}

/// Copies the 1200x900 fixture to [count] uniquely named files so that each
/// `FileImage` gets its own cache entry (as if the user had taken [count]
/// distinct photos).
Directory prepareDistinctPhotos(int count, {String fixture = fixturePhoto1200}) {
  final dir = Directory.systemTemp.createTempSync('fav_places_perf_');
  final bytes = File(fixture).readAsBytesSync();
  for (var i = 0; i < count; i++) {
    File('${dir.path}/photo_$i.jpg').writeAsBytesSync(bytes);
  }
  return dir;
}
