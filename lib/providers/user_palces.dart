import 'dart:io';

import 'package:favorite_places/models/place.dart';
import 'package:flutter_riverpod/legacy.dart';

class UserPlacesNofitier extends StateNotifier<List<Place>> {
  UserPlacesNofitier() : super(const []);

  void addPlace(
    String title, {
    PlaceCategory category = PlaceCategory.cafe,
    String note = '',
    File? image,
    PlaceLocation? location,
  }) {
    final newPlace = Place(
      title: title,
      category: category,
      note: note,
      image: image,
      location: location,
    );
    state = [newPlace, ...state];
  }

  /// Replaces the place with the same id (after editing it).
  void updatePlace(Place place) {
    state = [
      for (final p in state)
        if (p.id == place.id) place else p,
    ];
  }

  /// Removes [place] and returns where it was, so it can be put back.
  int removePlace(Place place) {
    final index = state.indexWhere((p) => p.id == place.id);
    if (index == -1) {
      return -1;
    }
    state = [...state]..removeAt(index);
    return index;
  }

  /// Undo for [removePlace].
  void restorePlace(Place place, int index) {
    if (state.any((p) => p.id == place.id)) {
      return;
    }
    final next = [...state];
    next.insert(index.clamp(0, next.length), place);
    state = next;
  }
}

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNofitier, List<Place>>(
      (ref) => UserPlacesNofitier(),
    );
