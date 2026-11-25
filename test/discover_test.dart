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

    // Closing search clears the filter too.
    await tester.tap(_circleButton('Close search'));
    await tester.pumpAndSettle();
    expect(searchBox, findsNothing);
    expect(find.text(posts.first.$2.title), findsOneWidget);
  });
}
