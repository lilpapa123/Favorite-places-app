import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_places/data/sample_places.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/services/place_photo_store.dart';
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
///
/// Photos are saved as file paths first, then uploaded to [_store] in the
/// background and swapped for their URLs, so saving never waits on the
/// network.
class UserPlacesNofitier extends StateNotifier<List<Place>> {
  UserPlacesNofitier([
    super.initial = const [],
    this._db,
    this._uid,
    this._store,
  ]) {
    final db = _db;
    final uid = _uid;
    if (db != null && uid != null) {
      _sub = placesOf(db, uid).listen(
        (places) {
          state = places;
          // Photos left from an earlier run (e.g. saved offline).
          places.forEach(_uploadPhotos);
        },
        // Missing index or rules denial: keep what is on screen.
        onError: (Object error) => debugPrint('Places sync failed: $error'),
      );
    }
  }

  final FirebaseFirestore? _db;
  final String? _uid;
  final PlacePhotoStore? _store;
  StreamSubscription<List<Place>>? _sub;

  /// Files already tried this run, so a failing upload isn't retried on
  /// every snapshot.
  final Set<String> _attempted = {};
  final Set<String> _uploading = {};

  /// Photo deletions waiting out the undo window, by place id.
  final Map<String, Timer> _pendingDeletes = {};

  /// Writes go to Firestore; the local list updates at once and the snapshot
  /// stream then confirms it.
  void _save(Place place) {
    final db = _db;
    final uid = _uid;
    if (db != null && uid != null) {
      db.collection('places').doc(place.id).set(place.toFirestore(uid));
      _uploadPhotos(place);
    }
  }

  Future<void> _uploadPhotos(Place place) async {
    final db = _db;
    final uid = _uid;
    final store = _store;
    final todo = [
      for (final p in place.photos)
        if (!isUploadedPhoto(p) && !_attempted.contains(p)) p,
    ];
    if (db == null || uid == null || store == null || todo.isEmpty) {
      return;
    }
    if (!_uploading.add(place.id)) {
      return;
    }
    final uploaded = <String, String>{};
    try {
      for (final path in todo) {
        _attempted.add(path);
        try {
          uploaded[path] = await store.upload(uid, place.id, path);
        } catch (error) {
          debugPrint('Photo upload failed: $error');
        }
      }
      if (uploaded.isEmpty || !mounted) {
        return;
      }
      // Apply to the latest version: it may have been edited meanwhile.
      final current = state.where((p) => p.id == place.id).firstOrNull;
      final photos = [
        for (final p in current?.photos ?? const <String>[]) uploaded[p] ?? p,
      ];
      final kept = photos.toSet();
      for (final url in uploaded.values) {
        if (!kept.contains(url)) {
          _deleteQuietly(url);
        }
      }
      if (current == null || listEquals(photos, current.photos)) {
        return;
      }
      state = [
        for (final p in state)
          if (p.id == place.id) p.copyWith(photos: photos) else p,
      ];
      await db.collection('places').doc(place.id).update({'photos': photos});
    } catch (error) {
      debugPrint('Saving uploaded photos failed: $error');
    } finally {
      _uploading.remove(place.id);
    }
    // Photos added while this upload ran.
    if (mounted) {
      final latest = state.where((p) => p.id == place.id).firstOrNull;
      if (latest != null) {
        _uploadPhotos(latest);
      }
    }
  }

  void _deleteQuietly(String url) {
    _store
        ?.delete(url)
        .catchError(
          (Object error) => debugPrint('Photo delete failed: $error'),
        );
  }

  void addPlace(
    String title, {
    PlaceCategory category = PlaceCategory.cafe,
    String note = '',
    List<String> photos = const [],
    PlaceLocation? location,
  }) {
    final newPlace = Place(
      title: title,
      category: category,
      note: note,
      photos: photos,
      location: location,
    );
    state = [newPlace, ...state];
    _save(newPlace);
  }

  /// Replaces the place with the same id (after editing it).
  void updatePlace(Place place) {
    final old = state.where((p) => p.id == place.id).firstOrNull;
    for (final photo in old?.photos ?? const <String>[]) {
      if (isUploadedPhoto(photo) && !place.photos.contains(photo)) {
        _deleteQuietly(photo);
      }
    }
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
    // Kept a little longer than the undo snackbar shows.
    _pendingDeletes[place.id]?.cancel();
    _pendingDeletes[place.id] = Timer(const Duration(seconds: 10), () {
      _pendingDeletes.remove(place.id);
      place.photos.where(isUploadedPhoto).forEach(_deleteQuietly);
    });
    return index;
  }

  /// Undo for [removePlace].
  void restorePlace(Place place, int index) {
    if (state.any((p) => p.id == place.id)) {
      return;
    }
    _pendingDeletes.remove(place.id)?.cancel();
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
        return UserPlacesNofitier(
          const [],
          ref.watch(firestoreProvider),
          uid,
          ref.watch(placePhotoStoreProvider),
        );
      }
      // Signed out: debug and profile runs start with sample places; tests
      // and release start empty.
      return UserPlacesNofitier(
        !kReleaseMode && !Platform.environment.containsKey('FLUTTER_TEST')
            ? samplePlaces()
            : const [],
      );
    });
