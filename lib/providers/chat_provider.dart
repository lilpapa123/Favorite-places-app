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

  /// A group's maker, kept first in [members]: the only one who can rename
  /// it, change its photo and remove people.
  String? get admin => isGroup ? members.firstOrNull : null;

  /// Everyone in the chat except [me].
  List<String> others(String me) => [
    for (final uid in members)
      if (uid != me) uid,
  ];

  bool get _isSample =>
      id.startsWith(samplePrefix) || (!isGroup && members.any(isSampleUid));

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
  Map<String, (Chat, List<ChatMessage>)> build() {
    final me = ref.watch(_myUid);
    if (!showSamplePosts || me == null) {
      return const {};
    }
    final chat = _sampleGroup(me);
    return {chat.id: (chat, _sampleGroupMessages(me))};
  }

  void add(Chat chat, ChatMessage message) => state = {
    ...state,
    chat.id: (chat, [...?state[chat.id]?.$2, message]),
  };
}

/// A made-up group, so group chats can be tried while developing. Lina
/// made it, so you see it as a member, not its admin.
Chat _sampleGroup(String me) => Chat(
  id: '${samplePrefix}group-weekend',
  members: [
    '${samplePrefix}lina',
    me,
    '${samplePrefix}mert',
    '${samplePrefix}sofia',
    '${samplePrefix}omar',
  ],
  name: 'Weekend in Kapadokya',
);

List<ChatMessage> _sampleGroupMessages(String me) {
  final start = DateTime.now().subtract(const Duration(hours: 3));
  var minutes = 0;
  ChatMessage say(String who, String text, [int after = 4]) => ChatMessage(
    uid: who == 'me' ? me : '$samplePrefix$who',
    text: text,
    createdAt: start.add(Duration(minutes: minutes += after)),
  );
  return [
    say('lina', 'Made a group for the Kapadokya trip! 🎈'),
    say('mert', 'Finally. Are we still going Friday night?'),
    say('lina', 'Yes, bus leaves 22:30 from Esenler.', 2),
    say('sofia', 'I booked the cave hotel in Göreme, 2 rooms.'),
    say('sofia', 'Breakfast on the roof included ☕', 1),
    say('me', 'Amazing. Who wants the balloon ride at sunrise?'),
    say('omar', 'Me! I have been waiting years for this.'),
    say('mert', 'I will watch from the ground with a camera 😅', 3),
    say('lina', 'I can ask the hotel to book 3 spots.'),
    say('me', 'Do it, count me in.', 2),
    say('omar', 'Same. Should we hike Love Valley after?', 6),
    say('sofia', 'Yes! Bring good shoes, it gets dusty.'),
    say('lina', 'Sending the plan here tonight 📍', 10),
  ];
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
  if (!chat.isGroup || chat._isSample) {
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

/// A new group of [me] and [others], up to [maxGroupMembers] in all. [me]
/// goes first in members, which makes them its admin.
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

/// Takes [uid] out of [chat]; only its admin may.
Future<void> removeMember(WidgetRef ref, Chat chat, String uid) {
  assert(uid != chat.admin);
  return ref.read(firestoreProvider).doc('chats/${chat.id}').update({
    'members': FieldValue.arrayRemove([uid]),
  });
}
