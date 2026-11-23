import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/place_photo.dart';
import 'package:flutter/material.dart';

/// Someone's places in two staggered columns: photos of uneven height with
/// the city under each (the name is read out, not shown). A stack icon marks
/// places with several photos.
class PlacesTwoColumns extends StatelessWidget {
  const PlacesTwoColumns({super.key, required this.places});

  final List<Place> places;

  /// Photo width / height, repeated down each column so they stagger.
  static const List<double> _ratios = [0.8, 1.2, 1.0, 0.7];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final column in [0, 1]) ...[
          if (column == 1) const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              children: [
                // Left takes 1st, 3rd, 5th…; right takes 2nd, 4th…
                for (var i = column; i < places.length; i += 2)
                  _Tile(place: places[i], ratio: _ratios[i % _ratios.length]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.place, required this.ratio});

  final Place place;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final city = place.location?.city ?? '';
    return Semantics(
      label: city.isEmpty ? place.title : '${place.title}, $city',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: ratio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlacePhoto(
                      photo: place.photos.firstOrNull,
                      tint: AppColors.tintFor(place.id),
                      iconSize: 28,
                    ),
                    if (place.photos.length > 1)
                      const PositionedDirectional(
                        end: 6,
                        top: 6,
                        child: Icon(
                          Icons.collections_rounded,
                          size: 16,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Color(0x66000000), blurRadius: 3),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (city.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(city, style: AppText.meta().copyWith(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
