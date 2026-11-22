import 'dart:io';

import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A place's photo, or a soft tinted placeholder when it has none.
///
/// [photo] is a file on this phone or an uploaded photo's URL. The image is
/// decoded at the size it's shown ([cacheWidth]), not at the camera's full
/// resolution, which keeps scrolling smooth.
class PlacePhoto extends StatelessWidget {
  const PlacePhoto({
    super.key,
    required this.photo,
    required this.tint,
    this.iconSize = 32,
  });

  final String? photo;
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

    final source = photo;
    if (source == null) {
      return placeholder;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth * dpr).round()
            : null;
        Widget onError(BuildContext context, Object error, StackTrace? st) =>
            placeholder;
        return isUploadedPhoto(source)
            ? Image.network(
                source,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: width,
                errorBuilder: onError,
                frameBuilder: (context, child, frame, sync) =>
                    frame == null && !sync ? ColoredBox(color: tint) : child,
              )
            : Image.file(
                File(source),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: width,
                errorBuilder: onError,
              );
      },
    );
  }
}

/// All of a place's photos, swiped left and right, with dots when there is
/// more than one.
class PlacePhotos extends StatefulWidget {
  const PlacePhotos({
    super.key,
    required this.photos,
    required this.tint,
    this.iconSize = 32,
  });

  final List<String> photos;
  final Color tint;
  final double iconSize;

  @override
  State<PlacePhotos> createState() => _PlacePhotosState();
}

class _PlacePhotosState extends State<PlacePhotos> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    if (photos.length < 2) {
      return PlacePhoto(
        photo: photos.firstOrNull,
        tint: widget.tint,
        iconSize: widget.iconSize,
      );
    }
    final page = _page.clamp(0, photos.length - 1);
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: photos.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) =>
              PlacePhoto(photo: photos[i], tint: widget.tint),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpace.sm,
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < photos.length; i++)
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == page ? 8 : 6,
                    height: i == page ? 8 : 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: i == page ? 1 : 0.55,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x40000000), blurRadius: 3),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
