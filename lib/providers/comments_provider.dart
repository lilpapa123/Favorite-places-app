import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_places/data/sample_posts.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firestore: `places/{placeId}/comments/{id}` with `uid`, `text` and
/// `createdAt`. Sample posts keep theirs in memory instead.
class PostComment {
  const PostComment({
    required this.uid,
    required this.text,
    required this.createdAt,
  });

  final String uid;
  final String text;
  final DateTime createdAt;
}

/// Counted in visible characters; firestore.rules allows 15x as many UTF-16
/// units, as one emoji can take 15.
const maxCommentLength = 500;

bool _isSamplePlace(String placeId) => placeId.startsWith(samplePrefix);

/// A few made-up comments on each sample post, by other sample people.
List<PostComment> sampleComments(String placeId) {
  final seed = placeId.hashCode.abs();
  const texts = [
    'Adding this to my list!',
    'Went there last year, still dreaming about it.',
    'Wow, the light in this one.',
    'Is it busy on weekends?',
  ];
  final count = seed % 4;
  return [
    for (var i = 0; i < count; i++)
      PostComment(
        uid: sampleProfiles[(seed + i * 3) % sampleProfiles.length].uid,
        text: texts[(seed + i) % texts.length],
        createdAt: DateTime.now().subtract(Duration(hours: (count - i) * 5)),
      ),
  ];
}

/// Comments written on sample posts during this run.
class _SampleComments extends Notifier<Map<String, List<PostComment>>> {
  @override
  Map<String, List<PostComment>> build() => const {};

  void add(String placeId, PostComment comment) => state = {
    ...state,
    placeId: [...(state[placeId] ?? sampleComments(placeId)), comment],
  };
}

final _sampleCommentsProvider =
    NotifierProvider<_SampleComments, Map<String, List<PostComment>>>(
      _SampleComments.new,
    );

/// Comments on a place, oldest first.
final commentsProvider = StreamProvider.family<List<PostComment>, String>((
  ref,
  placeId,
) {
  if (_isSamplePlace(placeId)) {
    return Stream.value(
      ref.watch(_sampleCommentsProvider)[placeId] ?? sampleComments(placeId),
    );
  }
  // Listens again after signing in: the rules only let signed-in users read.
  ref.watch(authStateProvider.select((a) => a.value?.uid));
  // shortcut: first 200 only, no paging; page once posts get that many.
  return ref
      .watch(firestoreProvider)
      .collection('places/$placeId/comments')
      .orderBy('createdAt')
      .limit(200)
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs)
            PostComment(
              uid: doc.data()['uid'] as String? ?? '',
              text: doc.data()['text'] as String? ?? '',
              // Null until the server confirms a comment just written.
              createdAt:
                  (doc.data()['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            ),
        ],
      );
});

Future<void> postComment(
  WidgetRef ref, {
  required String placeId,
  required String uid,
  required String text,
}) async {
  if (_isSamplePlace(placeId)) {
    ref
        .read(_sampleCommentsProvider.notifier)
        .add(
          placeId,
          PostComment(uid: uid, text: text, createdAt: DateTime.now()),
        );
    return;
  }
  await ref.read(firestoreProvider).collection('places/$placeId/comments').add({
    'uid': uid,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
