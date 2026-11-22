// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/services/place_photo_store.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Json = Map<String, dynamic>;

/// Uploads succeed with a URL made from the path, except paths in [failing].
class _Store implements PlacePhotoStore {
  final List<String> uploads = [];
  final List<String> deleted = [];
  final Set<String> failing = {};

  @override
  Future<String> upload(String uid, String placeId, String path) async {
    uploads.add(path);
    if (failing.contains(path)) {
      throw Exception('no bucket');
    }
    return 'https://photos.test/${path.split('/').last}';
  }

  @override
  Future<void> delete(String url) async => deleted.add(url);
}

/// Just enough Firestore for the notifier: writes are recorded, the places
/// query never emits.
class _Db extends Fake implements FirebaseFirestore {
  final Map<String, Json> docs = {};
  final List<Json> updates = [];

  @override
  CollectionReference<Json> collection(String path) => _Places(this);
}

class _Places extends Fake implements CollectionReference<Json> {
  _Places(this.db);

  final _Db db;

  @override
  Query<Json> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) => this;

  @override
  Query<Json> orderBy(Object field, {bool descending = false}) => this;

  @override
  Stream<QuerySnapshot<Json>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => const Stream.empty();

  @override
  DocumentReference<Json> doc([String? path]) => _Doc(db, path!);
}

class _Doc extends Fake implements DocumentReference<Json> {
  _Doc(this.db, this.id);

  final _Db db;

  @override
  final String id;

  @override
  Future<void> set(Json data, [SetOptions? options]) async => db.docs[id] = data;

  @override
  Future<void> update(Map<Object, Object?> data) async {
    db.updates.add(data.cast<String, dynamic>());
    db.docs[id]!.addAll(data.cast<String, dynamic>());
  }

  @override
  Future<void> delete() async => db.docs.remove(id);
}

void main() {
  group('Place.fromFirestore photos', () {
    test('keeps uploaded photos and files on this phone, in order', () {
      final file = File('${Directory.systemTemp.createTempSync().path}/a.jpg')
        ..writeAsBytesSync([0]);
      final place = Place.fromFirestore('p', {
        'photos': [
          'https://photos.test/1.jpg',
          '/not/on/this/phone.jpg',
          file.path,
        ],
      });
      expect(place.photos, ['https://photos.test/1.jpg', file.path]);
    });

    test('reads the old single photo field', () {
      final file = File('${Directory.systemTemp.createTempSync().path}/b.jpg')
        ..writeAsBytesSync([0]);
      expect(
        Place.fromFirestore('p', {'localImagePath': file.path}).photos,
        [file.path],
      );
    });
  });

  group('photo upload', () {
    late _Db db;
    late _Store store;
    late UserPlacesNofitier places;

    setUp(() {
      db = _Db();
      store = _Store();
      places = UserPlacesNofitier(const [], db, 'me', store);
    });

    tearDown(() => places.dispose());

    test('swaps every photo for its URL and saves the URLs', () async {
      places.addPlace('Galata', photos: ['/tmp/1.jpg', '/tmp/2.jpg']);
      await pumpEventQueue();

      const urls = ['https://photos.test/1.jpg', 'https://photos.test/2.jpg'];
      expect(store.uploads, ['/tmp/1.jpg', '/tmp/2.jpg']);
      expect(places.state.single.photos, urls);
      expect(db.docs.values.single['photos'], urls);
    });

    test('a failed upload keeps the file and is not retried', () async {
      store.failing.add('/tmp/bad.jpg');
      places.addPlace('Moda', photos: ['/tmp/bad.jpg', '/tmp/ok.jpg']);
      await pumpEventQueue();

      expect(places.state.single.photos, [
        '/tmp/bad.jpg',
        'https://photos.test/ok.jpg',
      ]);
      places.updatePlace(places.state.single.copyWith(title: 'Moda walk'));
      await pumpEventQueue();
      expect(store.uploads.where((p) => p == '/tmp/bad.jpg'), hasLength(1));
    });

    test('removing a photo while editing deletes it from storage', () async {
      places.addPlace('Bebek', photos: ['/tmp/1.jpg', '/tmp/2.jpg']);
      await pumpEventQueue();
      final place = places.state.single;

      places.updatePlace(place.copyWith(photos: [place.photos.last]));
      expect(store.deleted, ['https://photos.test/1.jpg']);
    });

    test('photos of a removed place go only after the undo window', () {
      fakeAsync((async) {
        places.addPlace('Kadıköy', photos: ['/tmp/1.jpg']);
        async.flushMicrotasks();
        final place = places.state.single;

        final index = places.removePlace(place);
        places.restorePlace(place, index);
        async.elapse(const Duration(seconds: 11));
        expect(store.deleted, isEmpty);

        places.removePlace(places.state.single);
        async.elapse(const Duration(seconds: 9));
        expect(store.deleted, isEmpty);
        async.elapse(const Duration(seconds: 2));
        expect(store.deleted, ['https://photos.test/1.jpg']);
      });
    });
  });
}
