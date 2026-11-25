import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_places/data/sample_posts.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firestore: `chats/{uidA_uidB}` (the two uids sorted) with `members`,
/// `lastText` and `lastAt`, and its messages in `chats/{id}/messages/{id}`
/// with `uid`, `text` and `createdAt`. Chats with sample people stay in
/// memory instead.
class ChatMessage {
  const ChatMessage({
    required this.uid,
    required this.text,
    required this.createdAt,
  });

  final String uid;
  final String text;
  final DateTime createdAt;
}

/// One chat in the inbox: who with, and the latest message.
class ChatSummary {
  const ChatSummary({
    required this.other,
    required this.lastText,
    required this.lastAt,
  });

  final String other;
  final String lastText;
  final DateTime lastAt;
}

/// Counted in visible characters; firestore.rules allows 15x as many UTF-16
/// units, as one emoji can take 15.
const maxMessageLength = 1000;

String chatIdFor(String a, String b) => ([a, b]..sort()).join('_');

final _myUid = Provider<String?>(
  (ref) => ref.watch(authStateProvider.select((a) => a.value?.uid)),
);

/// Messages with sample people during this run, by their uid.
class _SampleChats extends Notifier<Map<String, List<ChatMessage>>> {
  @override
  Map<String, List<ChatMessage>> build() => const {};

  void add(String other, ChatMessage message) => state = {
    ...state,
    other: [...?state[other], message],
  };
}

final _sampleChatsProvider =
    NotifierProvider<_SampleChats, Map<String, List<ChatMessage>>>(
      _SampleChats.new,
    );

DateTime _time(Object? value) =>
    // Null until the server confirms a message just written.
    (value as Timestamp?)?.toDate() ?? DateTime.now();

/// Messages between the signed-in user and [other], oldest first.
final messagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  other,
) {
  final me = ref.watch(_myUid);
  if (me == null) {
    return Stream.value(const []);
  }
  if (isSampleUid(other)) {
    return Stream.value(ref.watch(_sampleChatsProvider)[other] ?? const []);
  }
  // shortcut: newest 200 only, no paging; page once chats get that long.
  return ref
      .watch(firestoreProvider)
      .collection('chats/${chatIdFor(me, other)}/messages')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs.reversed)
            ChatMessage(
              uid: doc.data()['uid'] as String? ?? '',
              text: doc.data()['text'] as String? ?? '',
              createdAt: _time(doc.data()['createdAt']),
            ),
        ],
      );
});

/// The signed-in user's chats, newest first.
final chatsProvider = StreamProvider<List<ChatSummary>>((ref) {
  final me = ref.watch(_myUid);
  if (me == null) {
    return Stream.value(const []);
  }
  final samples = [
    for (final MapEntry(key: other, value: messages)
        in ref.watch(_sampleChatsProvider).entries)
      ChatSummary(
        other: other,
        lastText: messages.last.text,
        lastAt: messages.last.createdAt,
      ),
  ];
  // shortcut: newest 50 chats only; page once people have more.
  final saved = ref
      .watch(firestoreProvider)
      .collection('chats')
      .where('members', arrayContains: me)
      .orderBy('lastAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs)
            ChatSummary(
              other: (doc.data()['members'] as List).firstWhere(
                (uid) => uid != me,
                orElse: () => me,
              ) as String,
              lastText: doc.data()['lastText'] as String? ?? '',
              lastAt: _time(doc.data()['lastAt']),
            ),
          ...samples,
        ]..sort((a, b) => b.lastAt.compareTo(a.lastAt)),
      );
  // Sample chats right away, without waiting for the server.
  return () async* {
    yield [...samples]..sort((a, b) => b.lastAt.compareTo(a.lastAt));
    yield* saved;
  }();
});

Future<void> sendMessage(
  WidgetRef ref, {
  required String me,
  required String other,
  required String text,
}) async {
  if (isSampleUid(other)) {
    ref
        .read(_sampleChatsProvider.notifier)
        .add(
          other,
          ChatMessage(uid: me, text: text, createdAt: DateTime.now()),
        );
    return;
  }
  final db = ref.read(firestoreProvider);
  final chat = db.doc('chats/${chatIdFor(me, other)}');
  await (db.batch()
        ..set(chat, {
          'members': [me, other]..sort(),
          'lastText': text,
          'lastAt': FieldValue.serverTimestamp(),
        })
        ..set(chat.collection('messages').doc(), {
          'uid': me,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        }))
      .commit();
}
