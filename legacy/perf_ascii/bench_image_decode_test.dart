// Measures what the app actually pays to show photos.
//
// The app renders every thumbnail through `Image.file` with NO target size
// (lib/widgets/ascii_photo.dart -> Image.file(image, fit: fit)). Flutter then
// decodes the image at its full intrinsic resolution and keeps that bitmap in
// the ImageCache, even though the card renders it in a 56x56 box.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/palces_list.dart';
import 'package:favorite_places/widgets/place_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'perf_utils.dart';

Future<ui.Image> decode(
  Uint8List bytes, {
  int? targetWidth,
  int? targetHeight,
}) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

Future<List<double>> timeDecode(
  Uint8List bytes, {
  int? targetWidth,
  int? targetHeight,
  int runs = 5,
}) async {
  final samples = <double>[];
  for (var i = 0; i < runs; i++) {
    final stopwatch = Stopwatch()..start();
    final image = await decode(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds / 1000);
    image.dispose();
  }
  return samples;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decoded bitmap memory: full-resolution vs thumbnail-sized', () async {
    final bytes = File(fixturePhoto1200).readAsBytesSync();

    // What the app does today: decode at intrinsic size.
    final full = await decode(bytes);
    final fullBytes = full.width * full.height * 4; // RGBA8888
    final fullWidth = full.width;
    final fullHeight = full.height;
    full.dispose();

    // What a 56x56 thumbnail needs at DPR 2 / DPR 3.
    final dpr2 = await decode(bytes, targetWidth: 112, targetHeight: 84);
    final dpr2Bytes = dpr2.width * dpr2.height * 4;
    dpr2.dispose();

    final dpr3 = await decode(bytes, targetWidth: 168, targetHeight: 126);
    final dpr3Bytes = dpr3.width * dpr3.height * 4;
    dpr3.dispose();

    // ignore: avoid_print
    print(bench('decode.photo_capture', bytes.length, 'bytes_jpeg'));
    // ignore: avoid_print
    print(bench('decode.full_size', '${fullWidth}x$fullHeight', 'px'));
    // ignore: avoid_print
    print(bench('decode.full_size_bitmap', fullBytes, 'bytes'));
    // ignore: avoid_print
    print(bench('decode.dpr2_thumb_bitmap', dpr2Bytes, 'bytes'));
    // ignore: avoid_print
    print(bench('decode.dpr3_thumb_bitmap', dpr3Bytes, 'bytes'));
    // ignore: avoid_print
    print(
      bench(
        'decode.memory_saving_dpr3',
        (fullBytes / dpr3Bytes).toStringAsFixed(1),
        'x',
      ),
    );

    expect(fullWidth, 1200);
    expect(fullHeight, 900);
    expect(fullBytes, 4320000);
    expect(dpr3Bytes, 84672);
  });

  test('decode time: full-resolution vs thumbnail-sized', () async {
    final bytes = File(fixturePhoto1200).readAsBytesSync();
    // Warm up the codec / file caches so the comparison is not dominated by
    // first-touch overhead.
    (await decode(bytes)).dispose();
    (await decode(bytes, targetWidth: 168, targetHeight: 126)).dispose();

    final full = await timeDecode(bytes);
    final thumb = await timeDecode(bytes, targetWidth: 168, targetHeight: 126);

    // ignore: avoid_print
    print(bench('decode.time_full_size', median(full).toStringAsFixed(2), 'ms'));
    // ignore: avoid_print
    print(
      bench('decode.time_dpr3_thumb', median(thumb).toStringAsFixed(2), 'ms'),
    );
    // ignore: avoid_print
    print(bench('decode.time_full_samples', formatSamples(full), 'ms'));
    // ignore: avoid_print
    print(bench('decode.time_thumb_samples', formatSamples(thumb), 'ms'));

    expect(full.length, 5);
  });

  testWidgets(
    'widget-level: feed with photos fills ImageCache with full-resolution '
    'bitmaps',
    (tester) async {
      final cache = PaintingBinding.instance.imageCache;
      cache.clear();
      cache.clearLiveImages();

      final dir = prepareDistinctPhotos(12);
      addTearDown(() => dir.deleteSync(recursive: true));
      final places = [
        for (var i = 0; i < 12; i++)
          Place(title: 'place $i', image: File('${dir.path}/photo_$i.jpg')),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AsciiTheme.data,
          home: Scaffold(body: PalcesList(places: places)),
        ),
      );
      await settleImages(tester);

      final visibleCards = find.byType(PlaceCard).evaluate().length;
      final expectedFullRes = visibleCards * 1200 * 900 * 4;

      // ignore: avoid_print
      print(bench('imagecache.cards_built_of_12', visibleCards, 'cards'));
      // ignore: avoid_print
      print(bench('imagecache.live_images', cache.liveImageCount, 'images'));
      // ignore: avoid_print
      print(bench('imagecache.current_size_bytes', cache.currentSizeBytes, 'bytes'));
      // ignore: avoid_print
      print(bench('imagecache.expected_full_res_bytes', expectedFullRes, 'bytes'));
      // ignore: avoid_print
      print(bench('imagecache.max_size_bytes', cache.maximumSizeBytes, 'bytes'));

      // The finding: the cache holds full 1200x900 bitmaps for 56px
      // thumbnails (4.32 MB each) instead of 168x126 ones (84.7 KB each).
      expect(cache.currentSizeBytes, greaterThan(1000000));
      expect(
        cache.currentSizeBytes,
        greaterThanOrEqualTo((visibleCards * 4320000 * 0.9).round()),
      );
    },
  );

  testWidgets(
    'widget-level: same cards, 1200x900 source vs pre-sized 168x126 source',
    (tester) async {
      final cache = PaintingBinding.instance.imageCache;

      Future<int> measureFeed(List<File> photos) async {
        cache.clear();
        cache.clearLiveImages();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        final places = [
          for (var i = 0; i < photos.length; i++)
            Place(title: 'place $i', image: photos[i]),
        ];
        await tester.pumpWidget(
          MaterialApp(
            theme: AsciiTheme.data,
            home: Scaffold(body: PalcesList(places: places)),
          ),
        );
        await settleImages(tester);
        return cache.currentSizeBytes;
      }

      // Scenario A: 8 cards sharing one 1200x900 file -> 1 cache entry.
      final fullBytes = await measureFeed(
        List<File>.filled(8, File(fixturePhoto1200)),
      );

      // Scenario B: 8 cards, each with a pre-sized 168x126 file -> 8 entries.
      final thumbsDir = prepareDistinctPhotos(8, fixture: fixturePhoto168);
      addTearDown(() => thumbsDir.deleteSync(recursive: true));
      final thumbBytes = await measureFeed([
        for (var i = 0; i < 8; i++) File('${thumbsDir.path}/photo_$i.jpg'),
      ]);

      // ignore: avoid_print
      print(bench('imagecache.one_1200x900_entry', fullBytes, 'bytes'));
      // ignore: avoid_print
      print(bench('imagecache.8x168x126_entries', thumbBytes, 'bytes'));

      expect(fullBytes, greaterThan(4000000));
      expect(thumbBytes, lessThan(8 * 200000));
    },
  );
}
