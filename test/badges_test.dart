import 'package:favorite_places/data/sample_places.dart';
import 'package:favorite_places/models/badges.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/badge_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Place _at(
  String city,
  String country,
  double lat,
  double lng, [
  PlaceCategory category = PlaceCategory.cafe,
]) => Place(
  title: city,
  category: category,
  location: PlaceLocation(
    latitude: lat,
    longitude: lng,
    city: city,
    country: country,
  ),
);

void main() {
  test('no places earns nothing', () {
    expect(earnedBadges(const []), isEmpty);
  });

  test('one place earns First Steps only', () {
    expect(earnedBadges([_at('Rome', 'Italy', 41.9, 12.5)]), {
      AppBadge.firstSteps,
    });
  });

  test('three hikes earn Summit Seeker, two do not', () {
    final hikes = [
      for (var i = 0; i < 3; i++)
        _at('Göreme', 'Türkiye', 38.6, 34.8, PlaceCategory.hike),
    ];
    expect(
      earnedBadges(hikes.take(2).toList()),
      isNot(contains(AppBadge.summitSeeker)),
    );
    expect(earnedBadges(hikes), contains(AppBadge.summitSeeker));
  });

  test('Road Tripper needs two places at least 500 km apart', () {
    final near = [
      _at('Istanbul', 'Türkiye', 41.0, 28.9),
      _at('Bursa', 'Türkiye', 40.2, 29.0),
    ];
    final far = [
      _at('Istanbul', 'Türkiye', 41.0, 28.9),
      _at('Cairo', 'Egypt', 30.0, 31.2),
    ];
    expect(earnedBadges(near), isNot(contains(AppBadge.roadTripper)));
    expect(earnedBadges(far), contains(AppBadge.roadTripper));
  });

  test('the 15 sample places earn the travel badges', () {
    final earned = earnedBadges(samplePlaces());
    expect(
      earned,
      containsAll([
        AppBadge.firstSteps,
        AppBadge.cityHopper,
        AppBadge.globetrotter,
        AppBadge.frequentFlyer,
        AppBadge.roadTripper,
      ]),
    );
    expect(earned, isNot(contains(AppBadge.backpacker)));
  });

  testWidgets('on other profiles the row hides the next-badge hint', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    Future<void> pump({required bool showNext}) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EarnedBadgesRow(
            places: [_at('Rome', 'Italy', 41.9, 12.5)],
            showNext: showNext,
          ),
        ),
      ),
    );

    await pump(showNext: true);
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.textContaining('City Hopper:'), findsOneWidget);

    await pump(showNext: false);
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.textContaining('City Hopper:'), findsNothing);
  });

  testWidgets('several badges overlap, best in front at the left; a tap '
      'shows one full size', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final places = samplePlaces();
    final best = earnedBadges(places).toList().reversed.toList();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: EarnedBadgesRow(places: places)),
      ),
    );

    Finder badge(AppBadge b) => find.byWidgetPredicate(
      (w) => w is BadgeImage && w.badge == b && w.earned,
    );
    final xs = [for (final b in best) tester.getTopLeft(badge(b)).dx];
    expect(xs, [...xs]..sort(), reason: 'best at the left');
    expect(xs[1] - xs[0], 28, reason: 'each covers half of the next');

    await tester.tapAt(
      tester.getTopLeft(badge(best.first)) + const Offset(10, 28),
    );
    await tester.pump(const Duration(milliseconds: 800));
    final big = find.byWidgetPredicate(
      (w) => w is BadgeImage && w.badge == best.first && w.size == 240,
    );
    expect(big, findsOneWidget);
    expect(find.text('Earned'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(big, findsNothing);
  });

  testWidgets('sliding a finger along the row lifts the badge under it', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final places = samplePlaces();
    final best = earnedBadges(places).toList().reversed.toList();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(top: 120),
            child: EarnedBadgesRow(places: places),
          ),
        ),
      ),
    );
    Finder badge(AppBadge b) => find.byWidgetPredicate(
      (w) => w is BadgeImage && w.badge == b && w.earned,
    );
    final start = tester.getTopLeft(badge(best.first)) + const Offset(20, 28);

    double scaleOf(AppBadge b) => tester
        .widget<AnimatedScale>(
          find.ancestor(of: badge(b), matching: find.byType(AnimatedScale)),
        )
        .scale;

    State<StatefulWidget> scaleState(AppBadge b) => tester.state(
      find.ancestor(of: badge(b), matching: find.byType(AnimatedScale)),
    );
    final firstBefore = scaleState(best.first);

    final finger = await tester.startGesture(start);
    await finger.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 800));
    expect(scaleOf(best[1]), 1.4, reason: 'the badge under the finger lifts');
    expect(scaleOf(best.last), 1.0);
    // An untouched badge keeps its own animation, so it doesn't move.
    expect(identical(scaleState(best.first), firstBefore), isTrue);

    await finger.up();
    await tester.pump(const Duration(milliseconds: 800));
    expect(scaleOf(best[1]), 1.0);
  });
}
