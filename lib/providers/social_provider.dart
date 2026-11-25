import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_places/data/sample_posts.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firestore layout:
/// - `users/{uid}`: username, name, bio and photo of each person.
/// - `usernames/{lowercase}`: `{uid}`, so a username belongs to one person.
/// - `users/{uid}/following/{otherUid}` and `users/{uid}/followers/{otherUid}`.
/// - `places/{id}`: places with `ownerUid` (see user_palces.dart).
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.username,
    required this.displayName,
    this.bio = '',
    this.photoUrl,
  });

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return UserProfile(
      uid: doc.id,
      username: data['username'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
    );
  }

  final String uid;
  final String username;
  final String displayName;
  final String bio;
  final String? photoUrl;

  /// Display name, or the username when there is none.
  String get name => displayName.isNotEmpty ? displayName : username;

  /// "@username" for under the name; null when the name already is the
  /// username, or there is no username.
  String? get handle =>
      displayName.isEmpty || username.isEmpty ? null : '@$username';
}

/// Counted in visible characters. firestore.rules allows 15x as much, because
/// it counts UTF-16 units and one emoji can take 15.
const maxBioLength = 150;

/// 3–20 letters, numbers, dots or underscores. Not `__like_this__`: Firestore
/// reserves those document IDs.
final usernamePattern = RegExp(r'^(?!__.*__$)[a-zA-Z0-9._]{3,20}$');

final _myUid = Provider<String?>(
  (ref) => ref.watch(authStateProvider.select((a) => a.value?.uid)),
);

/// Null only when the server says there is no profile. Offline with an empty
/// cache it keeps loading, so nobody is asked for a username they already have.
final profileProvider = StreamProvider.family<UserProfile?, String>((ref, uid) {
  // Listens again after signing in: signing out ends the stream with an error.
  if (isSampleUid(uid)) {
    return Stream.value(sampleProfile(uid));
  }
  ref.watch(_myUid);
  return ref
      .watch(firestoreProvider)
      .doc('users/$uid')
      // Metadata changes, to hear the server confirm what the cache said.
      .snapshots(includeMetadataChanges: true)
      .where((doc) => doc.exists || !doc.metadata.isFromCache)
      .map((doc) => doc.exists ? UserProfile.fromDoc(doc) : null);
});

/// The signed-in user's profile; null until they pick a username.
final myProfileProvider = Provider<AsyncValue<UserProfile?>>((ref) {
  final uid = ref.watch(_myUid);
  return uid == null ? const AsyncData(null) : ref.watch(profileProvider(uid));
});

/// Sample people followed during this run; they exist only on this phone.
class _SampleFollows extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String uid) =>
      state = state.contains(uid) ? ({...state}..remove(uid)) : {...state, uid};
}

final _sampleFollowsProvider = NotifierProvider<_SampleFollows, Set<String>>(
  _SampleFollows.new,
);

/// Uids the signed-in user follows.
final followingIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(_myUid);
  if (uid == null) {
    return Stream.value(const {});
  }
  final samples = ref.watch(_sampleFollowsProvider);
  return ref
      .watch(firestoreProvider)
      .collection('users/$uid/following')
      .snapshots()
      .map((snap) => {for (final doc in snap.docs) doc.id, ...samples});
});

/// Follows [other], or unfollows when [following].
Future<void> toggleFollow(
  WidgetRef ref, {
  required String me,
  required String other,
  required bool following,
}) async {
  if (isSampleUid(other)) {
    ref.read(_sampleFollowsProvider.notifier).toggle(other);
    return;
  }
  final social = ref.read(socialProvider);
  await (following ? social.unfollow(me, other) : social.follow(me, other));
}

/// (followers, following) for [uid], counted by the server.
final followCountsProvider = FutureProvider.autoDispose
    .family<(int, int), String>((ref, uid) async {
      if (isSampleUid(uid)) {
        final (followers, following) = sampleFollowCounts(uid);
        final followedByMe = ref.watch(_sampleFollowsProvider).contains(uid);
        return (followers + (followedByMe ? 1 : 0), following);
      }
      final db = ref.watch(firestoreProvider);
      // Recount whenever the signed-in user follows or unfollows someone.
      ref.watch(followingIdsProvider);
      // Sample people I follow live on this phone, not in Firestore.
      final samples = uid == ref.watch(_myUid)
          ? ref.watch(_sampleFollowsProvider).length
          : 0;
      final results = await Future.wait([
        db.collection('users/$uid/followers').count().get(),
        db.collection('users/$uid/following').count().get(),
      ]);
      return (results[0].count ?? 0, (results[1].count ?? 0) + samples);
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
      final samples = !followers && uid == ref.watch(_myUid)
          ? ref.watch(_sampleFollowsProvider)
          : const <String>{};
      return [
        for (final id in samples) ?sampleProfile(id),
        for (final doc in docs)
          if (doc.exists) UserProfile.fromDoc(doc),
      ];
    });

/// Places saved by any user, newest first.
final placesOfUserProvider = StreamProvider.family<List<Place>, String>(
  (ref, uid) => isSampleUid(uid)
      ? Stream.value([
          for (final (owner, place) in samplePosts())
            if (owner == uid) place,
        ])
      : placesOf(ref.watch(firestoreProvider), uid),
);

/// Newest places shared by everyone except the signed-in user, with the
/// owner. Signed out it has only the sample posts (the rules only let
/// signed-in users read), which debug and profile builds add at the end.
final discoverProvider = StreamProvider<List<(String, Place)>>((ref) {
  final me = ref.watch(_myUid);
  final samples = showSamplePosts ? samplePosts() : const <(String, Place)>[];
  if (me == null) {
    return Stream.value(samples);
  }
  // shortcut: newest 100 only, no ranking or paging; add a score field and
  // paging once there are many places.
  return ref
      .watch(firestoreProvider)
      .collection('places')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs)
            if (doc.data()['ownerUid'] case final String owner when owner != me)
              (owner, Place.fromFirestore(doc.id, doc.data())),
          ...samples,
        ]..sort((a, b) => b.$2.createdAt.compareTo(a.$2.createdAt)),
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

  /// Saves the public profile all at once. A null [username] or [bio] is
  /// left as it is. False, with nothing written, when the username is taken.
  Future<bool> saveProfile({
    required String uid,
    required String displayName,
    String? username,
    String? bio,
    String? photoUrl,
  }) {
    // A transaction, so that it fails when offline instead of waiting forever.
    return _db.runTransaction((tx) async {
      final userRef = _db.doc('users/$uid');
      final old = (await tx.get(userRef)).data()?['usernameLower'] as String?;
      final key = username?.toLowerCase();
      if (key != null && key != old) {
        final claimRef = _db.doc('usernames/$key');
        final claim = await tx.get(claimRef);
        if (claim.exists && claim.data()?['uid'] != uid) {
          return false;
        }
        // The rules forbid updating a claim, so only create missing ones.
        if (!claim.exists) {
          tx.set(claimRef, {'uid': uid});
        }
        if (old != null) {
          tx.delete(_db.doc('usernames/$old'));
        }
      }
      tx.set(userRef, {
        'displayName': displayName,
        'displayNameLower': displayName.toLowerCase(),
        if (username != null) ...{
          'username': username,
          'usernameLower': key,
          'photoUrl': photoUrl,
        },
        'bio': ?bio,
      }, SetOptions(merge: true));
      return true;
    }, timeout: const Duration(seconds: 15));
  }

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
