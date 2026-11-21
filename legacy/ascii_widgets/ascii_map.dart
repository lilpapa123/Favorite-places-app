import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Shared OpenStreetMap pieces, dressed in the ASCII theme.
class AsciiMap {
  const AsciiMap._();

  /// Turns light OSM tiles into the theme's dark green: luminance is inverted
  /// and mapped from [AsciiPalette.canvas] (land) up to [AsciiPalette.mute]
  /// (roads and labels).
  static const List<double> _tileMatrix = <double>[
    -0.0942, -0.3168, -0.0320, 0, 126, //
    -0.1184, -0.3984, -0.0402, 0, 157, //
    -0.0893, -0.3004, -0.0303, 0, 119, //
    0, 0, 0, 1, 0, //
  ];

  /// OSM's tile policy requires a real user agent package name.
  static TileLayer tiles() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.favorite_places',
      tileBuilder: (context, tileWidget, tile) => ColorFiltered(
        colorFilter: const ColorFilter.matrix(_tileMatrix),
        child: tileWidget,
      ),
    );
  }

  /// OSM data is ODbL-licensed: the credit must stay visible on every map.
  static Widget attribution() {
    return SimpleAttributionWidget(
      backgroundColor: AsciiPalette.canvas.withValues(alpha: 0.88),
      source: Text(
        'OpenStreetMap contributors',
        style: AsciiType.meta(color: AsciiPalette.mute),
      ),
    );
  }
}

/// A square map pin: `[01]` in a framed block, accent when selected.
class AsciiMapPin extends StatelessWidget {
  const AsciiMapPin({super.key, this.label, this.onTap});

  static const double width = 44;
  static const double height = 26;

  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AsciiPalette.accent,
          border: Border.all(
            color: AsciiPalette.accentInk,
            width: AsciiShape.borderWidth,
          ),
        ),
        child: label == null
            ? const Icon(Icons.place, size: 16, color: AsciiPalette.accentInk)
            : Text(
                label!,
                style: AsciiType.meta(color: AsciiPalette.accentInk),
              ),
      ),
    );
  }
}
