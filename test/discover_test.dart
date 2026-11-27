import 'dart:math';

import 'package:favorite_places/data/sample_posts.dart';
import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/screens/discover.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Finder _circleButton(String label) => find.byWidgetPredicate(
  (w) => w is CircleIconButton && w.semanticLabel == label,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('search opens from the icon, with filters inside it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final posts = samplePosts();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoverProvider.overrideWith((ref) => Stream.value(posts)),
        ],
        child: MaterialApp(
          theme: AppTheme.data(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DiscoverScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final searchBox = find.widgetWithText(TextField, 'Find a favorite place');
    // No search bar or filter pills until the icon is tapped.
    expect(searchBox, findsNothing);
    expect(find.text('All · ${posts.length}'), findsNothing);

    await tester.tap(_circleButton('Find a favorite place'));
    await tester.pumpAndSettle();
    expect(searchBox, findsOneWidget);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('All · ${posts.length}'), findsOneWidget);
    await tester.tap(find.text('Cafés'));
    await tester.pumpAndSettle();
    expect(find.text('Cafés'), findsNothing); // the sheet closed
    final firstCafe = posts.firstWhere(
      (p) => p.$2.category == PlaceCategory.cafe,
    );
    final firstOther = posts.firstWhere(
      (p) => p.$2.category != PlaceCategory.cafe,
    );
    expect(find.text(firstCafe.$2.title), findsOneWidget);
    expect(find.text(firstOther.$2.title), findsNothing);

    // A tap outside keeps the bar while a filter is on...
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    expect(searchBox, findsOneWidget);
    expect(find.text(firstOther.$2.title), findsNothing);

    // ...and closes it once there is nothing to search for.
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All · ${posts.length}'));
    await tester.pumpAndSettle();
    expect(searchBox, findsOneWidget);
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    expect(searchBox, findsNothing);
    expect(find.text(posts.first.$2.title), findsOneWidget);
  });

  test('a reshuffle never keeps the same order', () {
    final ids = ['a', 'b'];
    for (var seed = 0; seed < 20; seed++) {
      final shuffled = reshuffle(ids, Random(seed));
      expect(shuffled, unorderedEquals(ids));
      expect(shuffled, isNot(ids));
    }
    expect(reshuffle(['a']), ['a']);
  });

  testWidgets('pulling down with no new posts shows them in another order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final posts = samplePosts().take(2).toList();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoverProvider.overrideWith((ref) => Stream.value(posts)),
        ],
        child: MaterialApp(
          theme: AppTheme.data(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DiscoverScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    double top(String title) => tester.getTopLeft(find.text(title)).dy;
    final first = posts[0].$2.title;
    final second = posts[1].$2.title;
    expect(top(first), lessThan(top(second)));

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(top(second), lessThan(top(first)));
  });
}
