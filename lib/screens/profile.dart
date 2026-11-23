import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
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

/// Someone's profile: who they are, their counts, Follow, and their places.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(uid)).value;
    final places = ref.watch(placesOfUserProvider(uid)).value ?? const [];
    final name = profile?.name ?? '';

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
                  Text(name, style: AppText.title()),
                  if (profile?.handle case final handle?)
                    Text(handle, style: AppText.meta()),
                  if (profile != null && profile.bio.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(profile.bio, style: AppText.note()),
                  ],
                  const SizedBox(height: AppSpace.lg),
                  FollowButton(uid: uid),
                  const SizedBox(height: AppSpace.xxl),
                  if (places.isEmpty)
                    Center(
                      child: Text(
                        context.l10n.noPlacesYet,
                        style: AppText.meta(),
                      ),
                    ),
                  // shortcut: other people's places have no detail screen
                  // yet, so the photos are not tappable.
                  PlacesTwoColumns(places: places),
                ],
              ),
            ),
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
