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
import 'package:favorite_places/widgets/golden_hour.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/place_photo.dart';
import 'package:favorite_places/widgets/profile_photo_picker.dart';
import 'package:favorite_places/widgets/search_field.dart';
import 'package:favorite_places/widgets/image_input.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
String chatTitle(WidgetRef ref, Chat chat, String me) {
  if (chat.name.isNotEmpty) {
    return chat.name;
  }
  return [
    for (final uid in chat.others(me))
      ref.watch(profileProvider(uid)).value?.name ?? '',
  ].where((n) => n.isNotEmpty).join(', ');
}

/// The person's photo, or a group icon.
class ChatAvatar extends ConsumerWidget {
  const ChatAvatar({
    super.key,
    required this.chat,
    required this.me,
    this.size = 48,
  });

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

/// The Messages tab, from the design: new group and new message buttons, a
/// search that starts a chat, people you follow for a quick start, then your
/// chats on a frosted card, newest first.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  void _new(BuildContext context, {bool group = false}) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (ctx) => NewMessageScreen(startAsGroup: group),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(authStateProvider).value?.uid;
    final chats = ref.watch(chatsProvider);
    final following = me == null
        ? const <UserProfile>[]
        : ref.watch(followListProvider((me, false))).value ?? const [];
    Widget note(String text) => Padding(
      padding: const EdgeInsets.all(AppSpace.page),
      child: Center(
        child: Text(text, style: AppText.meta(), textAlign: TextAlign.center),
      ),
    );
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, 18, AppSpace.page, 10),
      child: Text(
        text.toUpperCase(),
        style: AppText.overline(color: AppColors.muted),
      ),
    );
    return Scaffold(
      body: GoldenHour(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
            children: [
              PageHeader(
                title: l10n.messagesTitle,
                subtitle: l10n.messagesSubtitle,
                trailing: me == null
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleIconButton(
                            icon: AppIcon(
                              'tab_people',
                              size: 20,
                              color: AppColors.ink,
                            ),
                            semanticLabel: l10n.newGroup,
                            background: AppColors.surface.withValues(
                              alpha: .82,
                            ),
                            onPressed: () => _new(context, group: true),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          _GradientCircle(
                            label: l10n.newMessage,
                            onTap: () => _new(context),
                            child: AppIcon(
                              'edit',
                              size: 20,
                              color: AppColors.onAccent,
                            ),
                          ),
                        ],
                      ),
              ),
              if (me == null)
                note(l10n.signInToMessage)
              else ...[
                // Opens New message, where the search happens.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.page,
                  ),
                  child: Semantics(
                    button: true,
                    label: l10n.searchPeopleHint,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => _new(context),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: .82),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.isDark
                                ? Colors.white.withValues(alpha: .08)
                                : const Color(0x1F2A7C13),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            AppIcon('search', size: 18, color: AppColors.muted),
                            const SizedBox(width: 10),
                            Text(
                              l10n.searchPeopleHint,
                              style: AppText.body(color: AppColors.faint),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (following.isNotEmpty) ...[
                  heading(l10n.peopleYouFollow),
                  SizedBox(
                    height: 82,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final person in following)
                          _QuickPerson(
                            profile: person,
                            onTap: () =>
                                openChat(context, Chat.direct(me, person.uid)),
                          ),
                      ],
                    ),
                  ),
                ],
                heading(l10n.chats),
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
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpace.page,
                            ),
                            clipBehavior: Clip.antiAlias,
                            decoration: GoldenHour.card(),
                            child: Column(
                              children: [
                                for (final (i, summary) in list.indexed) ...[
                                  if (i > 0)
                                    Divider(
                                      height: 1,
                                      indent: 74,
                                      color: AppColors.accent.withValues(
                                        alpha: .1,
                                      ),
                                    ),
                                  _ChatTile(summary: summary, me: me),
                                ],
                              ],
                            ),
                          ),
                        ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A round gradient-green button, the design's main action.
class _GradientCircle extends StatelessWidget {
  const _GradientCircle({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent,
            AppColors.isDark
                ? const Color(0xFF5FAE40)
                : const Color(0xFF4E9E33),
          ],
        ),
        boxShadow: AppColors.isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: .3),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(dimension: 44, child: Center(child: child)),
        ),
      ),
    ),
  );
}

/// Someone you follow, as a round photo with their first name: tap to chat.
class _QuickPerson extends StatelessWidget {
  const _QuickPerson({required this.profile, required this.onTap});

