import 'dart:ui';

import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:flutter/material.dart';

class GlassTab {
  const GlassTab({required this.label, required this.icon});

  /// Read out by screen readers (the bar itself shows icons only).
  final String label;

  /// Name of the design icon in assets/icons.
  final String icon;
}

/// Floating "liquid glass" tab bar from the design: a frosted white capsule
/// with icon-only tabs, a soft pink pill behind the selected one, and a
/// camera in the middle that opens the camera straight away.
///
/// [tabs] are split around the camera: the first half on its left, the rest
/// on its right.
///
/// Flutter can't use Apple's real Liquid Glass material, so this recreates
/// the look with a background blur, a milky translucent fill and a bright rim.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onSelect,
    required this.onCamera,
    this.cameraBusy = false,
  });

  final List<GlassTab> tabs;

  /// Selected tab, or -1 when none is (e.g. while the add form is open).
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCamera;
  final bool cameraBusy;

  static const double _barHeight = 68;
  static const double _bottomGap = AppSpace.md;

  /// Space the bar takes above the safe area, for pages that pad around it.
  static const double height = _barHeight + _bottomGap;

  @override
  Widget build(BuildContext context) {
    final leftCount = (tabs.length + 1) ~/ 2;
    final radius = BorderRadius.circular(_barHeight / 2);

    Widget tabAt(int i) => Expanded(
      child: _TabButton(
        tab: tabs[i],
        selected: i == currentIndex,
        onTap: () => onSelect(i),
      ),
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: _bottomGap),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: const [
              BoxShadow(
                color: Color(0x241F2633),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: _barHeight,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                  // White 78% glass, brighter toward the bottom edge.
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.79),
                      Colors.white.withValues(alpha: 0.79),
                      Colors.white.withValues(alpha: 0.92),
                    ],
                    stops: const [0, 0.35, 1],
                  ),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < leftCount; i++) tabAt(i),
                    Expanded(
                      child: _CameraButton(
                        busy: cameraBusy,
                        onTap: onCamera,
                      ),
                    ),
                    for (var i = leftCount; i < tabs.length; i++) tabAt(i),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraButton extends StatefulWidget {
  const _CameraButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  State<_CameraButton> createState() => _CameraButtonState();
}

class _CameraButtonState extends State<_CameraButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Take a photo of a place',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.busy ? null : widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Center(
          child: AnimatedScale(
            duration: AppMotion.fast,
            curve: AppMotion.ease,
            scale: _pressed ? 0.88 : 1,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: widget.busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.accent,
                        ),
                      )
                    // Soft terracotta glow under the camera, as in the design.
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const AppIcon('tab_camera'),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final GlassTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.ease,
            width: double.infinity,
            height: 54,
            constraints: const BoxConstraints(maxWidth: 82),
            decoration: BoxDecoration(
              color: selected ? AppColors.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(27),
            ),
            child: Center(
              child: AnimatedScale(
                duration: AppMotion.medium,
                curve: Curves.easeOutBack,
                scale: selected ? 1.06 : 1,
                child: AppIcon(
                  tab.icon,
                  color: selected ? AppColors.accent : const Color(0xFF757575),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
