import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The design's "Golden hour" look for Account, its menu, Sign in and Edit
/// profile: a sun glow in the top-right corner over a peach-to-cream wash.
class GoldenHour extends StatelessWidget {
  const GoldenHour({super.key, required this.child});

  final Widget child;

  /// A frosted card over the wash, as the design's profile and menu cards.
  static BoxDecoration card({double radius = 22}) => BoxDecoration(
    color: AppColors.surface.withValues(alpha: .82),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: Colors.white.withValues(alpha: AppColors.isDark ? .08 : .8),
    ),
    boxShadow: AppColors.isDark
        ? null
        : const [
            BoxShadow(
              color: Color(0x33B98E7A),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.3,
          colors: [AppColors.accentSoft, AppColors.background],
          stops: const [0, .6],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -60,
            width: 240,
            height: 240,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF6CB74)
                          .withValues(alpha: AppColors.isDark ? .16 : .55),
                      const Color(0x00FBE6C2),
                    ],
                    stops: const [0, .7],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
