import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/chat_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/data/sample_posts.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/screens/chat.dart';
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

  testWidgets('New message: people you follow, and groups up to 9', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(_User())),
          firestoreProvider.overrideWithValue(_Db()),
          followListProvider(('me', false))
              .overrideWith((ref) async => sampleProfiles),
        ],
        child: MaterialApp(
          theme: AppTheme.data(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NewMessageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('PEOPLE YOU FOLLOW'), findsOneWidget);

    await tester.tap(find.text('New group'));
    await tester.pumpAndSettle();
    final create = find.textContaining('Create group');
    expect(create, findsOneWidget);
    expect(find.text('Create group · 1/9'), findsOneWidget);

    // You and 8 more fill the group; the 9th pick is refused.
    for (final p in sampleProfiles.take(9)) {
      await tester.tap(find.text(p.name).last);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Create group · 9/9'), findsOneWidget);
    expect(find.text('Up to 9 people, you included.'), findsWidgets);
  });

  testWidgets('Group details: photo, name, members, rename', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const chat = Chat(
      id: 'group1',
      members: ['me', 'sample-lina', 'sample-mert'],
      name: 'Weekend trip',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(_User())),
          chatProvider(chat).overrideWith((ref) => Stream.value(chat)),
          profileProvider('me').overrideWith(
            (ref) => Stream.value(
              const UserProfile(uid: 'me', username: 'me', displayName: 'Me'),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.data(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GroupDetailsScreen(chat: chat),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Weekend trip'), findsOneWidget);
    expect(find.text('3 MEMBERS'), findsOneWidget);
    expect(find.text('Lina Haddad'), findsOneWidget);
    expect(find.text('Mert Yılmaz'), findsOneWidget);
    expect(find.bySemanticsLabel('Group photo'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit group name'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Weekend trip'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    // The maker is admin: they can remove the others, asked first.
    expect(find.text('Admin'), findsOneWidget);
    expect(find.byTooltip('Remove'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Remove').first);
    await tester.pumpAndSettle();
    expect(find.text('Remove Lina Haddad from the group?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('Group details: others cannot edit or remove', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const chat = Chat(
      id: 'group2',
      members: ['sample-lina', 'me', 'sample-mert'],
      name: 'Lina’s trip',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(_User())),
          chatProvider(chat).overrideWith((ref) => Stream.value(chat)),
          profileProvider('me').overrideWith(
            (ref) => Stream.value(
              const UserProfile(uid: 'me', username: 'me', displayName: 'Me'),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.data(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GroupDetailsScreen(chat: chat),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Admin'), findsOneWidget);
    expect(find.byTooltip('Edit group name'), findsNothing);
    expect(find.byTooltip('Remove'), findsNothing);
    expect(find.byIcon(Icons.photo_camera_rounded), findsNothing);
  });
}
