import 'dart:io';

import 'package:favorite_places/data/sample_posts.dart';
import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/screens/profile.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Round photo, or the first letter of [name] on red.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    this.image,
    this.photoUrl,
    this.size = 40,
  });

  final String name;

  /// A photo on this phone; wins over [photoUrl].
  final File? image;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: image != null
            ? Image.file(
                image!,
                fit: BoxFit.cover,
                cacheWidth: size.round() * 3,
              )
            : photoUrl != null
            ? Image.network(photoUrl!, fit: BoxFit.cover)
            : ColoredBox(
                color: AppColors.accent,
                child: Center(
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: AppText.title(color: AppColors.onAccent)
                        .copyWith(fontSize: size * 0.42),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Follow / Following toggle for [uid]; hidden on your own profile and when
/// signed out.
class FollowButton extends ConsumerStatefulWidget {
  const FollowButton({super.key, required this.uid, this.compact = false});

  final String uid;
  final bool compact;

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _busy = false;

  Future<void> _toggle(String me, bool following) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final social = ref.read(socialProvider);
      if (following) {
        await social.unfollow(me, widget.uid);
      } else {
        await social.follow(me, widget.uid);
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).value?.uid;
    // Sample people exist only on this phone: following them would write
    // to Firestore.
    if (me == null || me == widget.uid || isSampleUid(widget.uid)) {
      return const SizedBox.shrink();
    }
    final following =
        ref.watch(followingIdsProvider).value?.contains(widget.uid) ?? false;
    return PillButton(
      label: following ? context.l10n.followingButton : context.l10n.follow,
      variant: following
          ? PillButtonVariant.outlined
          : PillButtonVariant.filled,
      expanded: !widget.compact,
      onPressed: _busy ? null : () => _toggle(me, following),
    );
  }
}

/// A person in search results or a followers list; opens their profile.
class PersonTile extends StatelessWidget {
  const PersonTile({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openProfile(context, profile.uid),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.page,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            Avatar(name: profile.name, photoUrl: profile.photoUrl, size: 44),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name, style: AppText.row()),
                  if (profile.handle case final handle?)
                    Text(handle, style: AppText.meta()),
                ],
              ),
            ),
            FollowButton(uid: profile.uid, compact: true),
          ],
        ),
      ),
    );
  }
}

/// Card of counters ("15 Places | 3 Followers | 4 Following").
class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.stats, this.card = true});

  /// (value, label, onTap).
  final List<(int, String, VoidCallback?)> stats;

  /// False when it sits inside another card, beside the avatar.
  final bool card;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: card ? 86 : 64,
      decoration: BoxDecoration(
        color: card ? AppColors.surface : null,
        borderRadius: AppRadius.cardAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0 && card)
              Container(width: 1, height: 38, color: AppColors.divider),
            Expanded(
              child: InkWell(
                onTap: stats[i].$3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${stats[i].$1}', style: AppText.stat()),
                    Text(
                      stats[i].$2,
                      style: AppText.meta().copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Places, followers and following for [uid]; the follower counts open
/// their lists.
class ProfileStats extends ConsumerWidget {
  const ProfileStats({
    super.key,
    required this.uid,
    required this.places,
    this.card = true,
  });

  final String uid;
  final int places;
  final bool card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final (followers, following) =
        ref.watch(followCountsProvider(uid)).value ?? (0, 0);
    void open(bool followersList) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => FollowListScreen(uid: uid, followers: followersList),
      ),
    );
    return StatsCard(
      card: card,
      stats: [
        (places, l10n.statPlaces(places), null),
        (followers, l10n.statFollowers(followers), () => open(true)),
        (following, l10n.statFollowing, () => open(false)),
      ],
    );
  }
}

/// "(K) Khalid  @khalid" above a shared place card; opens their profile.
class OwnerRow extends ConsumerWidget {
  const OwnerRow({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(uid)).value;
    final name = profile?.name ?? '';
    return InkWell(
      onTap: () => openProfile(context, uid),
      child: Row(
        children: [
          Avatar(name: name, photoUrl: profile?.photoUrl, size: 30),
          const SizedBox(width: AppSpace.sm),
          Text(name, style: AppText.bodyStrong()),
          if (profile?.handle case final handle?) ...[
            const SizedBox(width: AppSpace.xs),
            Text(handle, style: AppText.meta()),
          ],
        ],
      ),
    );
  }
}
