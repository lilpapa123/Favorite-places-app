import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firestore layout:
/// - `users/{uid}`: username, name and photo of each person.
/// - `usernames/{lowercase}`: `{uid}`, so a username belongs to one person.
/// - `users/{uid}/following/{otherUid}` and `users/{uid}/followers/{otherUid}`.
/// - `places/{id}`: places with `ownerUid` (see user_palces.dart).
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl,
  });

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return UserProfile(
      uid: doc.id,
      username: data['username'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
    );
  }

  final String uid;
  final String username;
  final String displayName;
  final String? photoUrl;

  /// Display name, or the username when there is none.
  String get name => displayName.isNotEmpty ? displayName : username;
}

/// 3–20 letters, numbers, dots or underscores.
final usernamePattern = RegExp(r'^[a-zA-Z0-9._]{3,20}$');

final _myUid = Provider<String?>(
  (ref) => ref.watch(authStateProvider.select((a) => a.value?.uid)),
);

final profileProvider = StreamProvider.family<UserProfile?, String>((ref, uid) {
  return ref
      .watch(firestoreProvider)
      .doc('users/$uid')
      .snapshots()
      .map((doc) => doc.exists ? UserProfile.fromDoc(doc) : null);
});

/// The signed-in user's profile; null until they pick a username.
final myProfileProvider = Provider<AsyncValue<UserProfile?>>((ref) {
  final uid = ref.watch(_myUid);
  return uid == null ? const AsyncData(null) : ref.watch(profileProvider(uid));
});

/// Uids the signed-in user follows.
final followingIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(_myUid);
  if (uid == null) {
    return Stream.value(const {});
  }
  return ref
      .watch(firestoreProvider)
      .collection('users/$uid/following')
      .snapshots()
      .map((snap) => {for (final doc in snap.docs) doc.id});
});

/// (followers, following) for [uid], counted by the server.
final followCountsProvider = FutureProvider.autoDispose
    .family<(int, int), String>((ref, uid) async {
      final db = ref.watch(firestoreProvider);
      // Recount whenever the signed-in user follows or unfollows someone.
      ref.watch(followingIdsProvider);
      final results = await Future.wait([
        db.collection('users/$uid/followers').count().get(),
        db.collection('users/$uid/following').count().get(),
      ]);
      return (results[0].count ?? 0, results[1].count ?? 0);
    });

/// People in [uid]'s followers (or following) list.
final followListProvider = FutureProvider.autoDispose
    .family<List<UserProfile>, (String, bool)>((ref, args) async {
      final (uid, followers) = args;
      final db = ref.watch(firestoreProvider);
      final snap = await db
          .collection('users/$uid/${followers ? 'followers' : 'following'}')
          .get();
      final docs = await Future.wait([
        for (final doc in snap.docs) db.doc('users/${doc.id}').get(),
      ]);
      return [
        for (final doc in docs)
          if (doc.exists) UserProfile.fromDoc(doc),
      ];
    });

/// Places saved by any user, newest first.
final placesOfUserProvider = StreamProvider.family<List<Place>, String>(
  (ref, uid) => placesOf(ref.watch(firestoreProvider), uid),
);

/// Newest places from the people the signed-in user follows, with the owner.
final feedProvider = StreamProvider<List<(String, Place)>>((ref) {
  final ids = ref.watch(followingIdsProvider).value ?? const {};
  if (ids.isEmpty) {
    return Stream.value(const []);
  }
  // shortcut: Firestore's whereIn takes at most 30 values, so only the first
  // 30 people followed appear; split into several queries beyond that.
  return ref
      .watch(firestoreProvider)
      .collection('places')
      .where('ownerUid', whereIn: ids.take(30).toList())
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs)
            (
              doc.data()['ownerUid'] as String,
              Place.fromFirestore(doc.id, doc.data()),
            ),
        ],
      );
});

/// Follow, unfollow, usernames and search.
class Social {
  Social(this._db);

  final FirebaseFirestore _db;

  Future<void> follow(String me, String other) =>
      (_db.batch()
            ..set(_db.doc('users/$me/following/$other'), {
              'at': FieldValue.serverTimestamp(),
            })
            ..set(_db.doc('users/$other/followers/$me'), {
              'at': FieldValue.serverTimestamp(),
            }))
          .commit();

  Future<void> unfollow(String me, String other) =>
      (_db.batch()
            ..delete(_db.doc('users/$me/following/$other'))
            ..delete(_db.doc('users/$other/followers/$me')))
          .commit();

  /// Gives [uid] the username [username]; false when someone else has it.
  Future<bool> claimUsername({
    required String uid,
    required String username,
    required String displayName,
    String? photoUrl,
  }) {
    final key = username.toLowerCase();
    return _db.runTransaction((tx) async {
      final claimed = await tx.get(_db.doc('usernames/$key'));
      if (claimed.exists && claimed.data()?['uid'] != uid) {
        return false;
      }
      final user = await tx.get(_db.doc('users/$uid'));
      final old = user.data()?['usernameLower'] as String?;
      if (old != null && old != key) {
        tx.delete(_db.doc('usernames/$old'));
      }
      tx.set(_db.doc('usernames/$key'), {'uid': uid});
      tx.set(_db.doc('users/$uid'), {
        'username': username,
        'usernameLower': key,
        'displayName': displayName,
        'displayNameLower': displayName.toLowerCase(),
        'photoUrl': photoUrl,
      }, SetOptions(merge: true));
      return true;
    });
  }

  /// Keeps the searchable name in step with the account name.
  Future<void> updateDisplayName(String uid, String name) =>
      _db.doc('users/$uid').set({
        'displayName': name,
        'displayNameLower': name.toLowerCase(),
      }, SetOptions(merge: true));

  /// People whose username or name starts with [query].
  Future<List<UserProfile>> search(String query, {String? exclude}) async {
    final q = query.trim().toLowerCase().replaceFirst('@', '');
    if (q.isEmpty) {
      return const [];
    }
    Future<QuerySnapshot<Map<String, dynamic>>> prefix(String field) => _db
        .collection('users')
        .where(field, isGreaterThanOrEqualTo: q)
        .where(field, isLessThan: '$q')
        .limit(20)
        .get();
    final results = await Future.wait([
      prefix('usernameLower'),
      prefix('displayNameLower'),
    ]);
    final byUid = <String, UserProfile>{
      for (final snap in results)
        for (final doc in snap.docs)
          if (doc.id != exclude) doc.id: UserProfile.fromDoc(doc),
    };
    return byUid.values.where((p) => p.username.isNotEmpty).toList();
  }
}

final socialProvider = Provider<Social>(
  (ref) => Social(ref.watch(firestoreProvider)),
);
