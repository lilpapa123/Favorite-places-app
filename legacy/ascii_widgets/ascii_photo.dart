import 'dart:io';

import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Every photo goes through the theme's treatment: desaturated, high contrast
/// and tinted with the accent, wrapped in a square frame with a caption plate.
class AsciiPhoto extends StatelessWidget {
  const AsciiPhoto({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.caption,
  });

  /// luminance × contrast(1.6) × brightness(1.1), multiplied by the accent —
  /// the Flutter equivalent of grayscale + a color-blend overlay.
  static const List<double> _tintMatrix = <double>[
    0.263, 0.517, 0.100, 0, -42.1, //
    0.463, 0.909, 0.177, 0, -74.1, //
    0.218, 0.429, 0.083, 0, -34.9, //
    0, 0, 0, 1, 0, //
  ];

  final File image;
  final BoxFit fit;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(_tintMatrix),
          child: Image.file(
            image,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: AsciiPalette.surfaceRaised,
              child: Center(child: Text('// image unavailable')),
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AsciiPalette.accent.withValues(alpha: 0.20),
                  AsciiPalette.accentSoft.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
        ),
        if (caption != null)
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              color: AsciiPalette.canvas.withValues(alpha: 0.88),
              padding: const EdgeInsets.symmetric(
                horizontal: AsciiSpace.sm,
                vertical: AsciiSpace.xs,
              ),
              child: Text(
                caption!,
                style: AsciiType.meta(color: AsciiPalette.accent),
              ),
            ),
          ),
      ],
    );
  }
}
