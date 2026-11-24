import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/comments_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/cover_post_card.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Copy the link, or hand the post to another app. Sending to friends and
/// groups inside the app will join this sheet later.
void showShareSheet(BuildContext context, Place place) {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final location = place.location;
  // shortcut: posts have no web page yet, so the link opens the place on
  // Google Maps; point it at the post once there is one.
  final link = location == null
      ? null
      : 'https://www.google.com/maps/search/?api=1&query='
            '${location.latitude},${location.longitude}';
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          0,
          AppSpace.page,
          AppSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.share, style: AppText.title()),
            const SizedBox(height: AppSpace.sm),
            if (link != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.link_rounded, color: AppColors.accent),
                title: Text(l10n.copyLink, style: AppText.row()),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
                },
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.ios_share_rounded, color: AppColors.accent),
              title: Text(l10n.shareToApps, style: AppText.row()),
              onTap: () {
                Navigator.of(ctx).pop();
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
