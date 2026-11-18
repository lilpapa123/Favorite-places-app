import 'package:favorite_places/models/place.dart';
import 'package:flutter_riverpod/legacy.dart';

class UserPlacesNofitier extends StateNotifier<List<Place>> {
  UserPlacesNofitier() : super(const []);

  void addPlace(String title) {
    final newPlace = Place(title: title);
    state = [newPlace, ...state];
  }
}

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNofitier, List<Place>>(
      (ref) => UserPlacesNofitier(),
    );
