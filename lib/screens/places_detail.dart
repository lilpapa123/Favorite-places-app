import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/ascii_label.dart';
import 'package:favorite_places/widgets/ascii_photo.dart';
import 'package:flutter/material.dart';

class PlacesDetailScreen extends StatelessWidget {
  const PlacesDetailScreen({super.key, required this.place});

  static const double _photoAspectRatio = 4 / 3;

  final Place place;

  String get _shortId =>
      place.id.length > 8 ? place.id.substring(0, 8) : place.id;

  @override
  Widget build(BuildContext context) {
    final image = place.image;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('>', style: AsciiType.heading(color: AsciiPalette.accent)),
            const SizedBox(width: AsciiSpace.sm),
            Flexible(
              child: Text(
                place.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AsciiType.heading(),
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(AsciiShape.borderWidth),
          child: Divider(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (image != null)
            AspectRatio(
              aspectRatio: _photoAspectRatio,
              child: AsciiPhoto(image: image, caption: '// captured'),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AsciiSpace.lg,
              AsciiSpace.xl,
              AsciiSpace.lg,
              AsciiSpace.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AsciiLabel('entry'),
                const SizedBox(height: AsciiSpace.sm),
                Text(place.title, style: AsciiType.display()),
                const SizedBox(height: AsciiSpace.xl),
                const Divider(),
                _MetaRow(label: 'id', value: _shortId),
                const Divider(),
                _MetaRow(
                  label: 'photo',
                  value: image != null ? 'attached' : 'none',
                  highlight: image != null,
                ),
                const Divider(),
                const _MetaRow(label: 'stored', value: 'this device'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AsciiSpace.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '// $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AsciiType.label(),
            ),
          ),
          const SizedBox(width: AsciiSpace.md),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AsciiType.meta(
                color: highlight ? AsciiPalette.accent : AsciiPalette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
