import 'package:favorite_places/screens/add_place.dart';
import 'package:favorite_places/widgets/palces_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_palces.dart';

class PalcesScreen extends ConsumerWidget {
  const PalcesScreen({super.key});

  Widget build(BuildContext context, WidgetRef ref) {
    final userPlaces = ref.watch(userPlacesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Places'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const AddedPlaceScreen()),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: PalcesList(places: userPlaces),
    );
  }
}
