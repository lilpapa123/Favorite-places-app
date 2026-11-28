import 'dart:async';

import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/settings_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/screens/account.dart';
import 'package:favorite_places/screens/settings.dart';
import 'package:favorite_places/services/profile_photo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'me';
  @override
  String? get displayName => 'Khalid';
  @override
  String? get email => 'test@example.com';
  @override
  String? get photoURL => null;
  @override
  String? get phoneNumber => null;
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.users);
  final StreamController<User?> users;
  @override
  Future<void> signOut() async => users.add(null);
}

void main() {
  // The account's globe spins forever; with less motion it stays still, so
  // pumpAndSettle can settle.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  testWidgets('Sign out is in Settings and returns to the sign-in form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The test font is taller than Inter, so fixed-height rows overflow.
    final report = FlutterError.onError!;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('A RenderFlex overflowed')) {
        report(details);
      }
    };
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final users = StreamController<User?>()..add(_User());
    addTearDown(users.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseAuthProvider.overrideWithValue(_Auth(users)),
          authStateProvider.overrideWith((ref) => users.stream),
          myProfileProvider.overrideWithValue(
            const AsyncData(
              UserProfile(uid: 'me', username: 'khalid', displayName: 'Khalid'),
            ),
          ),
          userPlacesProvider.overrideWith((ref) => UserPlacesNofitier()),
          followCountsProvider.overrideWith((ref, uid) async => (0, 0)),
          profilePhotoProvider.overrideWith((ref, uid) async => null),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsNothing);

    await tester.tap(find.byIcon(Icons.menu_rounded));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    FlutterError.onError = report;

    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
