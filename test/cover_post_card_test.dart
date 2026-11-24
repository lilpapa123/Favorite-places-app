import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/cover_post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'sample-maya';
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows type, headline, person, area, age and quote', (
    tester,
  ) async {
    var tapped = false;
    final place = Place(
      title: 'Karaköy morning coffee',
      category: PlaceCategory.cafe,
      note: 'Simit and the ferries.',
      createdAt: DateTime.now().subtract(const Duration(hours: 14, minutes: 5)),
      location: const PlaceLocation(
        latitude: 41.02,
        longitude: 28.97,
        area: 'Karaköy',
        city: 'Istanbul',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.data(Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                // A sample person: their profile needs no Firestore.
                CoverPostCard(
                  owner: 'sample-zeynep',
                  place: place,
                  onTap: () => tapped = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CAFÉ'), findsOneWidget);
    expect(find.text('Karaköy morning coffee'), findsOneWidget);
    expect(find.text('Zeynep Aydın'), findsOneWidget);
    expect(find.text('Karaköy, Istanbul · 14h ago'), findsOneWidget);
    expect(find.text('“Simit and the ferries.”'), findsOneWidget);

    await tester.tap(find.text('Karaköy morning coffee'));
    expect(tapped, isTrue);
  });

  testWidgets('comment and share buttons open their sheets', (tester) async {
    final place = Place(
      id: 'sample-post-test',
      title: 'Balat colorful streets',
      location: const PlaceLocation(latitude: 41.03, longitude: 28.95),
    );
    // Phone-sized, so the buttons at the bottom of the photo are on screen.
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(_User())),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                CoverPostCard(
                  owner: 'sample-zeynep',
                  place: place,
                  onTap: () => fail('the card took the button tap'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Comments'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Love this street');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Love this street'), findsOneWidget);
    expect(find.textContaining('Maya Lin', findRichText: true), findsWidgets);

    await tester.tapAt(const Offset(10, 10)); // close the sheet
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.text('Share to other apps'), findsOneWidget);
  });

  test('Turkish upper case keeps the dotted İ', () {
    expect(upperCaseFor('tr', 'Bisiklet'), 'BİSİKLET');
    expect(upperCaseFor('tr', 'Manzara noktası'), 'MANZARA NOKTASI');
    expect(upperCaseFor('en', 'Viewpoint'), 'VIEWPOINT');
  });
}
