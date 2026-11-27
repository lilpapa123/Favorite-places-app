import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/badges.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/chat_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/screens/europe_map.dart';
import 'package:favorite_places/screens/chat.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/badge_widgets.dart';
import 'package:favorite_places/widgets/cover_post_card.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/places_two_columns.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void openProfile(BuildContext context, String uid) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (ctx) => ProfileScreen(uid: uid)));
}

/// Someone's profile: who they are, their counts, Follow and Message, and
/// their places.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(uid)).value;
    final places = ref.watch(placesOfUserProvider(uid)).value ?? const [];
    final name = profile?.name ?? '';
    final me = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.sm,
                AppSpace.page,
                AppSpace.lg,
              ),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: AppIcon('back', color: AppColors.accent),
                    semanticLabel: context.l10n.back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instagram-style: photo with the counters beside it.
                  Row(
                    children: [
                      Avatar(name: name, photoUrl: profile?.photoUrl, size: 72),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: ProfileStats(
                          uid: uid,
                          places: places.length,
                          card: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppText.title()),
                            if (profile?.handle case final handle?)
                              Text(handle, style: AppText.meta()),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      EuropeMapButton(uid: uid),
                    ],
                  ),
                  if (profile != null && profile.bio.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(profile.bio, style: AppText.note()),
                  ],
                  if (earnedBadges(places).isNotEmpty) ...[
                    const SizedBox(height: AppSpace.sm),
                    EarnedBadgesRow(places: places, showNext: false),
                  ],
                  const SizedBox(height: AppSpace.lg),
                  if (me != null && me != uid)
                    Row(
                      children: [
                        Expanded(child: FollowButton(uid: uid)),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: PillButton(
                            label: context.l10n.message,
                            variant: PillButtonVariant.soft,
                            expanded: true,
                            onPressed: () =>
                                openChat(context, Chat.direct(me, uid)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpace.xxl),
                  if (places.isEmpty)
                    Center(
                      child: Text(
                        context.l10n.noPlacesYet,
                        style: AppText.meta(),
                      ),
                    ),
                  PlacesTwoColumns(
                    places: places,
                    onTap: (place) => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (ctx) => PostScreen(owner: uid, place: place),
                      ),
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

/// One shared place on its own, as it looks on Discover.
class PostScreen extends StatelessWidget {
  const PostScreen({super.key, required this.owner, required this.place});

  final String owner;
  final Place place;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.sm,
                AppSpace.page,
                AppSpace.lg,
              ),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: AppIcon('back', color: AppColors.accent),
                    semanticLabel: context.l10n.back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            CoverPostCard(owner: owner, place: place),
          ],
        ),
      ),
    );
  }
}

/// Followers (or following) of [uid].
class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({
    super.key,
    required this.uid,
    required this.followers,
  });

  final String uid;
  final bool followers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final people = ref.watch(followListProvider((uid, followers)));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
          children: [
            PageHeader(
              title: followers ? l10n.followersTitle : l10n.followingTitle,
              trailing: CircleIconButton(
                icon: const AppIcon('close'),
                semanticLabel: l10n.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            ...people.when(
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
                        child: Text(
                          followers
                              ? l10n.noFollowersYet
                              : l10n.notFollowingAnyone,
                          style: AppText.meta(),
                        ),
                      ),
                    ]
                  : [for (final p in list) PersonTile(profile: p)],
            ),
          ],
        ),
      ),
    );
  }
}
