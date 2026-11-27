// Firestore's classes are sealed; these small fakes stand in for them.
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/screens/account.dart';
import 'package:favorite_places/screens/edit_profile.dart';
import 'package:favorite_places/services/profile_photo.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _User extends Fake implements User {
  _User({this.name = 'Khalid'});
  String? name;
  String? savedName;
  bool nameWritten = false;
  @override
  String get uid => 'me';
  @override
  String? get displayName => name;
  @override
  String? get email => 'test@example.com';
  @override
  String? get photoURL => null;
  @override
  String? get phoneNumber => null;
  @override
  Future<void> updateDisplayName(String? displayName) async {
    nameWritten = true;
    // Like the iOS SDK: null is left out of the request and changes nothing.
    if (displayName != null) {
      name = savedName = displayName;
    }
  }

  @override
  Future<void> reload() async {}
}

class _Social extends Fake implements Social {
  Future<bool> Function() result = () async => true;
  void Function()? onSave;
  ({String name, String? username, String? bio})? call;

  @override
  Future<bool> saveProfile({
    required String uid,
    required String displayName,
    String? username,
    String? bio,
  }) {
    call = (name: displayName, username: username, bio: bio);
    onSave?.call();
    return result();
  }
}

class _Photos extends Fake implements ProfilePhotoStore {
  bool removed = false;
  @override
  Future<File?> load(String uid) async =>
      removed ? null : File('assets/does_not_exist.jpg');
  @override
  Future<void> remove(String uid) async => removed = true;
}

class _Db extends Fake implements FirebaseFirestore {
  _Db(this.docs, [this.live]);
  final Map<String, Map<String, dynamic>> docs;
  final Stream<DocumentSnapshot<Map<String, dynamic>>>? live;
  late final tx = _Tx(docs);

  @override
  DocumentReference<Map<String, dynamic>> doc(String documentPath) =>
      _Ref(documentPath, live);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) => transactionHandler(tx);
}

class _Ref extends Fake implements DocumentReference<Map<String, dynamic>> {
  _Ref(this.path, [this.live]);
  @override
  final String path;
  final Stream<DocumentSnapshot<Map<String, dynamic>>>? live;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    expect(includeMetadataChanges, isTrue);
    return live!;
  }
}

class _Meta extends Fake implements SnapshotMetadata {
  _Meta(this.isFromCache);
  @override
  final bool isFromCache;
}

class _Snap extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snap(this._data, {this.fromCache = false});
  final Map<String, dynamic>? _data;
  final bool fromCache;
  @override
  String get id => 'me';
  @override
  SnapshotMetadata get metadata => _Meta(fromCache);
  @override
  bool get exists => _data != null;
  @override
  Map<String, dynamic>? data() => _data;
}

class _Tx extends Fake implements Transaction {
  _Tx(this.docs);
  final Map<String, Map<String, dynamic>> docs;
  final writes = <String, Map<String, dynamic>>{};
  final deletes = <String>[];

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async => _Snap(docs[documentReference.path]) as DocumentSnapshot<T>;

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    writes[documentReference.path] = data as Map<String, dynamic>;
    return this;
  }

  @override
  Transaction delete(DocumentReference documentReference) {
    deletes.add(documentReference.path);
    return this;
  }
}

const _profile = UserProfile(
  uid: 'me',
  username: 'khalid',
  displayName: 'Khalid',
  bio: 'I like maps',
);

