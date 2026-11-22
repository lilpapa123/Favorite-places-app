import 'package:favorite_places/data/sample_posts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('30 sample posts, each by a sample person, newest first', () {
    final posts = samplePosts();
    expect(posts, hasLength(30));
    expect({for (final (_, p) in posts) p.id}, hasLength(30));
    for (final (owner, place) in posts) {
      expect(isSampleUid(owner), isTrue);
      expect(sampleProfile(owner), isNotNull, reason: owner);
      expect(place.photos, isNotEmpty);
      expect(place.location, isNotNull);
    }
    final dates = [for (final (_, p) in posts) p.createdAt];
    expect(dates, [...dates]..sort((a, b) => b.compareTo(a)));
  });

  test('samples stay out of tests', () {
    expect(showSamplePosts, isFalse);
  });
}
