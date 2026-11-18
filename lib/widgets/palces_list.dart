import 'dart:io';

import 'package:favorite_places/models/place.dart';
import 'package:flutter/material.dart';

import '../screens/places_detail.dart';

class PalcesList extends StatelessWidget {
  const PalcesList({super.key, required this.places});

  static const double _thumbnailSize = 56;

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const Center(child: Text("No Places added yet."));
    }

    return ListView.builder(
      itemCount: places.length,
      itemBuilder: ((context, index) {
        final place = places[index];
        return ListTile(
          leading: _PlaceThumbnail(image: place.image, size: _thumbnailSize),
          title: Text(
            place.title,
            style: Theme.of(context).textTheme.titleMedium!
                .copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => PlacesDetailScreen(place: place),
              ),
            );
          },
        );
      }),
    );
  }
}

class _PlaceThumbnail extends StatelessWidget {
  const _PlaceThumbnail({required this.image, required this.size});

  final File? image;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(image!, width: size, height: size, fit: BoxFit.cover),
    );
  }
}
