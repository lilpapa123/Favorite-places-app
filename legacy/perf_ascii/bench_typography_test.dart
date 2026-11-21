// Typography cost.
//
// lib/theme/app_theme.dart builds every TextStyle by calling
// GoogleFonts.ibmPlexMono() / GoogleFonts.jetBrainsMono(), and every widget
// build calls AsciiType.*(). The app bundles no font assets (pubspec.yaml has
// the assets block commented out), so at runtime google_fonts has to resolve
// (and on a cold start, download) the font. This file measures what that
// macro costs per call and per frame.

import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'perf_utils.dart';

const TextStyle plainStyle = TextStyle(
  fontFamily: 'Menlo',
  fontSize: 14,
  height: 1.35,
  fontWeight: FontWeight.w400,
  color: AsciiPalette.ink,
);

double microsPerCall(int iterations, void Function() body) {
  body(); // warm up
  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    body();
  }
  stopwatch.stop();
  return stopwatch.elapsedMicroseconds / iterations;
}

Widget textGrid(int count, {required bool useThemeTypography}) {
  return MaterialApp(
    theme: AsciiTheme.data,
    home: Scaffold(
      body: ListView(
        children: [
          for (var i = 0; i < count; i++)
            Text(
              'entry line $i',
              style: useThemeTypography ? AsciiType.body() : plainStyle,
            ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('per-call cost of an app TextStyle vs a plain TextStyle', () {
    const iterations = 3000;

    final appStyle = microsPerCall(iterations, () {
      AsciiType.body();
    });
    final googleFont = microsPerCall(iterations, () {
      GoogleFonts.ibmPlexMono();
    });
    // A plain TextStyle created at runtime (not a const reference, which the
    // compiler folds away) as the allocation-cost reference point.
    final plain = microsPerCall(iterations, () {
      TextStyle(
        fontFamily: 'Menlo',
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w400,
        color: AsciiPalette.ink,
      );
    });

    // ignore: avoid_print
    print(bench('type.ascii_style_us_per_call', appStyle.toStringAsFixed(3), 'us'));
    // ignore: avoid_print
    print(bench('type.google_fonts_call_us', googleFont.toStringAsFixed(3), 'us'));
    // ignore: avoid_print
    print(bench('type.plain_new_style_us', plain.toStringAsFixed(4), 'us'));
    // ignore: avoid_print
    print(
      bench(
        'type.extra_us_vs_plain_style',
        (appStyle - plain).toStringAsFixed(2),
        'us',
      ),
    );
  });

  test('cost of building the ThemeData (AsciiTheme.data)', () {
    // ThemeData itself is constructed on every `AsciiTheme.data` access, and it
    // is a getter, so every rebuild of MyApp pays for it.
    final samples = <double>[];
    for (var i = 0; i < 15; i++) {
      final stopwatch = Stopwatch()..start();
      final theme = AsciiTheme.data;
      stopwatch.stop();
      samples.add(stopwatch.elapsedMicroseconds / 1000);
      // ignore: unnecessary_statements
      theme;
    }
    // ignore: avoid_print
    print(bench('theme.build_ms', median(samples).toStringAsFixed(2), 'ms'));
    // ignore: avoid_print
    print(bench('theme.build_samples', formatSamples(samples), 'ms'));
  });

  testWidgets('frame cost of 300 text widgets: app typography vs plain', (tester) async {
    Future<double> measure(bool useThemeTypography) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(
        textGrid(300, useThemeTypography: useThemeTypography),
      );
      stopwatch.stop();
      return stopwatch.elapsedMicroseconds / 1000;
    }

    final app = <double>[];
    final plain = <double>[];
    for (var i = 0; i < 5; i++) {
      app.add(await measure(true));
      plain.add(await measure(false));
    }

    // ignore: avoid_print
    print(bench('type.frame_300_texts_app', median(app).toStringAsFixed(2), 'ms'));
    // ignore: avoid_print
    print(bench('type.frame_300_texts_plain', median(plain).toStringAsFixed(2), 'ms'));
    // ignore: avoid_print
    print(
      bench(
        'type.frame_300_extra_ms',
        (median(app) - median(plain)).toStringAsFixed(2),
        'ms',
      ),
    );
  });
}
