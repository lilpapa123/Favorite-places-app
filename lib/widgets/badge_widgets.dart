import 'dart:math' as math;

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/badges.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/badge_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// empty-state trophy) and the next badge to chase.
/// Tap to see all badges and how to earn them.
class EarnedBadgesRow extends StatelessWidget {
  const EarnedBadgesRow({
    super.key,
    required this.places,
    this.showNext = true,
  });

  final List<Place> places;

  /// The "next badge: how to earn it" hint; off on other people's profiles,
  /// where it would tell the viewer what to do.
  final bool showNext;

  /// "City Hopper: Save places in 3 cities." under the badges.
  Widget? _nextHint(AppLocalizations l10n, AppBadge? next) => next == null
      ? null
      : Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
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
        );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final earned = earnedBadges(places);
    final total = AppBadge.values.length;
    // Badges are listed easiest first, so the last earned is the best one.
    final top = earned.isEmpty ? null : earned.last;
    final next = showNext
        ? AppBadge.values.where((b) => !earned.contains(b)).firstOrNull
        : null;
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
              if (earned.length > 1)
                // Several earned: all of them side by side, best first.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BadgeStack(badges: earned.toList().reversed.toList()),
                      ?_nextHint(l10n, next),
                    ],
                  ),
                )
              else ...[
                if (top != null)
                  _TapToView(
                    badges: [top],
                    index: 0,
                    earned: {top},
                    child: BadgeImage(top, size: 72),
                  )
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
                      ?_nextHint(l10n, next),
                    ],
                  ),
                ),
              ],
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
                    _TapToView(
                      badges: AppBadge.values,
                      index: badge.index,
                      earned: earned,
                      child: BadgeImage(
                        badge,
                        size: 84,
                        earned: earned.contains(badge),
                      ),
                    ),
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

/// Earned badges in one row, best in front at the left, each covering half
/// of the next one (closer together when they don't fit). Sliding a finger
/// along the row lifts the badge under it, like a dock.
class _BadgeStack extends StatefulWidget {
  const _BadgeStack({required this.badges});

  /// Best first.
  final List<AppBadge> badges;

  @override
  State<_BadgeStack> createState() => _BadgeStackState();
}

class _BadgeStackState extends State<_BadgeStack> {
  static const double _size = 56;

  /// Slow enough to feel like the badge floats up.
  static const Duration _liftDuration = Duration(milliseconds: 700);

  /// The badge under the finger while sliding.
  int? _active;

  void _track(double dx, double step, double width) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final fromStart = rtl ? width - dx : dx;
    final i = ((fromStart - _size / 2) / step).round().clamp(
      0,
      widget.badges.length - 1,
    );
    if (i != _active) {
      HapticFeedback.selectionClick();
      setState(() => _active = i);
    }
  }

  void _release() => setState(() => _active = null);

  @override
  Widget build(BuildContext context) {
    final badges = widget.badges;
    final n = badges.length;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _liftDuration;
    final active = _active;
    return LayoutBuilder(
      builder: (context, constraints) {
        final step = n < 2
            ? _size / 2
            : math.min(_size / 2, (constraints.maxWidth - _size) / (n - 1));
        final width = _size + (n - 1) * step;
        // Worst painted first so the best is on top; a lifted badge on top
        // of all.
        final order = [
          for (var i = n - 1; i >= 0; i--)
            if (i != active) i,
          ?active,
        ];
        return GestureDetector(
          onHorizontalDragStart: (d) => _track(d.localPosition.dx, step, width),
          onHorizontalDragUpdate: (d) =>
              _track(d.localPosition.dx, step, width),
          onHorizontalDragEnd: (_) => _release(),
          onHorizontalDragCancel: _release,
          child: SizedBox(
            width: width,
            height: _size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final i in order)
                  PositionedDirectional(
                    // Keyed: the lifted badge moves to the end to paint on
                    // top, and each badge must keep its own animation.
                    key: ValueKey(badges[i]),
                    start: i * step,
                    child: _lifted(badges, i, active, duration),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Badge [i], bigger and higher the closer it is to the finger.
  Widget _lifted(List<AppBadge> badges, int i, int? active, Duration duration) {
    final distance = active == null ? 99 : (i - active).abs();
    final (scale, lift) = switch (distance) {
      0 => (1.4, -0.45),
      1 => (1.12, -0.12),
      _ => (1.0, 0.0),
    };
    return AnimatedSlide(
      offset: Offset(0, lift),
      duration: duration,
      curve: Curves.easeInOutCubic,
      child: AnimatedScale(
        scale: scale,
        alignment: Alignment.bottomCenter,
        duration: duration,
        curve: Curves.easeInOutCubic,
        child: _TapToView(
          badges: badges,
          index: i,
          earned: badges.toSet(),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 6)],
            ),
            child: BadgeImage(badges[i], size: _size),
          ),
        ),
      ),
    );
  }
}

/// Opens [badges] full size at [index] when tapped; swipe for the others.
class _TapToView extends StatelessWidget {
  const _TapToView({
    required this.badges,
    required this.index,
    required this.earned,
    required this.child,
  });

  final List<AppBadge> badges;
  final int index;
  final Set<AppBadge> earned;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => showBadgeViewer(context, badges, index, earned),
    child: child,
  );
}
