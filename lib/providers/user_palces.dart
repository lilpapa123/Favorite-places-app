import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_places/data/sample_places.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Override in tests with a fake.
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// The signed-in user's places. Signed in, they live in Firestore
/// (`places/{id}` with `ownerUid`) so followers can see them; signed out,
/// they stay in memory on this phone.
class UserPlacesNofitier extends StateNotifier<List<Place>> {
  UserPlacesNofitier([super.initial = const [], this._db, this._uid]) {
    final db = _db;
    final uid = _uid;
    if (db != null && uid != null) {
      _sub = placesOf(db, uid).listen(
        (places) => state = places,
        // Missing index or rules denial: keep what is on screen.
        onError: (Object error) => debugPrint('Places sync failed: $error'),
      );
    }
  }

  final FirebaseFirestore? _db;
  final String? _uid;
  StreamSubscription<List<Place>>? _sub;

  /// Writes go to Firestore; the local list updates at once and the snapshot
  /// stream then confirms it.
  void _save(Place place) {
    final db = _db;
    final uid = _uid;
    if (db != null && uid != null) {
      db.collection('places').doc(place.id).set(place.toFirestore(uid));
    }
  }

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
    _save(newPlace);
  }

  /// Replaces the place with the same id (after editing it).
  void updatePlace(Place place) {
    state = [
      for (final p in state)
        if (p.id == place.id) place else p,
    ];
    _save(place);
  }

  /// Removes [place] and returns where it was, so it can be put back.
  int removePlace(Place place) {
    final index = state.indexWhere((p) => p.id == place.id);
    if (index == -1) {
      return -1;
    }
    state = [...state]..removeAt(index);
    _db?.collection('places').doc(place.id).delete();
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
    _save(place);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Places saved by [uid], newest first. Needs the composite index in
/// `firestore.indexes.json` (ownerUid + createdAt).
Stream<List<Place>> placesOf(FirebaseFirestore db, String uid) => db
    .collection('places')
    .where('ownerUid', isEqualTo: uid)
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map(
      (snap) => [
        for (final doc in snap.docs) Place.fromFirestore(doc.id, doc.data()),
      ],
    );

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNofitier, List<Place>>((ref) {
      // Only the uid matters: name or photo changes must not reset the list.
      final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
      if (uid != null) {
        return UserPlacesNofitier(const [], ref.watch(firestoreProvider), uid);
      }
      // Signed out: debug and profile runs start with sample places; tests
      // and release start empty.
      return UserPlacesNofitier(
        !kReleaseMode && !Platform.environment.containsKey('FLUTTER_TEST')
            ? samplePlaces()
            : const [],
      );
    });
