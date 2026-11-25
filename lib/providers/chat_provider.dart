import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_places/data/sample_posts.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firestore: `chats/{id}` with `members`, `lastText`, `lastAt` and, for
/// groups, `name`; its messages in `chats/{id}/messages/{id}` with `uid`,
/// `text` and `createdAt`. A chat between two people has the id
/// `uidA_uidB` (sorted); a group has a random id. Chats with one sample
/// person stay in memory instead.
class Chat {
  const Chat({
    required this.id,
    required this.members,
    this.name = '',
    this.photo,
  });

  factory Chat.fromDoc(String id, Map<String, dynamic> data) => Chat(
    id: id,
    members: [...(data['members'] as List? ?? const [])].cast<String>(),
    name: data['name'] as String? ?? '',
    photo: (data['photo'] as Blob?)?.bytes,
  );

  /// The two-person chat between [me] and [other].
  factory Chat.direct(String me, String other) =>
      Chat(id: chatIdFor(me, other), members: [me, other]..sort());

  final String id;
  final List<String> members;

  /// A group's name and photo, which any member can change; may be empty.
  final String name;
  final Uint8List? photo;

  bool get isGroup => !id.contains('_');

  /// Everyone in the chat except [me].
  List<String> others(String me) => [
    for (final uid in members)
      if (uid != me) uid,
  ];

  bool get _isSample => !isGroup && members.any(isSampleUid);

  // The same chat, wherever it is opened from: messagesProvider keys on it.
  @override
  bool operator ==(Object other) => other is Chat && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

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

/// One chat in the inbox, with its latest message.
class ChatSummary {
  const ChatSummary({
    required this.chat,
    required this.lastText,
    required this.lastAt,
  });

  final Chat chat;
  final String lastText;
  final DateTime lastAt;
}

/// Counted in visible characters; firestore.rules allows 15x as many UTF-16
/// units, as one emoji can take 15.
const maxMessageLength = 1000;
const maxGroupNameLength = 50;

/// Everyone in a group, its maker included.
const maxGroupMembers = 9;

String chatIdFor(String a, String b) => ([a, b]..sort()).join('_');

final _myUid = Provider<String?>(
  (ref) => ref.watch(authStateProvider.select((a) => a.value?.uid)),
);

/// Chats with sample people during this run, by chat id.
class _SampleChats extends Notifier<Map<String, (Chat, List<ChatMessage>)>> {
  @override
  Map<String, (Chat, List<ChatMessage>)> build() => const {};

  void add(Chat chat, ChatMessage message) => state = {
    ...state,
    chat.id: (chat, [...?state[chat.id]?.$2, message]),
  };
}

final _sampleChatsProvider =
    NotifierProvider<_SampleChats, Map<String, (Chat, List<ChatMessage>)>>(
      _SampleChats.new,
    );

DateTime _time(Object? value) =>
    // Null until the server confirms a message just written.
    (value as Timestamp?)?.toDate() ?? DateTime.now();

/// [chat] as it is now: a group's name and photo can change while it is open.
final chatProvider = StreamProvider.family<Chat, Chat>((ref, chat) {
  if (!chat.isGroup) {
    return Stream.value(chat);
  }
  return ref
      .watch(firestoreProvider)
      .doc('chats/${chat.id}')
      .snapshots()
      .map((doc) => doc.exists ? Chat.fromDoc(doc.id, doc.data()!) : chat);
});

/// Messages in [chat], oldest first.
final messagesProvider = StreamProvider.family<List<ChatMessage>, Chat>((
  ref,
  chat,
) {
  if (ref.watch(_myUid) == null) {
    return Stream.value(const []);
  }
  if (chat._isSample) {
    return Stream.value(
      ref.watch(_sampleChatsProvider)[chat.id]?.$2 ?? const [],
    );
  }
  // shortcut: newest 200 only, no paging; page once chats get that long.
  return ref
      .watch(firestoreProvider)
      .collection('chats/${chat.id}/messages')
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
    for (final (chat, messages) in ref.watch(_sampleChatsProvider).values)
      ChatSummary(
        chat: chat,
        lastText: messages.last.text,
        lastAt: messages.last.createdAt,
      ),
  ];
  int newestFirst(ChatSummary a, ChatSummary b) => b.lastAt.compareTo(a.lastAt);
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
              chat: Chat.fromDoc(doc.id, doc.data()),
              lastText: doc.data()['lastText'] as String? ?? '',
              lastAt: _time(doc.data()['lastAt']),
            ),
          ...samples,
        ]..sort(newestFirst),
      );
  // Sample chats right away, without waiting for the server.
  return () async* {
    yield [...samples]..sort(newestFirst);
    yield* saved;
  }();
});

Future<void> sendMessage(
  WidgetRef ref, {
  required String me,
  required Chat chat,
  required String text,
}) async {
  if (chat._isSample) {
    ref
        .read(_sampleChatsProvider.notifier)
        .add(chat, ChatMessage(uid: me, text: text, createdAt: DateTime.now()));
    return;
  }
  final db = ref.read(firestoreProvider);
  final doc = db.doc('chats/${chat.id}');
  final last = {'lastText': text, 'lastAt': FieldValue.serverTimestamp()};
  final batch = db.batch();
  if (chat.isGroup) {
    batch.update(doc, last);
  } else {
    // The first message creates the chat.
    batch.set(doc, {'members': chat.members, ...last});
  }
  batch.set(doc.collection('messages').doc(), {
    'uid': me,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  });
  await batch.commit();
}

/// A new group of [me] and [others], up to [maxGroupMembers] in all.
Future<Chat> createGroup(
  WidgetRef ref, {
  required String me,
  required List<String> others,
  required String name,
}) async {
  assert(others.length >= 2 && others.length < maxGroupMembers);
  final doc = ref.read(firestoreProvider).collection('chats').doc();
  final chat = Chat(id: doc.id, members: [me, ...others], name: name);
  await doc.set({
    'members': chat.members,
    'name': name,
    'lastText': '',
    'lastAt': FieldValue.serverTimestamp(),
  });
  return chat;
}

/// Renames [chat]; an empty [name] shows the members' names instead.
Future<void> renameGroup(WidgetRef ref, Chat chat, String name) =>
    ref.read(firestoreProvider).doc('chats/${chat.id}').update({'name': name});

/// A group photo is kept in the chat document, so it must stay small:
/// pick it at [groupPhotoSize] px.
const groupPhotoSize = 256.0;
const maxGroupPhotoBytes = 100 * 1024;

/// Sets [chat]'s photo to [bytes], or removes it when null.
Future<void> setGroupPhoto(WidgetRef ref, Chat chat, Uint8List? bytes) {
  if (bytes != null && bytes.length > maxGroupPhotoBytes) {
    throw ArgumentError('photo too big');
  }
  return ref.read(firestoreProvider).doc('chats/${chat.id}').update({
    'photo': bytes == null ? FieldValue.delete() : Blob(bytes),
  });
}
