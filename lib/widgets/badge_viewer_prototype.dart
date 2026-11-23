// PROTOTYPE, throw away: three ways to go through badges one by one after
// tapping one: stories, 3D cover flow, and flip cards. Switched with the
// yellow pill at the top of the viewer (debug and profile builds only).
//
// "Tapping a badge opens all of that person's earned badges at the tapped
// one. Three layouts to compare."

import 'dart:async';
import 'dart:math' as math;

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/badges.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/badge_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final badgeViewerLayout = ValueNotifier<int>(0);

const badgeViewerNames = [
  'A · Stories',
  'B · 3D cover flow',
  'C · Flip for details',
];

/// Opens [badges] at [initial]; [earned] decides "Earned" vs how to earn.
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
  late int _page = widget.initial;
  late PageController _controller = _makeController();

  PageController _makeController() => PageController(
    initialPage: _page,
    viewportFraction: badgeViewerLayout.value == 1 ? 0.55 : 1,
  );

  void _onLayout() => setState(() {
    _controller.dispose();
    _controller = _makeController();
  });

  @override
  void initState() {
    super.initState();
    badgeViewerLayout.addListener(_onLayout);
  }

  @override
  void dispose() {
    badgeViewerLayout.removeListener(_onLayout);
    _controller.dispose();
    super.dispose();
  }

  void _setPage(int i) => setState(() => _page = i);

  void _close() => Navigator.of(context).pop();

  void _goTo(int i) {
    if (i < 0 || i >= widget.badges.length) {
      return;
    }
    if (badgeViewerLayout.value == 0) {
      setState(() => _page = i); // stories jump, no slide
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
    final body = switch (badgeViewerLayout.value) {
      1 => _CoverFlow(state: this),
      2 => _Flip(state: this),
      _ => _Stories(state: this),
    };
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned(
            top: badgeViewerLayout.value == 0 ? 20 : AppSpace.sm,
            right: AppSpace.sm,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: _close,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          if (!kReleaseMode)
            Positioned(
              bottom: AppSpace.lg,
              left: 0,
              right: 0,
              child: Center(child: _Switcher()),
            ),
        ],
      ),
    );
  }
}

/// Name and "Earned" (or how to earn it) under a badge.
Widget _texts(BuildContext context, AppBadge b, bool got) {
  final l10n = context.l10n;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        b.title(l10n),
        textAlign: TextAlign.center,
        style: AppText.heading(color: Colors.white),
      ),
      const SizedBox(height: AppSpace.sm),
      Text(
        got ? l10n.badgeEarned : b.howTo(l10n),
        textAlign: TextAlign.center,
        style: AppText.body(color: got ? AppColors.accent : Colors.white70),
      ),
    ],
  );
}

// --- A: Stories ------------------------------------------------------------
// Bars at the top fill one by one; tap the right side for the next badge,
// the left side for the previous one. Moves on by itself every 4 seconds.

class _Stories extends StatefulWidget {
  const _Stories({required this.state});
  final _ViewerState state;

  @override
  State<_Stories> createState() => _StoriesState();
}

