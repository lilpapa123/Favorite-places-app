import 'package:favorite_places/main.dart';
import 'package:favorite_places/providers/settings_provider.dart';
import 'package:favorite_places/screens/discover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Arabic keeps the left-to-right layout, only words change', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'locale': 'ar'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    final page = tester.element(find.byType(DiscoverScreen));
    expect(Localizations.localeOf(page).languageCode, 'ar');
    expect(Directionality.of(page), TextDirection.ltr);
  });
}
