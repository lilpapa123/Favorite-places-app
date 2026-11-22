import 'dart:io';

import 'package:favorite_places/models/place.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where place photos are shared from, so other people can see them.
abstract interface class PlacePhotoStore {
  /// Uploads the file at [path] and returns its download URL.
  Future<String> upload(String uid, String placeId, String path);

  Future<void> delete(String url);
}

/// Photos live at `places/{uid}/{placeId}/{random}.jpg` (see storage.rules).
class FirebasePlacePhotoStore implements PlacePhotoStore {
  FirebasePlacePhotoStore(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<String> upload(String uid, String placeId, String path) async {
    final png = path.toLowerCase().endsWith('.png');
    final ref = _storage.ref(
      'places/$uid/$placeId/${uuid.v4()}.${png ? 'png' : 'jpg'}',
    );
    await ref.putFile(
      File(path),
      SettableMetadata(contentType: png ? 'image/png' : 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  @override
  Future<void> delete(String url) => _storage.refFromURL(url).delete();
}

/// Override in tests with a fake.
final placePhotoStoreProvider = Provider<PlacePhotoStore>(
  (ref) => FirebasePlacePhotoStore(FirebaseStorage.instance),
);