class _StoriesState extends State<_Stories>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..addStatusListener(_onTimer);
  int? _shown;

  void _onTimer(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final s = widget.state;
    if (s._page < s.widget.badges.length - 1) {
      s._goTo(s._page + 1);
    } else {
      s._close();
    }
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final badges = s.widget.badges;
    final page = s._page;
    if (_shown != page) {
      _shown = page;
      // Reduce Motion: no auto-advance, the bar shows as full.
      if (MediaQuery.disableAnimationsOf(context)) {
        _timer.value = 1;
      } else {
        unawaited(_timer.forward(from: 0));
      }
    }
    final b = badges[page];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) {
        final width = context.size?.width ?? 1;
        s._goTo(d.localPosition.dx > width / 3 ? page + 1 : page - 1);
      },
      onLongPressStart: (_) => _timer.stop(),
      onLongPressEnd: (_) => _timer.forward(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, 56, 0),
            child: Row(
              children: [
                for (var i = 0; i < badges.length; i++)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AnimatedBuilder(
                          animation: _timer,
                          builder: (context, _) => FractionallySizedBox(
                            widthFactor: i < page
                                ? 1
                                : i == page
                                ? _timer.value
                                : 0,
                            child: const ColoredBox(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BadgeImage(b, size: 240, earned: s.widget.earned.contains(b)),
                  const SizedBox(height: AppSpace.xl),
                  _texts(context, b, s.widget.earned.contains(b)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// --- B: 3D cover flow -----------------------------------------------------
// The middle badge faces you; the ones beside it turn away in 3D.

class _CoverFlow extends StatelessWidget {
  const _CoverFlow({required this.state});
  final _ViewerState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final badges = s.widget.badges;
    final b = badges[s._page];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: s._controller,
            itemCount: badges.length,
            onPageChanged: s._setPage,
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: s._controller,
              builder: (context, child) {
                final c = s._controller;
                final page = c.hasClients && c.position.haveDimensions
                    ? c.page ?? s._page.toDouble()
                    : s._page.toDouble();
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
              child: GestureDetector(
                onTap: () => i == s._page ? s._close() : s._goTo(i),
                child: Center(
                  child: BadgeImage(
                    badges[i],
                    size: 210,
                    earned: s.widget.earned.contains(badges[i]),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        _texts(context, b, s.widget.earned.contains(b)),
        const SizedBox(height: AppSpace.lg),
        Text(
          '${s._page + 1} / ${badges.length}',
          style: AppText.meta(color: Colors.white70),
        ),
      ],
    );
  }
}

// --- C: Flip for details ---------------------------------------------------
// One badge per page. Tap it to flip it over: the back says what it is for
// and whether it is earned.

class _Flip extends StatelessWidget {
  const _Flip({required this.state});
  final _ViewerState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final badges = s.widget.badges;
    return PageView.builder(
      controller: s._controller,
      itemCount: badges.length,
      onPageChanged: s._setPage,
      itemBuilder: (context, i) => Center(
        child: _FlipCard(
          badge: badges[i],
          earned: s.widget.earned.contains(badges[i]),
          position: '${i + 1} / ${badges.length}',
        ),
      ),
    );
  }
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({
    required this.badge,
    required this.earned,
    required this.position,
  });

  final AppBadge badge;
  final bool earned;
  final String position;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> {
  bool _back = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final b = widget.badge;
    final card = BoxDecoration(
      color: const Color(0xFF1C1E25),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white12),
    );
    final front = Container(
      decoration: card,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BadgeImage(b, size: 190, earned: widget.earned),
          const SizedBox(height: AppSpace.lg),
          Text(b.title(l10n), style: AppText.heading(color: Colors.white)),
          const SizedBox(height: AppSpace.xs),
          Text(widget.position, style: AppText.meta(color: Colors.white54)),
        ],
      ),
    );
    final back = Container(
      decoration: card.copyWith(color: AppColors.accent),
      padding: const EdgeInsets.all(AppSpace.xl),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.earned ? Icons.verified : Icons.lock_outline,
            color: Colors.white,
            size: 44,
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            b.title(l10n),
            textAlign: TextAlign.center,
            style: AppText.heading(color: Colors.white),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            b.howTo(l10n),
            textAlign: TextAlign.center,
            style: AppText.body(color: Colors.white),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            widget.earned ? l10n.badgeEarned : '—',
            style: AppText.bodyStrong(color: Colors.white),
          ),
        ],
      ),
    );
    return GestureDetector(
      onTap: () => setState(() => _back = !_back),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _back ? math.pi : 0),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        builder: (context, angle, _) {
          final showBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: SizedBox(
              width: 280,
              height: 380,
              child: showBack
                  // Turn the back the right way round.
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: back,
                    )
                  : front,
            ),
          );
        },
      ),
    );
  }
}

/// Yellow-edged pill with ‹ name ›; not part of the designs.
class _Switcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    void step(int by) => badgeViewerLayout.value =
        (badgeViewerLayout.value + by) % badgeViewerNames.length;
    final v = badgeViewerLayout.value;
    return Material(
      color: const Color(0xEE111111),
      shape: const StadiumBorder(
        side: BorderSide(color: Color(0xFFFFD54F), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => step(-1),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Text(
            '${v + 1}/${badgeViewerNames.length}  ${badgeViewerNames[v]}',
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          IconButton(
            onPressed: () => step(1),
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
