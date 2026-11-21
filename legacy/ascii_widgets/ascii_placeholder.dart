import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The no-photo state: a gradient plate with a glyph, never a grey box.
class AsciiPlaceholder extends StatelessWidget {
  const AsciiPlaceholder({
    super.key,
    this.icon = Icons.photo_camera_back_outlined,
    this.iconSize = 20,
  });

  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AsciiPalette.surfaceRaised, AsciiPalette.canvas],
        ),
        border: Border.all(
          color: AsciiPalette.line,
          width: AsciiShape.borderWidth,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: AsciiPalette.accent.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
