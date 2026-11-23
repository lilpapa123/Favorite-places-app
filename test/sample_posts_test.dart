import 'package:favorite_places/data/sample_posts.dart';
import 'package:favorite_places/models/badges.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('57 sample posts, each by a sample person, newest first', () {
    final posts = samplePosts();
    expect(posts, hasLength(57));
    expect({for (final (_, p) in posts) p.id}, hasLength(57));
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

  test('Noah earns six badges, to show a long badge row', () {
    final noah = [
      for (final (owner, place) in samplePosts())
        if (owner == 'sample-noah') place,
    ];
    expect(earnedBadges(noah), hasLength(6));
  });

  test('Maya earns every badge', () {
    final maya = [
      for (final (owner, place) in samplePosts())
        if (owner == 'sample-maya') place,
    ];
    expect(earnedBadges(maya), AppBadge.values.toSet());
    expect(sampleFollowCounts('sample-maya'), (945, 180));
  });
}
