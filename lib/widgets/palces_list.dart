import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/screens/places_detail.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/place_card.dart';
import 'package:flutter/material.dart';

/// The feed of saved places, as cards.
class PalcesList extends StatelessWidget {
  const PalcesList({super.key, required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpace.page,
        0,
        AppSpace.page,
        bottomBarClearance(context),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: places.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpace.lg),
      itemBuilder: (context, index) {
        final place = places[index];
        return PlaceCard(
          key: ValueKey(place.id),
          place: place,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (ctx) => PlacesDetailScreen(placeId: place.id),
              ),
            );
          },
        );
      },
    );
  }
}