  final UserProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${context.l10n.message}: ${profile.name}',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        child: Column(
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
              ),
              child: Avatar(
                name: profile.name,
                photoUrl: profile.photoUrl,
                size: 50,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              profile.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.meta(color: AppColors.ink).copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.summary, required this.me});

  final ChatSummary summary;
  final String me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = summary.chat;
    // A shared post shows as a pin line.
    final post = summary.lastText.startsWith('📍 ');
    return InkWell(
      onTap: () => openChat(context, chat),
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              ChatAvatar(chat: chat, me: me),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatTitle(ref, chat, me),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyStrong().copyWith(fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Text(
                          timeAgo(context.l10n, summary.lastAt),
                          style: AppText.meta(color: AppColors.faint)
                              .copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (post) ...[
                          AppIcon(
                            'pin_small',
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            post
                                ? summary.lastText.substring(3)
                                : summary.lastText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.meta().copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search people, or pick from those you follow, to message them or to make
/// a group of up to [maxGroupMembers].
class NewMessageScreen extends ConsumerStatefulWidget {
  const NewMessageScreen({super.key, this.startAsGroup = false});

  /// Opens straight into making a group.
  final bool startAsGroup;

  @override
  ConsumerState<NewMessageScreen> createState() => _NewMessageState();
}

class _NewMessageState extends ConsumerState<NewMessageScreen> {
  final _query = TextEditingController();
  final _name = TextEditingController();
  Timer? _debounce;
  List<UserProfile>? _results;
  late bool _group = widget.startAsGroup;
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
    final other = me == null || chat.isGroup
        ? null
        : ref.watch(profileProvider(chat.others(me).firstOrNull ?? me)).value;
    final frost = AppColors.background.withValues(alpha: .86);
    final edge = BorderSide(color: AppColors.accent.withValues(alpha: .08));
    return Scaffold(
      body: GoldenHour(
        child: Column(
          children: [
            // Frosted header with who you're talking to.
            Container(
              padding: EdgeInsets.fromLTRB(
                12,
                MediaQuery.paddingOf(context).top + 4,
                12,
                10,
              ),
              decoration: BoxDecoration(
                color: frost,
                border: Border(bottom: edge),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.back,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: AppIcon('back', color: AppColors.ink),
                  ),
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
                            ChatAvatar(chat: chat, me: me, size: 42),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chatTitle(ref, chat, me),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.bodyStrong().copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (chat.isGroup)
                                    Text(
                                      l10n.groupMembers(chat.members.length),
                                      style: AppText.meta().copyWith(
                                        fontSize: 12,
                                      ),
                                    )
                                  else if (other?.username.isNotEmpty ?? false)
                                    Text(
                                      '@${other!.username}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.meta().copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
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
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      children: [
                        for (final (i, m) in messages.reversed.indexed) ...[
                          _Bubble(
                            message: m,
                            mine: m.uid == me,
                            // In a group, others' photos sit beside their
                            // messages: shown by the last of a run, with
                            // room kept beside the rest.
                            avatar: !chat.isGroup || m.uid == me
                                ? _Avatar.none
                                : i == 0 ||
                                      messages[messages.length - i].uid != m.uid
                                ? _Avatar.shown
                                : _Avatar.space,
                            // Who wrote it, above the first of a run.
                            showName:
                                chat.isGroup &&
                                m.uid != me &&
                                (i + 1 >= messages.length ||
                                    messages[messages.length - i - 2].uid !=
                                        m.uid),
                          ),
                          // The day, above its first message (the list runs
                          // upwards, so it comes after it here).
                          if (i + 1 >= messages.length ||
                              !_sameDay(
                                messages[messages.length - i - 2].createdAt,
                                m.createdAt,
                              ))
                            _DayChip(day: m.createdAt),
                        ],
                      ],
                    ),
            ),
            if (me != null)
              Container(
                padding: EdgeInsets.fromLTRB(
                  12,
                  10,
                  12,
                  10 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: BoxDecoration(
                  color: frost,
                  border: Border(top: edge),
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
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: _composerBorder(),
                          enabledBorder: _composerBorder(),
                          focusedBorder: _composerBorder(AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GradientCircle(
                      label: l10n.sendComment,
                      onTap: () => _sending ? null : _send(me),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 20,
                        color: AppColors.onAccent,
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

  static OutlineInputBorder _composerBorder([Color? color]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color: color ?? AppColors.accent.withValues(alpha: .14),
          width: 1.5,
        ),
      );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today", "Yesterday" or the date, between days.
class _DayChip extends StatelessWidget {
  const _DayChip({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final label = _sameDay(day, now)
        ? l10n.today
        : _sameDay(day, now.subtract(const Duration(days: 1)))
        ? l10n.yesterday
        : DateFormat.MMMd(l10n.localeName).format(day);
    return Center(
      child: Container(
        height: 26,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accentSoft.withValues(alpha: .8),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          label,
          style: AppText.label(color: AppColors.muted).copyWith(fontSize: 12),
        ),
      ),
    );
  }
}

enum _Avatar { none, shown, space }

/// A post sent in a chat, as a little post card: the photo with its type,
/// the title, and who shared it from where; opens the post.
class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post, required this.mine});

  final SharedPost post;
  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final place = ref.watch(sharedPostProvider(post)).value;
    final owner = ref.watch(profileProvider(post.owner)).value;
    final city = place?.location?.cityCountry ?? '';
    const big = Radius.circular(20);
    const small = Radius.circular(6);
    return GestureDetector(
      onTap: place == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (ctx) => PostScreen(owner: post.owner, place: place),
              ),
            ),
      child: Container(
        width: 236,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: big,
            topRight: big,
            bottomLeft: mine ? big : small,
            bottomRight: mine ? small : big,
          ),
          boxShadow: AppColors.isDark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x38B98E7A),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlacePhoto(
                    photo: place?.photos.firstOrNull,
                    tint: AppColors.tintFor(post.id),
                  ),
                  if (place != null)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xEBFFFBE6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const AppIcon(
                              'pin_small',
                              size: 12,
                              color: Color(0xFF2A7C13),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              place.category.label(l10n).toUpperCase(),
                              style:
                                  AppText.label(color: const Color(0xFF2A7C13))
                                      .copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place?.title ?? post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong().copyWith(fontSize: 14),
                  ),
                  if (owner != null || city.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        [
                          if (owner != null) l10n.byOwner(owner.name),
                          if (city.isNotEmpty) city,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.meta().copyWith(fontSize: 12),
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

class _Bubble extends ConsumerWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    this.avatar = _Avatar.none,
    this.showName = false,
  });

  static const double _avatarSize = 28;

  final ChatMessage message;
  final bool mine;
  final _Avatar avatar;
  final bool showName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = showName || avatar == _Avatar.shown
        ? ref.watch(profileProvider(message.uid)).value
        : null;
    final name = showName ? profile?.name ?? '' : '';
    final bubble = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpace.md,
              top: AppSpace.xs,
              bottom: 2,
            ),
            child: Text(name, style: AppText.meta().copyWith(fontSize: 12)),
          ),
        if (message.post case final post?)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: _PostCard(post: post, mine: mine),
          ),
        if (message.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpace.xs),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? null : AppColors.surface,
              gradient: mine
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent,
                        AppColors.isDark
                            ? const Color(0xFF5FAE40)
                            : const Color(0xFF4E9E33),
                      ],
                    )
                  : null,
              // The corner by the speaker is tucked in.
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(mine ? 20 : 6),
                bottomRight: Radius.circular(mine ? 6 : 20),
              ),
              boxShadow: AppColors.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: mine
                            ? AppColors.accent.withValues(alpha: .25)
                            : const Color(0x24B98E7A),
                        blurRadius: mine ? 16 : 12,
                        offset: Offset(0, mine ? 6 : 4),
                      ),
                    ],
            ),
            child: Text(
              message.text,
              style: AppText.body(color: mine ? AppColors.onAccent : null)
                  .copyWith(fontSize: 15, height: 1.4),
            ),
          ),
      ],
    );
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: avatar == _Avatar.none
            ? bubble
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.xs),
                    child: avatar == _Avatar.shown
                        ? GestureDetector(
                            onTap: () => openProfile(context, message.uid),
                            child: Avatar(
                              name: profile?.name ?? '',
                              photoUrl: profile?.photoUrl,
                              size: _avatarSize,
                            ),
                          )
                        : const SizedBox(width: _avatarSize),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Flexible(child: bubble),
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
                      ChatAvatar(chat: chat, me: me, size: 112),
                      if (isAdmin)
                        PositionedDirectional(
                          end: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.accent,
                            child: _saving
                                ? SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.onAccent,
                                    ),
                                  )
                                : Icon(
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
                      chatTitle(ref, chat, me),
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