void main() {
  group('Social.saveProfile', () {
    Future<(bool, _Tx)> save(
      Map<String, Map<String, dynamic>> docs, {
      String? username,
      String? bio,
    }) async {
      final db = _Db(docs);
      final saved = await Social(db).saveProfile(
        uid: 'me',
        displayName: 'Khalid',
        username: username,
        bio: bio,
      );
      return (saved, db.tx);
    }

    test('a taken username writes nothing', () async {
      final (saved, tx) = await save(
        {
          'usernames/sara': {'uid': 'other'},
        },
        username: 'Sara',
        bio: 'hi',
      );
      expect(saved, isFalse);
      expect(tx.writes, isEmpty);
    });

    test('a new username replaces the old claim', () async {
      final (saved, tx) = await save({
        'users/me': {'usernameLower': 'old'},
        'usernames/old': {'uid': 'me'},
      }, username: 'New');
      expect(saved, isTrue);
      expect(tx.writes['usernames/new'], {'uid': 'me'});
      expect(tx.deletes, ['usernames/old']);
    });

    test('changing only capitals never rewrites the claim', () async {
      final (_, tx) = await save({
        'users/me': {'usernameLower': 'khalid'},
        'usernames/khalid': {'uid': 'me'},
      }, username: 'Khalid');
      expect(tx.writes.keys, ['users/me']);
      expect(tx.deletes, isEmpty);
    });

    test('a claim already mine is not updated', () async {
      final (saved, tx) = await save({
        'usernames/khalid': {'uid': 'me'},
      }, username: 'khalid');
      expect(saved, isTrue);
      expect(tx.writes.keys, ['users/me']);
    });

    test('fields that were not edited are not written', () async {
      final (_, tx) = await save({});
      expect(tx.writes['users/me']!.keys, ['displayName', 'displayNameLower']);
    });

    test('an empty bio clears it', () async {
      final (_, tx) = await save({}, bio: '');
      expect(tx.writes['users/me']!['bio'], '');
    });
  });

  test('usernames Firestore reserves as IDs are refused', () {
    expect(usernamePattern.hasMatch('__init__'), isFalse);
    expect(usernamePattern.hasMatch('_khalid_'), isTrue);
    expect(usernamePattern.hasMatch('__khalid'), isTrue);
  });

  test('the username is not repeated under itself', () {
    const unnamed = UserProfile(uid: 'a', username: 'sara', displayName: '');
    expect(unnamed.name, 'sara');
    expect(unnamed.handle, isNull);
    expect(_profile.handle, '@khalid');
  });

  group('profileProvider', () {
    Future<List<UserProfile?>> emitted(List<_Snap> snaps) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => const Stream.empty()),
          firestoreProvider.overrideWithValue(
            _Db({}, Stream.fromIterable(snaps)),
          ),
        ],
      );
      addTearDown(container.dispose);
      final values = <UserProfile?>[];
      container.listen(profileProvider('me'), (_, next) {
        if (next.hasValue) values.add(next.value);
      });
      await pumpEventQueue();
      return values;
    }

    test('an empty cache is not "no username"', () async {
      expect(await emitted([_Snap(null, fromCache: true)]), isEmpty);
    });

    test('the server saying so is', () async {
      final values = await emitted([_Snap(null, fromCache: true), _Snap(null)]);
      expect(values, [null]);
    });

    test('a cached profile works offline', () async {
      final values = await emitted([
        _Snap({'username': 'khalid'}, fromCache: true),
      ]);
      expect(values.single?.username, 'khalid');
    });
  });

  group('EditProfileScreen', () {
    late _User user;
    late _Social social;

    setUp(() {
      user = _User();
      social = _Social();
    });

    Future<void> open(
      WidgetTester tester, {
      Stream<UserProfile?>? profile,
    }) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream<User?>.value(user)),
            socialProvider.overrideWithValue(social),
            profileProvider.overrideWith(
              (ref, uid) => profile ?? Stream.value(_profile),
            ),
            profilePhotoProvider.overrideWith((ref, uid) async => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          EditProfileScreen(user: user, shownName: 'Khalid'),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<void> type(WidgetTester tester, int field, String text) =>
        tester.enterText(find.byType(TextField).at(field), text);

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows and saves name, username and bio', (tester) async {
      await open(tester);
      expect(find.text('khalid'), findsOneWidget);
      expect(find.text('I like maps'), findsOneWidget);
      await type(tester, 0, 'Khalid W');
      await type(tester, 1, '@khalid.w');
      await type(tester, 2, 'Coffee and hikes');
      await save(tester);
      expect(user.savedName, 'Khalid W');
      expect(social.call, (
        name: 'Khalid W',
        username: 'khalid.w',
        bio: 'Coffee and hikes',
      ));
      expect(find.text('Profile saved'), findsOneWidget);
      expect(find.byType(EditProfileScreen), findsNothing);
    });

    testWidgets('sends only what changed, including a cleared bio', (
      tester,
    ) async {
      await open(tester);
      await type(tester, 2, '');
      await save(tester);
      expect(user.savedName, isNull);
      expect(social.call, (name: 'Khalid', username: null, bio: ''));
    });

    testWidgets('a taken username keeps the screen open', (tester) async {
      social.result = () async => false;
      await open(tester);
      await type(tester, 1, 'sara');
      await save(tester);
      expect(find.text('That username is taken.'), findsOneWidget);
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('an invalid username saves nothing', (tester) async {
      await open(tester);
      await type(tester, 0, 'New name');
      await type(tester, 1, 'a b');
      await save(tester);
      expect(user.savedName, isNull);
      expect(social.call, isNull);
    });

    testWidgets('a name alone is not enough: username is required', (
      tester,
    ) async {
      await open(tester, profile: Stream.value(null));
      await type(tester, 0, 'A new name');
      await save(tester);
      expect(find.text('Enter a username.'), findsOneWidget);
      expect(user.nameWritten, isFalse);
      expect(social.call, isNull);
    });

    testWidgets('a saved username cannot be blanked', (tester) async {
      await open(tester);
      await type(tester, 1, '');
      await save(tester);
      expect(find.text('Enter a username.'), findsOneWidget);
      expect(social.call, isNull);
    });

    testWidgets('name and bio are marked optional', (tester) async {
      await open(tester);
      expect(find.text('Optional'), findsNWidgets(2));
    });

    testWidgets('without a name, the fallback is never saved as one', (
      tester,
    ) async {
      user = _User(name: null);
      await open(tester, profile: Stream.value(null));
      expect(find.widgetWithText(TextField, 'Khalid'), findsNothing);
      await type(tester, 1, 'khalid.w');
      await save(tester);
      expect(user.nameWritten, isFalse);
      expect(social.call, (name: '', username: 'khalid.w', bio: null));
    });

    testWidgets('clearing the name leaves the username', (tester) async {
      await open(tester);
      await type(tester, 0, '');
      await save(tester);
      expect(user.nameWritten, isTrue);
      expect(user.name, isEmpty);
      expect(social.call?.name, '');
    });

    testWidgets('a name is kept when its replacement fails to save', (
      tester,
    ) async {
      social.result = () async => throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      await open(tester);
      await type(tester, 0, '');
      await save(tester);
      expect(user.nameWritten, isFalse);
      expect(find.textContaining("Couldn't save your profile"), findsOneWidget);
    });

    testWidgets('a name is kept when the new username is taken', (
      tester,
    ) async {
      social.result = () async => false;
      await open(tester);
      await type(tester, 0, '');
      await type(tester, 1, 'sara');
      await save(tester);
      expect(user.nameWritten, isFalse);
    });

    testWidgets('rejected by Firestore: nothing changes, and it says so', (
      tester,
    ) async {
      social.result = () async => throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      await open(tester);
      await type(tester, 0, 'New name');
      await save(tester);
      expect(user.nameWritten, isFalse);
      expect(find.textContaining("Couldn't save your profile"), findsOneWidget);
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('a late profile does not replace typed text', (tester) async {
      final stream = StreamController<UserProfile?>();
      addTearDown(stream.close);
      await open(tester, profile: stream.stream);
      await type(tester, 2, 'Typed first');
      stream.add(_profile);
      await tester.pumpAndSettle();
      expect(find.text('Typed first'), findsOneWidget);
      expect(find.text('khalid'), findsOneWidget);
    });

    testWidgets('closing during a save is safe', (tester) async {
      final done = Completer<bool>();
      social.result = () => done.future;
      await open(tester);
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      Navigator.of(tester.element(find.byType(EditProfileScreen))).pop();
      await tester.pumpAndSettle();
      done.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AccountScreen', () {
    Future<_Photos> show(
      WidgetTester tester, {
      String? name = 'Khalid',
      UserProfile? profile = _profile,
      Stream<UserProfile?>? profiles,
      Stream<User?>? users,
      _Social? social,
      Locale? locale,
    }) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // The test font is taller than Inter, so fixed-height rows overflow.
      final report = FlutterError.onError!;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (!text.contains('A RenderFlex overflowed') &&
            !text.contains('does_not_exist.jpg')) {
          report(details);
        }
      };
      final photos = _Photos();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => users ?? Stream<User?>.value(_User(name: name)),
            ),
            socialProvider.overrideWithValue(social ?? _Social()),
            profileProvider.overrideWith(
              (ref, uid) => profiles ?? Stream.value(profile),
            ),
            userPlacesProvider.overrideWith((ref) => UserPlacesNofitier()),
            followCountsProvider.overrideWith((ref, uid) async => (0, 0)),
            profilePhotoStoreProvider.overrideWithValue(photos),
          ],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AccountScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(() => FlutterError.onError = report);
      return photos;
    }

    const withUsername = UserProfile(
      uid: 'me',
      username: 'khalid.w',
      displayName: '',
    );
    testWidgets('a name shows under the photo', (tester) async {
      final report = FlutterError.onError!;
      await show(tester);
      FlutterError.onError = report;
      expect(find.text('Khalid'), findsOneWidget);
    });

    testWidgets('a removed name stays gone if the account still has it', (
      tester,
    ) async {
      final report = FlutterError.onError!;
      await show(tester, name: 'Khalid', profile: withUsername);
      expect(find.text('Khalid'), findsNothing);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile & preferences'));
      await tester.pumpAndSettle();
      FlutterError.onError = report;
      // Not back in the field either, where Save would store it again.
      expect(find.widgetWithText(TextField, 'Khalid'), findsNothing);
    });

    for (final name in [null, '  ']) {
      testWidgets('name "$name": no name line', (tester) async {
        final report = FlutterError.onError!;
        await show(tester, name: name, profile: withUsername);
        FlutterError.onError = report;
        // The title only: not repeated as a name, and no email stand-in.
        expect(find.text('khalid.w'), findsOneWidget);
        expect(find.text('Test'), findsNothing);
      });
    }

    testWidgets('no name line while the profile loads', (tester) async {
      final report = FlutterError.onError!;
      await show(
        tester,
        name: null,
        profiles: const Stream.empty(broadcast: true),
      );
      FlutterError.onError = report;
      expect(find.text('Test'), findsNothing);
    });

    testWidgets('the username replaces the "Account" title', (tester) async {
      final report = FlutterError.onError!;
      await show(tester);
      FlutterError.onError = report;
      expect(find.text('Account'), findsNothing);
      final title = tester.widget<PageHeader>(find.byType(PageHeader));
      expect(title.title, 'khalid');
    });

    testWidgets('a long username fits on one line, left to right in Arabic', (
      tester,
    ) async {
      final report = FlutterError.onError!;
      const long = 'WWWWWWWWWWWWWWWWWWW.';
      await show(
        tester,
        locale: const Locale('ar'),
        profile: const UserProfile(
          uid: 'me',
          username: long,
          displayName: 'Khalid',
        ),
      );
      tester.view.physicalSize = const Size(375, 2000);
      await tester.pumpAndSettle();
      FlutterError.onError = report;
      final title = find.text(long);
      expect(tester.widget<Text>(title).textDirection, TextDirection.ltr);
      expect(tester.getRect(title).left, greaterThanOrEqualTo(0));
      expect(tester.getRect(title).right, lessThanOrEqualTo(375));
    });

    testWidgets('no username: setup replaces Account', (tester) async {
      final report = FlutterError.onError!;
      await show(tester, profile: null);
      FlutterError.onError = report;
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('Choose a username'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('a profile with only a name still needs a username', (
      tester,
    ) async {
      final report = FlutterError.onError!;
      await show(
        tester,
        profile: const UserProfile(uid: 'me', username: '', displayName: 'K'),
      );
      FlutterError.onError = report;
      expect(find.text('Choose a username'), findsOneWidget);
    });

    testWidgets('loading never asks for a username', (tester) async {
      final report = FlutterError.onError!;
      await show(tester, profiles: const Stream.empty(broadcast: true));
      FlutterError.onError = report;
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('setup ends when the username is saved', (tester) async {
      final report = FlutterError.onError!;
      final profiles = StreamController<UserProfile?>()..add(null);
      addTearDown(profiles.close);
      final social = _Social()..onSave = () => profiles.add(withUsername);
      await show(tester, name: null, profiles: profiles.stream, social: social);
      await tester.enterText(find.byType(TextField).at(1), 'khalid.w');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      FlutterError.onError = report;
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.text('khalid.w'), findsOneWidget);
    });

    testWidgets('an account refresh keeps what is typed in setup', (
      tester,
    ) async {
      final report = FlutterError.onError!;
      final users = StreamController<User?>()..add(_User());
      addTearDown(users.close);
      await show(tester, profile: null, users: users.stream);
      await tester.enterText(find.byType(TextField).at(1), 'half.typed');
      users.add(_User(name: 'Renamed'));
      await tester.pumpAndSettle();
      FlutterError.onError = report;
      expect(find.text('half.typed'), findsOneWidget);
    });

    testWidgets('"Profile & preferences" opens the editor', (tester) async {
      final report = FlutterError.onError!;
      await show(tester);
      expect(find.text('I like maps'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile & preferences'));
      await tester.pumpAndSettle();
      FlutterError.onError = report;
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('the photo can be removed from the editor', (tester) async {
      final report = FlutterError.onError!;
      final photos = await show(tester);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile & preferences'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();
      FlutterError.onError = report;
      expect(photos.removed, isTrue);
    });
  });
}
