import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

/// Where place photos are shared from, so other people can see them.
abstract interface class PlacePhotoStore {
  /// Uploads the file at [path] and returns where it is shared from.
  Future<String> upload(String uid, String placeId, String path);

  Future<void> delete(String url);
}

/// Shared photos are kept in Firestore, one document each:
/// `photos/{id}` with `ownerUid`, `placeId` and the JPEG in `data`. A place
/// lists them as `firestore://photos/{id}`.
// shortcut: Firestore, as the project has no Firebase Storage (it needs the
// Blaze plan); move photos to Storage if quality or read costs matter.
class FirestorePlacePhotoStore implements PlacePhotoStore {
  FirestorePlacePhotoStore(this._db);

  final FirebaseFirestore _db;

  /// A Firestore document holds at most 1 MiB; leave room for the rest.
  static const maxBytes = 900 * 1024;

  @override
  Future<String> upload(String uid, String placeId, String path) async {
    var bytes = await File(path).readAsBytes();
    if (bytes.length > maxBytes) {
      bytes = await compute(shrinkPhoto, bytes);
    }
    final doc = _db.collection('photos').doc();
    await doc.set({'ownerUid': uid, 'placeId': placeId, 'data': Blob(bytes)});
    return '$firestorePhotoScheme${doc.path}';
  }

  @override
  Future<void> delete(String url) async {
    if (url.startsWith(firestorePhotoScheme)) {
      await _db.doc(url.substring(firestorePhotoScheme.length)).delete();
    }
  }
}

/// At most 1080 px wide, as a JPEG that fits [FirestorePlacePhotoStore.maxBytes].
@visibleForTesting
Uint8List shrinkPhoto(Uint8List bytes) {
  var image = img.decodeImage(bytes);
  if (image == null) {
    return bytes;
  }
  if (image.width > 1080) {
    image = img.copyResize(image, width: 1080);
  }
  for (final quality in [80, 65, 50, 35]) {
    final jpg = img.encodeJpg(image, quality: quality);
    if (jpg.length <= FirestorePlacePhotoStore.maxBytes) {
      return jpg;
    }
  }
  return img.encodeJpg(img.copyResize(image, width: 720), quality: 50);
}

/// A photo kept in Firestore, for [Image]; cached like any other image.
class FirestorePhotoImage extends ImageProvider<FirestorePhotoImage> {
  const FirestorePhotoImage(this.url);

  /// `firestore://photos/{id}`.
  final String url;

  @override
  Future<FirestorePhotoImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    FirestorePhotoImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final snap = await FirebaseFirestore.instance
        .doc(url.substring(firestorePhotoScheme.length))
        .get();
    final data = snap.data()?['data'];
    if (data is! Blob) {
      throw StateError('No photo at $url');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(data.bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is FirestorePhotoImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

/// Override in tests with a fake.
final placePhotoStoreProvider = Provider<PlacePhotoStore>(
  (ref) => FirestorePlacePhotoStore(ref.watch(firestoreProvider)),
);
