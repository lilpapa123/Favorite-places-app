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
    final side = const EdgeInsets.symmetric(horizontal: AppSpace.page);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * (me == null ? 0.3 : 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: side,
              child: Text(l10n.share, style: AppText.title()),
            ),
            const SizedBox(height: AppSpace.sm),
            Padding(
              padding: side,
              child: Row(
                children: [
                  if (link != null)
                    Expanded(
                      child: _ShareAction(
                        icon: Icons.link_rounded,
                        label: l10n.copyLink,
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          await Clipboard.setData(ClipboardData(text: link));
                          navigator.pop();
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text(l10n.linkCopied)),
                            );
                        },
                      ),
                    ),
                  if (link != null) const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: _ShareAction(
                      icon: Icons.ios_share_rounded,
                      label: l10n.shareToApps,
                      onTap: () {
                        Navigator.of(context).pop();
                        SharePlus.instance.share(
                          ShareParams(
                            text: [
                              widget.place.title,
                              if (widget.place.note.isNotEmpty)
                                widget.place.note,
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
            if (me != null) ...[
              const SizedBox(height: AppSpace.lg),
              Padding(
                padding: side,
                child: Text(
                  l10n.sendTo.toUpperCase(),
                  style: AppText.overline(),
                ),
              ),
              Expanded(
                child: targets.isEmpty
                    ? Center(
                        child: Text(
                          l10n.notFollowingAnyone,
                          style: AppText.meta(),
                        ),
                      )
                    : ListView(
                        children: [
                          for (final chat in targets.values)
                            ListTile(
                              contentPadding: side,
                              leading: ChatAvatar(chat: chat, me: me, size: 44),
                              title: Text(
                                chatTitle(ref, chat, me),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.bodyStrong(),
                              ),
                              trailing: Icon(
                                _picked.containsKey(chat.id)
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: _picked.containsKey(chat.id)
                                    ? AppColors.accent
                                    : AppColors.muted,
                              ),
                              onTap: () => setState(() {
                                if (_picked.remove(chat.id) == null) {
                                  _picked[chat.id] = chat;
                                }
                              }),
                            ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  AppSpace.sm,
                  AppSpace.page,
                  AppSpace.md,
                ),
                child: PillButton(
                  label: _picked.isEmpty
                      ? l10n.send
                      : '${l10n.send} · ${_picked.length}',
                  expanded: true,
                  onPressed: _picked.isEmpty || _sending
                      ? null
                      : () => _send(me),
                ),
              ),
            ],
          ],
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
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(height: AppSpace.xs),
            Text(label, style: AppText.label(), textAlign: TextAlign.center),
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
