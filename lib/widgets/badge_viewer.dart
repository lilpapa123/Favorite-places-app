import 'dart:math' as math;

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/badges.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/badge_widgets.dart';
import 'package:flutter/material.dart';

/// All of [badges] in a 3D cover flow, starting at [initial]: the middle one
/// faces you, the ones beside it turn away. Tap the middle badge to flip it
/// over for its details; [earned] decides "Earned" vs how to earn it.
Future<void> showBadgeViewer(
  BuildContext context,
  List<AppBadge> badges,
  int initial,
  Set<AppBadge> earned,
) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0xFA0B0C10),
    transitionDuration: reduceMotion ? Duration.zero : AppMotion.medium,
    transitionBuilder: (ctx, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    pageBuilder: (ctx, _, _) => Material(
      type: MaterialType.transparency,
      child: _Viewer(badges: badges, initial: initial, earned: earned),
    ),
  );
}

class _Viewer extends StatefulWidget {
  const _Viewer({
    required this.badges,
    required this.initial,
    required this.earned,
  });

  final List<AppBadge> badges;
  final int initial;
  final Set<AppBadge> earned;

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  static const double _size = 210;

  late int _page = widget.initial;
  late final PageController _controller = PageController(
    initialPage: _page,
    viewportFraction: 0.55,
  );

  /// The middle badge shows its back.
  bool _flipped = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tap(int i) {
    if (i == _page) {
      setState(() => _flipped = !_flipped);
    } else {
      _controller.animateToPage(
        i,
        duration: AppMotion.medium,
        curve: AppMotion.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final badges = widget.badges;
    final b = badges[_page];
    final got = widget.earned.contains(b);
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 280,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: badges.length,
                    onPageChanged: (i) => setState(() {
                      _page = i;
                      _flipped = false;
                    }),
                    itemBuilder: (context, i) => AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final c = _controller;
                        final page = c.hasClients && c.position.haveDimensions
                            ? c.page ?? _page.toDouble()
                            : _page.toDouble();
                        final d = (i - page).clamp(-1.5, 1.5);
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0015) // perspective
                            ..rotateY(-d * 0.9)
                            ..scaleByDouble(
                              1 - d.abs() * 0.18,
                              1 - d.abs() * 0.18,
                              1,
                              1,
                            ),
                          child: Opacity(
                            opacity: (1 - d.abs() * 0.35).clamp(0.3, 1.0),
                            child: child,
                          ),
                        );
                      },
                      // Screen readers hear the badge's name; a tap flips it.
                      child: Semantics(
                        button: true,
                        label: badges[i].title(l10n),
                        child: GestureDetector(
                          onTap: () => _tap(i),
                          child: Center(
                            child: _FlipBadge(
                              badge: badges[i],
                              earned: widget.earned.contains(badges[i]),
                              flipped: i == _page && _flipped,
                              size: _size,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                // The name under the badge; hidden while its back shows it.
                AnimatedOpacity(
                  opacity: _flipped ? 0 : 1,
                  duration: AppMotion.fast,
                  child: Column(
                    children: [
                      Text(
                        b.title(l10n),
                        style: AppText.heading(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        got ? l10n.badgeEarned : b.howTo(l10n),
                        textAlign: TextAlign.center,
                        style: AppText.body(
                          color: got ? AppColors.accent : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  '${_page + 1} / ${badges.length}',
                  style: AppText.meta(color: Colors.white70),
                ),
              ],
            ),
          ),
          Positioned(
            top: AppSpace.sm,
            right: AppSpace.sm,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// A badge that turns over (around its vertical middle) to show its back.
class _FlipBadge extends StatelessWidget {
  const _FlipBadge({
    required this.badge,
    required this.earned,
    required this.flipped,
    required this.size,
  });

  final AppBadge badge;
  final bool earned;
  final bool flipped;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: flipped ? math.pi : 0),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      builder: (context, angle, _) {
        final showBack = angle > math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: showBack
              // Turned the right way round, so the text isn't mirrored.
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: _BadgeBack(badge: badge, earned: earned, size: size),
                )
              : BadgeImage(badge, size: size, earned: earned),
        );
      },
    );
  }
}

/// The back of a badge: its own artwork darkened, keeping its exact shape,
/// with the name, how to earn it and whether it is earned written inside.
class _BadgeBack extends StatelessWidget {
  const _BadgeBack({
    required this.badge,
    required this.earned,
    required this.size,
  });

  final AppBadge badge;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // srcATop darkens only where the badge is drawn, so the transparent
          // edges, and with them the shape, stay.
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xA6000000),
              BlendMode.srcATop,
            ),
            child: BadgeImage(badge, size: size),
          ),
          // Kept to the middle so it fits even the narrow diamond shapes.
          SizedBox(
            width: size * 0.62,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  earned ? Icons.verified_rounded : Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(height: 6),
                Text(
                  badge.title(l10n),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppText.bodyStrong(color: Colors.white)
                      .copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.howTo(l10n),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.meta(
                    color: Colors.white.withValues(alpha: 0.85),
                  ).copyWith(fontSize: 11, height: 1.3),
                ),
                if (earned) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.badgeEarned,
                    style: AppText.label(color: Colors.white)
                        .copyWith(fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
