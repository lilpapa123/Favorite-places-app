import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/chat_provider.dart';
import 'package:favorite_places/providers/comments_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/screens/chat.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/cover_post_card.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/place_photo.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Send the post to your chats and people you follow (several at once),
/// copy its link, or hand it to another app.
void showShareSheet(BuildContext context, String owner, Place place) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    builder: (ctx) => _ShareSheet(owner: owner, place: place),
  );
}

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.owner, required this.place});

  final String owner;
  final Place place;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  /// Picked chats, by id.
  final Map<String, Chat> _picked = {};
  bool _sending = false;
  bool _copied = false;

  // shortcut: posts have no web page yet, so the link opens the place on
  // Google Maps; point it at the post once there is one.
  String? get _link {
    final location = widget.place.location;
    return location == null
        ? null
        : 'https://www.google.com/maps/search/?api=1&query='
              '${location.latitude},${location.longitude}';
  }

  Future<void> _send(String me) async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final post = SharedPost(
      id: widget.place.id,
      owner: widget.owner,
      title: widget.place.title,
    );
    setState(() => _sending = true);
    try {
      await Future.wait([
        for (final chat in _picked.values)
          sendMessage(ref, me: me, chat: chat, post: post),
      ]);
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.postSent)));
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(authStateProvider.select((a) => a.value?.uid));
    final link = _link;
    final place = widget.place;
    final owner = ref.watch(profileProvider(widget.owner)).value;
    // Your chats first, then people you follow you have no chat with yet.
    final targets = <String, Chat>{};
    if (me != null) {
      for (final summary in ref.watch(chatsProvider).value ?? const []) {
        targets[summary.chat.id] = summary.chat;
      }
      for (final p
          in ref.watch(followListProvider((me, false))).value ?? const []) {
        final chat = Chat.direct(me, p.uid);
        targets.putIfAbsent(chat.id, () => chat);
      }
    }
    final picked = _picked.values.toList();
    final sendLabel = switch (picked.length) {
      0 => l10n.pickSomeoneToSend,
      1 => l10n.sendToName(_firstName(chatTitle(ref, picked.first, me ?? ''))),
      final n => l10n.sendToCount(n),
    };
    final city = place.location?.cityCountry ?? '';

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.share,
                    style: AppText.heading().copyWith(fontSize: 22),
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accentSoft,
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // What you're sharing.
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 56,
                    child: PlacePhoto(
                      photo: place.photos.firstOrNull,
                      tint: AppColors.tintFor(place.id),
                      iconSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong().copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (owner != null) l10n.byOwner(owner.name),
                          if (city.isNotEmpty) city,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.meta().copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (me != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                l10n.sendTo,
                style: AppText.label(color: AppColors.label)
                    .copyWith(fontSize: 13),
              ),
            ),
            SizedBox(
              height: 92,
              child: targets.isEmpty
                  ? Center(
                      child: Text(
                        l10n.notFollowingAnyone,
                        style: AppText.meta(),
                      ),
                    )
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final chat in targets.values)
                          _PickPerson(
                            chat: chat,
                            me: me,
                            picked: _picked.containsKey(chat.id),
                            onTap: () => setState(() {
                              if (_picked.remove(chat.id) == null) {
                                _picked[chat.id] = chat;
                              }
                            }),
                          ),
                      ],
                    ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                if (link != null) ...[
                  Expanded(
                    child: _ShareAction(
                      icon: _copied ? Icons.check_rounded : Icons.link_rounded,
                      label: _copied ? l10n.linkCopied : l10n.copyLink,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: link));
                        if (mounted) {
                          setState(() => _copied = true);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _ShareAction(
                    icon: Icons.ios_share_rounded,
                    label: l10n.shareToApps,
                    onTap: () {
                      Navigator.of(context).pop();
                      SharePlus.instance.share(
                        ShareParams(
                          text: [
                            place.title,
                            if (place.note.isNotEmpty) place.note,
                            ?link,
                          ].join('\n'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (me != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: PillButton(
                label: sendLabel,
                icon: Icons.send_rounded,
                expanded: true,
                large: true,
                onPressed: picked.isEmpty || _sending ? null : () => _send(me),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

String _firstName(String name) => name.split(' ').first;

/// A chat to send to: its round photo, ringed and ticked when picked, and
/// the first name (or the group's name) under it.
class _PickPerson extends ConsumerWidget {
  const _PickPerson({
    required this.chat,
    required this.me,
    required this.picked,
    required this.onTap,
  });

  final Chat chat;
  final String me;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = chatTitle(ref, chat, me);
    return Semantics(
      button: true,
      selected: picked,
      label: title,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              const SizedBox(height: 4),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: picked ? AppColors.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ChatAvatar(chat: chat, me: me, size: 48),
                  ),
                  if (picked)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: AppColors.onAccent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                chat.isGroup ? title : _firstName(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.meta(color: AppColors.ink).copyWith(
                  fontSize: 12,
                  fontWeight: picked ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: AlignmentDirectional.centerStart,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: AppColors.accent),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodyStrong().copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Everyone's comments on [place], and a box to add one when signed in.
void showCommentsSheet(BuildContext context, Place place) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => _CommentsSheet(place: place),
  );
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.place});

  final Place place;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send(String uid) async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await postComment(ref, placeId: widget.place.id, uid: uid, text: text);
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
    final comments =
        ref.watch(commentsProvider(widget.place.id)).value ?? const [];
    return Padding(
      // Stays above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            0,
            AppSpace.page,
            AppSpace.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.comments, style: AppText.title()),
              const SizedBox(height: AppSpace.md),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                ),
                child: comments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.lg,
                        ),
                        child: Text(l10n.noCommentsYet, style: AppText.meta()),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final comment in comments)
                            _CommentRow(comment: comment),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpace.sm),
              if (me == null)
                Text(l10n.signInToComment, style: AppText.meta())
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        maxLength: maxCommentLength,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: l10n.addComment,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentRow extends ConsumerWidget {
  const _CommentRow({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(comment.uid)).value;
    final name = profile?.name ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(name: name, photoUrl: profile?.photoUrl, size: 32),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: name, style: AppText.bodyStrong()),
                      TextSpan(
                        text: '  ${timeAgo(context.l10n, comment.createdAt)}',
                        style: AppText.meta().copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(comment.text, style: AppText.body()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
