import 'dart:async';

import 'package:favorite_places/data/sample_posts.dart';
import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/chat_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/screens/profile.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/cover_post_card.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/profile_photo_picker.dart';
import 'package:favorite_places/widgets/search_field.dart';
import 'package:favorite_places/widgets/image_input.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Above the tab bar, so the message box at the bottom is not hidden.
void openChat(BuildContext context, Chat chat) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute<void>(builder: (ctx) => ChatScreen(chat: chat)));
}

/// "Lina, Mert, Sofia" when a group has no name; the person's name for a
/// two-person chat.
String _chatTitle(WidgetRef ref, Chat chat, String me) {
  if (chat.name.isNotEmpty) {
    return chat.name;
  }
  return [
    for (final uid in chat.others(me))
      ref.watch(profileProvider(uid)).value?.name ?? '',
  ].where((n) => n.isNotEmpty).join(', ');
}

/// The person's photo, or a group icon.
class _ChatAvatar extends ConsumerWidget {
  const _ChatAvatar({required this.chat, required this.me, this.size = 48});

  final Chat chat;
  final String me;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (chat.photo case final photo?) {
      return ClipOval(
        child: Image.memory(
          photo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    if (chat.isGroup) {
      return SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.group_rounded,
            size: size * 0.5,
            color: AppColors.accent,
          ),
        ),
      );
    }
    final other = chat.others(me).firstOrNull ?? me;
    final profile = ref.watch(profileProvider(other)).value;
    return Avatar(
      name: profile?.name ?? '',
      photoUrl: profile?.photoUrl,
      size: size,
    );
  }
}

