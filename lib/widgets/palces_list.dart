import 'package:favorite_places/models/place.dart';
import 'package:flutter/material.dart';

class PalcesList extends StatelessWidget {
  const PalcesList({super.key, required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const Center(child: Text("No Places added yet."));
    }

    return ListView.builder(
      itemCount: places.length,
      itemBuilder: ((context, index) => ListTile(
        title: Text(
          places[index].title,
          style: Theme.of(context).textTheme.titleMedium!
              .copyWith(color: Theme.of(context).colorScheme.onBackground),
        ),
      )),
    );
  }
}
