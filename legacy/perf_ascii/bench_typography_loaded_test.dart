// Measures the cost of the app's typography when the Google Fonts are ALREADY
// loaded (the normal, warm-run case), and contrasts it with the
// font-not-available case measured in bench_typography_test.dart.
//
// This test injects the real font files through google_fonts' injectable HTTP
// client (GoogleFonts.config.httpClient) and a fake path_provider, so the
// package's own download -> checksum -> font-loader path runs exactly as it
// does in the app, without hitting the network at test time.
//
// The two TTFs in fixtures/fonts/ are byte-identical to what google_fonts
// downloads for this app (their sha256 is the hash in the gstatic URL).

import 'dart:io';
import 'dart:typed_data';

import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'perf_utils.dart';

const String _ibmUrl =
    'https://fonts.gstatic.com/s/a/d37b0be393abb9e88603a9493e97d0ca660146b93fad3897d22358f3a93e7a05.ttf';
const String _jetbrainsUrl =
    'https://fonts.gstatic.com/s/a/fc34426314d00825ccc768a0c4b1178fe704f04bd947882ef10c2b71b7e355e7.ttf';

/// Serves the two fixture TTFs for the URLs google_fonts asks for.
class _FixtureFontClient extends http.BaseClient {
  _FixtureFontClient(this._bytesByUrl);

  final Map<String, Uint8List> _bytesByUrl;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = _bytesByUrl[request.url.toString()];
    if (bytes == null) {
      return http.StreamedResponse(const Stream<List<int>>.empty(), 404);
    }
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      contentLength: bytes.length,
    );
  }
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

double microsPerCall(int iterations, void Function() body) {
  body(); // warm up
  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    body();
  }
  stopwatch.stop();
  return stopwatch.elapsedMicroseconds / iterations;
}

final TextStyle _plainStyle = TextStyle(
  fontFamily: 'Menlo',
  fontSize: 14,
  height: 1.35,
  fontWeight: FontWeight.w400,
  color: AsciiPalette.ink,
);

Widget textGrid(int count, {required bool useThemeTypography}) {
  return MaterialApp(
    theme: AsciiTheme.data,
    home: Scaffold(
      body: ListView(
        children: [
          for (var i = 0; i < count; i++)
            Text(
              'entry line $i',
              style: useThemeTypography ? AsciiType.body() : _plainStyle,
            ),
        ],
      ),
    ),
  );
}

late Directory _supportDir;

void main() {
  setUpAll(() {
    _supportDir = Directory.systemTemp.createTempSync('fav_places_fonts_');
    final fonts = {
      _ibmUrl: File(
        'test/perf/fixtures/fonts/IBMPlexMono-Regular.ttf',
      ).readAsBytesSync(),
      _jetbrainsUrl: File(
        'test/perf/fixtures/fonts/JetBrainsMono-Regular.ttf',
      ).readAsBytesSync(),
    };
    GoogleFonts.config.allowRuntimeFetching = true;
    GoogleFonts.config.httpClient = _FixtureFontClient(fonts);
    PathProviderPlatform.instance = _FakePathProvider(_supportDir.path);
  });

  tearDownAll(() {
    if (_supportDir.existsSync()) _supportDir.deleteSync(recursive: true);
  });

  test('warm path: per-call cost once the fonts are loaded', () async {
    // Trigger the package's real load path (asset check -> device FS -> HTTP
    // -> checksum -> FontLoader) and give it time to finish.
    GoogleFonts.ibmPlexMono();
    GoogleFonts.jetBrainsMono();
    await Future<void>.delayed(const Duration(milliseconds: 800));

    const iterations = 3000;
    final appStyle = microsPerCall(iterations, () {
      AsciiType.body();
    });
    final meta = microsPerCall(iterations, () {
      AsciiType.meta();
    });
    final googleFont = microsPerCall(iterations, () {
      GoogleFonts.ibmPlexMono();
    });

    // ignore: avoid_print
    print(bench('type.warm.ascii_style_us', appStyle.toStringAsFixed(3), 'us'));
    // ignore: avoid_print
    print(bench('type.warm.ascii_meta_us', meta.toStringAsFixed(3), 'us'));
    // ignore: avoid_print
    print(
      bench('type.warm.google_fonts_us', googleFont.toStringAsFixed(3), 'us'),
    );
    // ignore: avoid_print
    print(
      bench(
        'type.warm.per_frame_18_texts_us',
        (appStyle * 18).toStringAsFixed(1),
        'us',
      ),
    );
  });

  testWidgets('warm path: frame with 300 text widgets, app vs plain style', (
    tester,
  ) async {
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
    print(
      bench('type.warm.frame_300_texts_app', median(app).toStringAsFixed(2), 'ms'),
    );
    // ignore: avoid_print
    print(
      bench(
        'type.warm.frame_300_texts_plain',
        median(plain).toStringAsFixed(2),
        'ms',
      ),
    );
    // ignore: avoid_print
    print(
      bench(
        'type.warm.frame_300_extra_ms',
        (median(app) - median(plain)).toStringAsFixed(2),
        'ms',
      ),
    );
  });
}
