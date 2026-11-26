import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/screens/places_detail.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/place_photo.dart';
import 'package:flutter/material.dart';

/// The user's own places as a 3-column photo grid (Account tab). A tile
/// opens the place; a stack icon marks places with several photos.
class PlacesGrid extends StatelessWidget {
  const PlacesGrid({super.key, required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: places.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, i) {
        final place = places[i];
        return Semantics(
          button: true,
          label: place.title,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (ctx) => PlacesDetailScreen(placeId: place.id),
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A15171C),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlacePhoto(
                      photo: place.photos.firstOrNull,
                      tint: AppColors.tintFor(place.id),
                      iconSize: 22,
                    ),
                    if (place.photos.length > 1)
                      const Positioned(
                        right: 6,
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
          ),
        );
      },
    );
  }
}
