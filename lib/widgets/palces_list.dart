import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/screens/places_detail.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/empty_places.dart';
import 'package:favorite_places/widgets/place_card.dart';
import 'package:flutter/material.dart';

/// The feed of saved places.
class PalcesList extends StatelessWidget {
  const PalcesList({super.key, required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const EmptyPlaces();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AsciiSpace.lg,
        AsciiSpace.md,
        AsciiSpace.lg,
        AsciiSpace.xl,
      ),
      itemCount: places.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AsciiSpace.sm),
      itemBuilder: (context, index) {
        final place = places[index];
        return PlaceCard(
          place: place,
          index: index,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (ctx) => PlacesDetailScreen(place: place),
              ),
            );
          },
        );
      },
    );
  }
}
