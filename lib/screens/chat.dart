import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/chat_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/cover_post_card.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Above the tab bar, so the message box at the bottom is not hidden.
void openChat(BuildContext context, String uid) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute<void>(builder: (ctx) => ChatScreen(other: uid)));
}

void openInbox(BuildContext context) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute<void>(builder: (ctx) => const InboxScreen()));
}

/// The signed-in user's chats, newest first.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final chats = ref.watch(chatsProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            PageHeader(
              title: l10n.messagesTitle,
              trailing: CircleIconButton(
                icon: const AppIcon('close'),
                semanticLabel: l10n.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            ...chats.when(
              loading: () => [
                Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ],
              error: (_, _) => [
                Center(
                  child: Text(l10n.somethingWentWrong, style: AppText.meta()),
                ),
              ],
              data: (list) => list.isEmpty
                  ? [
                      Center(
                        child: Text(l10n.noMessagesYet, style: AppText.meta()),
                      ),
                    ]
                  : [for (final chat in list) _ChatTile(chat: chat)],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.chat});

  final ChatSummary chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(chat.other)).value;
    final name = profile?.name ?? '';
    return InkWell(
      onTap: () => openChat(context, chat.other),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.page,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            Avatar(name: name, photoUrl: profile?.photoUrl, size: 48),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.bodyStrong()),
                  Text(
                    chat.lastText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              timeAgo(context.l10n, chat.lastAt),
              style: AppText.meta().copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// One-to-one chat with [other].
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.other});

  final String other;

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
      await sendMessage(ref, me: me, other: widget.other, text: text);
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
    final profile = ref.watch(profileProvider(widget.other)).value;
    final name = profile?.name ?? '';
    final messages =
        ref.watch(messagesProvider(widget.other)).value ?? const [];
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
                  Avatar(name: name, photoUrl: profile?.photoUrl, size: 36),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(),
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
                        for (final m in messages.reversed)
                          _Bubble(message: m, mine: m.uid == me),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpace.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: mine ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            message.text,
            style: AppText.body(color: mine ? AppColors.onAccent : null),
          ),
        ),
      ),
    );
  }
}
