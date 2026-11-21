// Screen-level frame benchmarks: first frame, idle-frame production, scroll
// cost and how it scales with the number of saved places.
//
// Uses the real app widgets (PalcesScreen / PalcesList / PlaceCard /
// PlacesDetailScreen / AddedPlaceScreen) so nothing is re-implemented here.

import 'dart:io';

import 'package:favorite_places/main.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/screens/add_place.dart';
import 'package:favorite_places/screens/palces.dart';
import 'package:favorite_places/screens/places_detail.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/palces_list.dart';
import 'package:favorite_places/widgets/place_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'perf_utils.dart';

/// The app's own root widget, exactly as the app runs it.
Widget appRoot() => const ProviderScope(child: MyApp());

/// A feed of [count] places rendered by the real list widget.
Widget feed(int count, {List<File>? photos}) => MaterialApp(
  theme: AsciiTheme.data,
  home: Scaffold(
    body: PalcesList(
      places: [
        for (var i = 0; i < count; i++)
          Place(title: 'place $i', image: photos?[i % photos.length]),
      ],
    ),
  ),
);

void main() {
  setUpAll(() {
    // The app does not bundle its Google Fonts; in the test environment there
    // is no network/platform channel, so turn runtime fetching off to keep the
    // benchmarks deterministic (this matches the app's existing tests).
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('first frame: cold home screen (empty state)', (tester) async {
    final samples = await timeFirstFrames(tester, appRoot, runs: 7);
    // ignore: avoid_print
    print(bench('frame.cold_home_first_frame', median(samples).toStringAsFixed(2), 'ms'));
    // ignore: avoid_print
    print(bench('frame.cold_home_first_frame_samples', formatSamples(samples), 'ms'));
  });

  testWidgets('first frame: add-place form', (tester) async {
    final samples = await timeFirstFrames(
      tester,
      () => const ProviderScope(
        child: MaterialApp(home: AddedPlaceScreen()),
      ),
      runs: 5,
    );
    // ignore: avoid_print
    print(bench('frame.cold_add_form_first_frame', median(samples).toStringAsFixed(2), 'ms'));
  });

  testWidgets('first frame: place detail screen with photo', (tester) async {
    final place = Place(title: 'cafe', image: File(fixturePhoto1200));
    final samples = await timeFirstFrames(
      tester,
      () => MaterialApp(
        theme: AsciiTheme.data,
        home: PlacesDetailScreen(place: place),
      ),
      runs: 5,
    );
    // ignore: avoid_print
    print(bench('frame.cold_detail_first_frame', median(samples).toStringAsFixed(2), 'ms'));
  });

  testWidgets('idle: the blinking cursor renders frames forever', (tester) async {
    await tester.pumpWidget(appRoot());
    await tester.pump();

    // Nothing is touched from here on: measure how much CPU the UI burns while
    // sitting still for one simulated second.
    final samples = <double>[];
    var scheduled = 0;
    for (var i = 0; i < 60; i++) {
      samples.add(await timedPump(tester));
      if (tester.binding.hasScheduledFrame) scheduled++;
    }
    final total = samples.reduce((a, b) => a + b);

    // ignore: avoid_print
    print(bench('idle.frames_scheduled_of_60', scheduled, 'frames'));
    // ignore: avoid_print
    print(bench('idle.cpu_per_second_blinking', total.toStringAsFixed(2), 'ms'));
    // ignore: avoid_print
    print(bench('idle.cpu_per_frame', median(samples).toStringAsFixed(3), 'ms'));
    expect(scheduled, 60, reason: 'blinking cursor keeps every vsync busy');
  });

  testWidgets('idle with animations disabled: no frames are scheduled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AsciiTheme.data,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const PalcesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final samples = <double>[];
    var scheduled = 0;
    for (var i = 0; i < 60; i++) {
      samples.add(await timedPump(tester));
      if (tester.binding.hasScheduledFrame) scheduled++;
    }
    final total = samples.reduce((a, b) => a + b);

    // ignore: avoid_print
    print(bench('idle_reduced.frames_scheduled_of_60', scheduled, 'frames'));
    // ignore: avoid_print
    print(bench('idle_reduced.cpu_per_second', total.toStringAsFixed(2), 'ms'));
    expect(scheduled, 0);
  });

  testWidgets('scroll cost scaling: 10 / 60 / 200 places (no photos)', (tester) async {
    for (final count in [10, 60, 200]) {
      await tester.pumpWidget(feed(count));
      await tester.pump();
      final built = find.byType(PlaceCard).evaluate().length;
      final samples = await timedScroll(tester, delta: -24, frames: 30);

      // ignore: avoid_print
      print(bench('scroll.no_photos.places_$count.frames', formatSamples(samples), 'ms'));
      // ignore: avoid_print
      print(bench('scroll.no_photos.places_$count.built_widgets', built, 'cards'));
      expect(
        built,
        lessThan(40),
        reason: 'ListView must stay lazy with $count items',
      );
    }
  });

  testWidgets('scroll cost: photo cards, 1200x900 source vs pre-sized source', (tester) async {
    final fullPhoto = File(fixturePhoto1200);
    final bigDir = prepareDistinctPhotos(8);
    final smallDir = prepareDistinctPhotos(8, fixture: fixturePhoto168);
    addTearDown(() => bigDir.deleteSync(recursive: true));
    addTearDown(() => smallDir.deleteSync(recursive: true));

    final bigPhotos = [
      for (var i = 0; i < 8; i++) File('${bigDir.path}/photo_$i.jpg'),
    ];
    final smallPhotos = [
      for (var i = 0; i < 8; i++) File('${smallDir.path}/photo_$i.jpg'),
    ];

    Future<void> measure(String label, List<File> photos) async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(feed(60, photos: photos));
      await settleImages(tester);

      final samples = await timedScroll(tester, delta: -24, frames: 30);
      final cache = PaintingBinding.instance.imageCache;
      // ignore: avoid_print
      print(bench('scroll.$label.frames', formatSamples(samples), 'ms'));
      // ignore: avoid_print
      print(bench('scroll.$label.imagecache_bytes', cache.currentSizeBytes, 'bytes'));
      // ignore: avoid_print
      print(bench('scroll.$label.live_images', cache.liveImageCount, 'images'));
    }

    await measure('photo_1200x900', bigPhotos);
    await measure('photo_168x126', smallPhotos);
    expect(fullPhoto.existsSync(), isTrue);
  });

  testWidgets('screen: repaint of the whole home screen', (tester) async {
    await tester.pumpWidget(appRoot());
    await tester.pump();
    // Force a rebuild of the screen (what happens whenever state changes).
    final samples = <double>[];
    for (var i = 0; i < 20; i++) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AsciiTheme.data,
            home: const PalcesScreen(),
          ),
        ),
      );
      samples.add(await timedPump(tester));
    }
    // ignore: avoid_print
    print(bench('frame.home_rebuild', median(samples).toStringAsFixed(2), 'ms'));
  });
}
