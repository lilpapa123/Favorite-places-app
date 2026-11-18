import 'dart:io';

import 'package:favorite_places/models/place.dart';
import 'package:flutter_riverpod/legacy.dart';

class UserPlacesNofitier extends StateNotifier<List<Place>> {
  UserPlacesNofitier() : super(const []);

  void addPlace(String title, {File? image}) {
    final newPlace = Place(title: title, image: image);
    state = [newPlace, ...state];
  }
}

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNofitier, List<Place>>(
      (ref) => UserPlacesNofitier(),
    );
