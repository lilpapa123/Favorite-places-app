import 'package:favorite_places/data/sample_posts.dart';
import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/screens/places_map.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the map shows places other people shared', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (owner, place) = samplePosts().firstWhere(
      (p) => p.$2.location != null,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoverProvider.overrideWith(
            (ref) => Stream.value([(owner, place)]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.data(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // The test font is wider than the app's; the map's credit line
          // would overflow at full size.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(0.5)),
            child: child!,
          ),
          home: const PlacesMapScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final pin = find.byWidgetPredicate(
      (w) => w is CategoryPin && w.semanticLabel == place.title,
    );
    expect(pin, findsOneWidget);

    await tester.tap(pin);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final name = sampleProfiles.firstWhere((p) => p.uid == owner).name;
    expect(find.textContaining('by $name'), findsOneWidget);
  });
}