/// The Messages tab: the signed-in user's chats, newest first, and + to
/// start a new one.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(authStateProvider).value?.uid;
    final chats = ref.watch(chatsProvider);
    Widget note(String text) => Padding(
      padding: const EdgeInsets.all(AppSpace.page),
      child: Center(
        child: Text(text, style: AppText.meta(), textAlign: TextAlign.center),
      ),
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
          children: [
            PageHeader(
              title: l10n.messagesTitle,
              trailing: me == null
                  ? null
                  : CircleIconButton(
                      icon: Icon(Icons.add_rounded, color: AppColors.ink),
                      semanticLabel: l10n.newMessage,
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute<void>(
                              builder: (ctx) => const NewMessageScreen(),
                            ),
                          ),
                    ),
            ),
            if (me == null)
              note(l10n.signInToMessage)
            else
              ...chats.when(
                loading: () => [
                  Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ],
                error: (_, _) => [note(l10n.somethingWentWrong)],
                data: (list) => list.isEmpty
                    ? [note(l10n.noMessagesYet)]
                    : [
                        for (final summary in list)
                          _ChatTile(summary: summary, me: me),
                      ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.summary, required this.me});

  final ChatSummary summary;
  final String me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = summary.chat;
    return InkWell(
      onTap: () => openChat(context, chat),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.page,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            _ChatAvatar(chat: chat, me: me),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chatTitle(ref, chat, me),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong(),
                  ),
                  Text(
                    summary.lastText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              timeAgo(context.l10n, summary.lastAt),
              style: AppText.meta().copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search people, or pick from those you follow, to message them or to make
/// a group of up to [maxGroupMembers].
class NewMessageScreen extends ConsumerStatefulWidget {
  const NewMessageScreen({super.key});

  @override
  ConsumerState<NewMessageScreen> createState() => _NewMessageState();
}

class _NewMessageState extends ConsumerState<NewMessageScreen> {
  final _query = TextEditingController();
  final _name = TextEditingController();
  Timer? _debounce;
  List<UserProfile>? _results;
  bool _group = false;
  bool _creating = false;

  /// Picked for the group, in the order picked.
  final List<UserProfile> _picked = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _name.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    if (text.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final me = ref.read(authStateProvider).value?.uid;
      final q = text.trim().toLowerCase().replaceFirst('@', '');
      try {
        final found = await ref.read(socialProvider).search(text, exclude: me);
        final samples = [
          if (showSamplePosts)
            for (final p in sampleProfiles)
              if (p.username.toLowerCase().startsWith(q) ||
                  p.displayName.toLowerCase().startsWith(q))
                p,
        ];
        if (mounted && text == _query.text) {
          setState(() => _results = [...found, ...samples]);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.somethingWentWrong)),
          );
        }
      }
    });
  }

  void _tap(String me, UserProfile person) {
    if (!_group) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (ctx) => ChatScreen(chat: Chat.direct(me, person.uid)),
        ),
      );
      return;
    }
    final index = _picked.indexWhere((p) => p.uid == person.uid);
    if (index >= 0) {
      setState(() => _picked.removeAt(index));
    } else if (_picked.length + 1 >= maxGroupMembers) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.groupLimit(maxGroupMembers))),
        );
    } else {
      setState(() => _picked.add(person));
    }
  }

  Future<void> _create(String me) async {
    setState(() => _creating = true);
    try {
      final chat = await createGroup(
        ref,
        me: me,
        others: [for (final p in _picked) p.uid],
        name: _name.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (ctx) => ChatScreen(chat: chat)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.somethingWentWrong)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(authStateProvider).value?.uid;
    if (me == null) {
      return const Scaffold();
    }
    final following = ref.watch(followListProvider((me, false)));
    final people = _results ?? following.value ?? const [];
    final pickedIds = {for (final p in _picked) p.uid};
    const side = EdgeInsets.symmetric(horizontal: AppSpace.page);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: AppSpace.xxl),
          children: [
            PageHeader(
              title: _group ? l10n.newGroup : l10n.newMessage,
              trailing: CircleIconButton(
                icon: const AppIcon('close'),
                semanticLabel: l10n.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: side,
              child: SearchField(
                controller: _query,
                hintText: l10n.searchPeopleHint,
                onChanged: _onChanged,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            if (!_group)
              ListTile(
                contentPadding: side,
                leading: SizedBox.square(
                  dimension: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.group_add_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                title: Text(l10n.newGroup, style: AppText.bodyStrong()),
                subtitle: Text(
                  l10n.groupLimit(maxGroupMembers),
                  style: AppText.meta(),
                ),
                onTap: () => setState(() => _group = true),
              )
            else ...[
              Padding(
                padding: side,
                child: TextField(
                  controller: _name,
                  maxLength: maxGroupNameLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.groupNameHint,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Padding(
                padding: side,
                child: Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    for (final p in _picked)
                      InputChip(
                        label: Text(p.name),
                        onDeleted: () => setState(() => _picked.remove(p)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Padding(
                padding: side,
                child: PillButton(
                  label:
                      '${l10n.createGroup} · '
                      '${l10n.groupCount(_picked.length + 1, maxGroupMembers)}',
                  expanded: true,
                  // A group needs at least 3 people, you included.
                  onPressed: _picked.length >= 2 && !_creating
                      ? () => _create(me)
                      : null,
                ),
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            if (_results == null)
              Padding(
                padding: side,
                child: Text(
                  l10n.peopleYouFollow.toUpperCase(),
                  style: AppText.overline(),
                ),
              ),
            const SizedBox(height: AppSpace.xs),
            if (people.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpace.page),
                child: Center(
                  child: Text(
                    _results == null
                        ? l10n.notFollowingAnyone
                        : l10n.noPeopleFound,
                    style: AppText.meta(),
                  ),
                ),
              ),
            for (final p in people)
              ListTile(
                contentPadding: side,
                leading: Avatar(name: p.name, photoUrl: p.photoUrl, size: 44),
                title: Text(p.name, style: AppText.bodyStrong()),
                subtitle: p.handle == null
                    ? null
                    : Text(p.handle!, style: AppText.meta()),
                trailing: _group
                    ? Icon(
                        pickedIds.contains(p.uid)
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: pickedIds.contains(p.uid)
                            ? AppColors.accent
                            : AppColors.muted,
                      )
                    : null,
                onTap: () => _tap(me, p),
              ),
          ],
        ),
      ),
    );
  }
}

/// A chat with one person, or a group.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chat});

  final Chat chat;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send(String me) async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await sendMessage(ref, me: me, chat: widget.chat, text: text);
      _text.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.somethingWentWrong)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(authStateProvider.select((a) => a.value?.uid));
    final chat = ref.watch(chatProvider(widget.chat)).value ?? widget.chat;
    final messages = ref.watch(messagesProvider(chat)).value ?? const [];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.sm,
                AppSpace.page,
                AppSpace.sm,
              ),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: AppIcon('back', color: AppColors.accent),
                    semanticLabel: l10n.back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpace.md),
                  if (me != null)
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        // A group's details; the person's profile otherwise.
                        onTap: () => chat.isGroup
                            ? Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (ctx) =>
                                      GroupDetailsScreen(chat: chat),
                                ),
                              )
                            : openProfile(
                                context,
                                chat.others(me).firstOrNull ?? me,
                              ),
                        child: Row(
                          children: [
                            _ChatAvatar(chat: chat, me: me, size: 36),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: Text(
                                _chatTitle(ref, chat, me),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.title(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(l10n.noMessagesYet, style: AppText.meta()),
                    )
                  : ListView(
                      // Newest at the bottom, and the list starts there.
                      reverse: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(AppSpace.page),
                      children: [
                        for (final (i, m) in messages.reversed.indexed)
                          _Bubble(
                            message: m,
                            mine: m.uid == me,
                            color: chat.isGroup && m.uid != me
                                ? memberColor(m.uid)
                                : null,
                            // In a group, who wrote it, above the first of
                            // their messages in a row.
                            showName:
                                chat.isGroup &&
                                m.uid != me &&
                                (i + 1 >= messages.length ||
                                    messages[messages.length - i - 2].uid !=
                                        m.uid),
                          ),
                      ],
                    ),
            ),
            if (me != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  AppSpace.xs,
                  AppSpace.sm,
                  AppSpace.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        maxLength: maxMessageLength,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: l10n.writeMessage,
                          counterText: '',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.sendComment,
                      onPressed: _sending ? null : () => _send(me),
                      icon: Icon(
                        Icons.arrow_upward_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bubble colors for other people in a group: deep enough for white text,
/// none close to the app's orange, which marks your own messages.
const _memberColors = [
  Color(0xFF3B6FB6), // blue
  Color(0xFF2E8B6E), // green
  Color(0xFF8A4FBF), // purple
  Color(0xFFC0447A), // pink
  Color(0xFF1F8A9E), // teal
  Color(0xFF6B7A2E), // olive
  Color(0xFF5A5FCF), // indigo
  Color(0xFFA0522D), // brown
];

/// The same color for [uid] every time, on every phone.
Color memberColor(String uid) =>
    _memberColors[uid.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0x7fffffff) %
        _memberColors.length];

class _Bubble extends ConsumerWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    this.color,
    this.showName = false,
  });

  final ChatMessage message;
  final bool mine;

  /// The writer's own color in a group, with white text.
  final Color? color;
  final bool showName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = showName
        ? ref.watch(profileProvider(message.uid)).value?.name ?? ''
        : '';
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpace.md,
                  top: AppSpace.xs,
                  bottom: 2,
                ),
                child: Text(
                  name,
                  style: AppText.meta(color: color).copyWith(fontSize: 12),
                ),
              ),
            Container(
              margin: const EdgeInsets.only(bottom: AppSpace.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                color: mine ? AppColors.accent : color ?? AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: AppText.body(
                  color: mine || color != null ? Colors.white : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A group's photo, name and members. Its admin can change the photo and
/// name, and remove people.
class GroupDetailsScreen extends ConsumerStatefulWidget {
  const GroupDetailsScreen({super.key, required this.chat});

  final Chat chat;

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsState();
}

class _GroupDetailsState extends ConsumerState<GroupDetailsScreen> {
  bool _saving = false;

  Future<void> _run(Future<void> Function() change) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await change();
    } on PlatformException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(photoErrorMessage(l10n, error))),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _changePhoto(Chat chat) async {
    final choice = await askPhotoSource(
      context,
      title: context.l10n.groupPhoto,
      hasPhoto: chat.photo != null,
    );
    if (choice == null) {
      return;
    }
    await _run(() async {
      Uint8List? bytes;
      if (choice != 'remove') {
        final picked = await ImagePicker().pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: groupPhotoSize,
          maxHeight: groupPhotoSize,
          imageQuality: 70,
        );
        if (picked == null) {
          return;
        }
        bytes = await picked.readAsBytes();
      }
      await setGroupPhoto(ref, chat, bytes);
    });
  }

  Future<void> _remove(Chat chat, String uid, String name) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeMemberConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.removeFromGroup,
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
    if (sure ?? false) {
      await _run(() => removeMember(ref, chat, uid));
    }
  }

  Future<void> _rename(Chat chat) async {
    final l10n = context.l10n;
    final text = TextEditingController(text: chat.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editGroupName),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLength: maxGroupNameLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.groupNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(text.text.trim()),
            child: Text(l10n.saveChanges),
          ),
        ],
      ),
    );
    // Not disposed here: the dialog still uses it while it animates closed.
    if (name != null && name != chat.name) {
      await _run(() => renameGroup(ref, chat, name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(authStateProvider.select((a) => a.value?.uid));
    final chat = ref.watch(chatProvider(widget.chat)).value ?? widget.chat;
    if (me == null) {
      return const Scaffold();
    }
    final isAdmin = chat.admin == me;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpace.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.sm,
                AppSpace.page,
                0,
              ),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: AppIcon('back', color: AppColors.accent),
                    semanticLabel: l10n.back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Center(
              child: Semantics(
                button: true,
                label: l10n.groupPhoto,
                child: GestureDetector(
                  onTap: _saving || !isAdmin ? null : () => _changePhoto(chat),
                  child: Stack(
                    children: [
                      _ChatAvatar(chat: chat, me: me, size: 112),
                      if (isAdmin)
                        PositionedDirectional(
                          end: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.accent,
                            child: _saving
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.onAccent,
                                    ),
                                  )
                                : const Icon(
                                    Icons.photo_camera_rounded,
                                    size: 18,
                                    color: AppColors.onAccent,
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _chatTitle(ref, chat, me),
                      textAlign: TextAlign.center,
                      style: AppText.title(),
                    ),
                  ),
                  if (isAdmin)
                    IconButton(
                      tooltip: l10n.editGroupName,
                      onPressed: _saving ? null : () => _rename(chat),
                      icon: Icon(Icons.edit_rounded, color: AppColors.accent),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              child: Text(
                l10n.groupMembers(chat.members.length).toUpperCase(),
                style: AppText.overline(),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            // The admin first, as in members.
            for (final uid in chat.members)
              _Member(
                uid: uid,
                isAdmin: uid == chat.admin,
                onRemove: isAdmin && uid != me && !_saving
                    ? (name) => _remove(chat, uid, name)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _Member extends ConsumerWidget {
  const _Member({required this.uid, required this.isAdmin, this.onRemove});

  final String uid;
  final bool isAdmin;

  /// Shown to the admin on everyone else; gets the person's name.
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(profileProvider(uid)).value;
    if (profile == null) {
      return const SizedBox.shrink();
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
      leading: Avatar(name: profile.name, photoUrl: profile.photoUrl, size: 44),
      title: Text(profile.name, style: AppText.bodyStrong()),
      subtitle: profile.handle == null
          ? null
          : Text(profile.handle!, style: AppText.meta()),
      trailing: isAdmin
          ? Text(l10n.groupAdmin, style: AppText.meta(color: AppColors.accent))
          : onRemove == null
          ? null
          : IconButton(
              tooltip: l10n.removeFromGroup,
              onPressed: () => onRemove!(profile.name),
              icon: Icon(Icons.person_remove_outlined, color: AppColors.muted),
            ),
      onTap: () => openProfile(context, uid),
    );
  }
}
