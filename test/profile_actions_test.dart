import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/screens/profile.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'me';
}

/// Nobody followed in Firestore.
class _Db extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => _Col();
}

// ignore: subtype_of_sealed_class
class _Col extends Fake implements CollectionReference<Map<String, dynamic>> {
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.value(_Empty());
}

class _Empty extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => const [];
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Follow adds a follower and Message opens a chat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(_User())),
          firestoreProvider.overrideWithValue(_Db()),
        ],
        child: MaterialApp(
          theme: AppTheme.data(Brightness.light),
          // The test font is taller than the app's; at full size the
          // fixed-height counters overflow by 3 px.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(0.9)),
            child: child!,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfileScreen(uid: 'sample-maya'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('945'), findsOneWidget);
    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();
    expect(find.text('Following'), findsWidgets);
    expect(find.text('946'), findsOneWidget);

    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(find.text('No messages yet'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Hi Maya!');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Hi Maya!'), findsOneWidget);
    expect(find.text('No messages yet'), findsNothing);

    // Back on the profile, still followed.
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('946'), findsOneWidget);
  });
}
