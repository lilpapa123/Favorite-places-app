import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A square-cornered 1px frame with an optional legend breaking the top rule —
/// the "fieldset" look that carries most of the theme's structure.
class AsciiPanel extends StatelessWidget {
  const AsciiPanel({
    super.key,
    required this.child,
    this.label,
    this.padding = const EdgeInsets.all(AsciiSpace.lg),
    this.background = AsciiPalette.surface,
    this.borderColor = AsciiPalette.line,
    this.labelColor = AsciiPalette.mute,
  });

  static const double _legendOverlap = 7;

  final Widget child;
  final String? label;
  final EdgeInsets padding;
  final Color background;
  final Color borderColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: background,
            border: Border.all(
              color: borderColor,
              width: AsciiShape.borderWidth,
            ),
          ),
          child: child,
        ),
        if (label != null)
          Positioned(
            left: AsciiSpace.md,
            top: -_legendOverlap,
            child: Container(
              color: AsciiPalette.canvas,
              padding: const EdgeInsets.symmetric(horizontal: AsciiSpace.xs),
              child: Text(label!, style: AsciiType.label(color: labelColor)),
            ),
          ),
      ],
    );
  }
}
