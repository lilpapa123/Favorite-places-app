import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/ascii_photo.dart';
import 'package:favorite_places/widgets/ascii_placeholder.dart';
import 'package:flutter/material.dart';

/// One row of the feed: index, thumbnail, title, photo state, chevron.
class PlaceCard extends StatefulWidget {
  const PlaceCard({
    super.key,
    required this.place,
    required this.index,
    required this.onTap,
  });

  final Place place;
  final int index;
  final VoidCallback onTap;

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  static const double _thumbSize = 56;

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = widget.place.image != null;
    final String counter = (widget.index + 1).toString().padLeft(2, '0');

    return Semantics(
      button: true,
      label: widget.place.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration: AsciiMotion.fast,
          curve: AsciiMotion.ease,
          padding: const EdgeInsets.all(AsciiSpace.sm),
          decoration: BoxDecoration(
            color: _pressed ? AsciiPalette.surfaceRaised : AsciiPalette.surface,
            border: Border.all(
              color: _pressed ? AsciiPalette.accent : AsciiPalette.line,
              width: AsciiShape.borderWidth,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: _thumbSize,
                height: _thumbSize,
                child: hasPhoto
                    ? AsciiPhoto(image: widget.place.image!)
                    : const AsciiPlaceholder(),
              ),
              const SizedBox(width: AsciiSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.place.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AsciiType.title(),
                    ),
                    const SizedBox(height: AsciiSpace.xxs),
                    Text(
                      '$counter · ${hasPhoto ? 'photo' : 'no photo'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AsciiType.meta(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AsciiSpace.sm),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AsciiPalette.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
