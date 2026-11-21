import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/badges.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

extension AppBadgeL10n on AppBadge {
  String title(AppLocalizations l) => switch (this) {
    AppBadge.firstSteps => l.badgeFirstSteps,
    AppBadge.cityHopper => l.badgeCityHopper,
    AppBadge.globetrotter => l.badgeGlobetrotter,
    AppBadge.frequentFlyer => l.badgeFrequentFlyer,
    AppBadge.roadTripper => l.badgeRoadTripper,
    AppBadge.backpacker => l.badgeBackpacker,
    AppBadge.shutterbug => l.badgeShutterbug,
    AppBadge.summitSeeker => l.badgeSummitSeeker,
    AppBadge.jungleExplorer => l.badgeJungleExplorer,
    AppBadge.beachBum => l.badgeBeachBum,
    AppBadge.happyCamper => l.badgeHappyCamper,
    AppBadge.stargazer => l.badgeStargazer,
  };

  String howTo(AppLocalizations l) => switch (this) {
    AppBadge.firstSteps => l.badgeFirstStepsHow,
    AppBadge.cityHopper => l.badgeCityHopperHow,
    AppBadge.globetrotter => l.badgeGlobetrotterHow,
    AppBadge.frequentFlyer => l.badgeFrequentFlyerHow,
    AppBadge.roadTripper => l.badgeRoadTripperHow,
    AppBadge.backpacker => l.badgeBackpackerHow,
    AppBadge.shutterbug => l.badgeShutterbugHow,
    AppBadge.summitSeeker => l.badgeSummitSeekerHow,
    AppBadge.jungleExplorer => l.badgeJungleExplorerHow,
    AppBadge.beachBum => l.badgeBeachBumHow,
    AppBadge.happyCamper => l.badgeHappyCamperHow,
    AppBadge.stargazer => l.badgeStargazerHow,
  };
}

/// Grayscale, for badges not earned yet.
const _locked = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 0.35, 0, //
]);

class BadgeImage extends StatelessWidget {
  const BadgeImage(this.badge, {super.key, this.size = 40, this.earned = true});

  final AppBadge badge;
  final double size;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final image = SvgPicture.asset(badge.path, width: size, height: size);
    return earned ? image : ColorFiltered(colorFilter: _locked, child: image);
  }
}

/// Badges spotlight under the name on Account: the top earned badge (or the
/// empty-state trophy), the next badge to chase, and an x/12 progress ring.
/// Tap to see all badges and how to earn them.
class EarnedBadgesRow extends StatelessWidget {
  const EarnedBadgesRow({super.key, required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final earned = earnedBadges(places);
    final total = AppBadge.values.length;
    // Badges are listed easiest first, so the last earned is the best one.
    final top = earned.isEmpty ? null : earned.last;
    final next = AppBadge.values.where((b) => !earned.contains(b)).firstOrNull;
    return Semantics(
      button: true,
      label:
          '${l10n.badgesTitle}: ${l10n.badgesProgress(earned.length, total)}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showBadgesSheet(context, earned),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Row(
            children: [
              if (top != null)
                BadgeImage(top, size: 72)
              else
                SizedBox.square(
                  dimension: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      size: 32,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      top?.title(l10n) ?? l10n.noBadgesYet,
                      style: AppText.bodyStrong(),
                    ),
                    if (next != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          BadgeImage(next, size: 22, earned: false),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${next.title(l10n)}: ${next.howTo(l10n)}',
                              style: AppText.meta().copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              SizedBox.square(
                dimension: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 52,
                      child: CircularProgressIndicator(
                        value: earned.length / total,
                        strokeWidth: 5,
                        color: AppColors.accent,
                        backgroundColor: AppColors.accentSoft,
                      ),
                    ),
                    Text(
                      '${earned.length}/$total',
                      style: AppText.label(color: AppColors.accent),
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

/// All 12 badges: earned in color, locked in gray, each with how to earn it.
void showBadgesSheet(BuildContext context, Set<AppBadge> earned) {
  final l10n = context.l10n;
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          0,
          AppSpace.page,
          AppSpace.xxl,
        ),
        children: [
          Text(l10n.badgesTitle, style: AppText.title()),
          Text(
            l10n.badgesProgress(earned.length, AppBadge.values.length),
            style: AppText.meta(),
          ),
          const SizedBox(height: AppSpace.lg),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpace.lg,
            crossAxisSpacing: AppSpace.md,
            childAspectRatio: 0.8,
            children: [
              for (final badge in AppBadge.values)
                Column(
                  children: [
                    BadgeImage(badge, size: 84, earned: earned.contains(badge)),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      badge.title(l10n),
                      textAlign: TextAlign.center,
                      style: AppText.label(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      earned.contains(badge)
                          ? l10n.badgeEarned
                          : badge.howTo(l10n),
                      textAlign: TextAlign.center,
                      style: AppText.meta(
                        color: earned.contains(badge)
                            ? AppColors.accent
                            : AppColors.muted,
                      ).copyWith(fontSize: 11),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
