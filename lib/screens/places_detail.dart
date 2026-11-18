import 'package:favorite_places/models/place.dart';
import 'package:flutter/material.dart';

class PlacesDetailScreen extends StatelessWidget {
  const PlacesDetailScreen({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final image = place.image;

    return Scaffold(
      appBar: AppBar(title: Text(place.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image != null)
              Image.file(
                image,
                fit: BoxFit.cover,
                height: 240,
                errorBuilder: (context, error, stackTrace) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'Image could not be loaded.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Details for ${place.title}',
                style: Theme.of(context).textTheme.titleMedium!
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
