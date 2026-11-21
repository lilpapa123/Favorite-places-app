import 'dart:io';

import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A place's photo, or a soft tinted placeholder when it has none.
///
/// The image is decoded at the size it's shown ([cacheWidth]), not at the
/// camera's full resolution, which keeps scrolling smooth.
class PlacePhoto extends StatelessWidget {
  const PlacePhoto({
    super.key,
    required this.image,
    required this.tint,
    this.iconSize = 32,
  });

  final File? image;
  final Color tint;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: tint,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: iconSize,
          color: AppColors.label,
        ),
      ),
    );

    final file = image;
    if (file == null) {
      return placeholder;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth * dpr).round()
            : null;
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: width,
          errorBuilder: (context, error, stackTrace) => placeholder,
        );
      },
    );
  }
}
