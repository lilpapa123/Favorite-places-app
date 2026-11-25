import 'dart:math';

import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/services/place_photo_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('a big photo shrinks to fit one Firestore document', () {
    // Noise barely compresses, so this JPEG is several MB.
    final random = Random(1);
    final big = img.Image(width: 2400, height: 1800);
    for (final p in big) {
      p
        ..r = random.nextInt(256)
        ..g = random.nextInt(256)
        ..b = random.nextInt(256);
    }
    final bytes = img.encodeJpg(big, quality: 95);
    expect(bytes.length, greaterThan(FirestorePlacePhotoStore.maxBytes));

    final small = shrinkPhoto(bytes);
    expect(small.length, lessThanOrEqualTo(FirestorePlacePhotoStore.maxBytes));
    expect(img.decodeJpg(small)!.width, lessThanOrEqualTo(1080));
  });

  test('Firestore photos count as shared', () {
    expect(isUploadedPhoto('firestore://photos/abc'), isTrue);
    expect(isUploadedPhoto('/var/mobile/photo.jpg'), isFalse);
  });
}
