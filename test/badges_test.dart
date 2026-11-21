import 'package:favorite_places/data/sample_places.dart';
import 'package:favorite_places/models/badges.dart';
import 'package:favorite_places/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

Place _at(
  String city,
  String country,
  double lat,
  double lng, [
  PlaceCategory category = PlaceCategory.cafe,
]) => Place(
  title: city,
  category: category,
  location: PlaceLocation(
    latitude: lat,
    longitude: lng,
    city: city,
    country: country,
  ),
);

void main() {
  test('no places earns nothing', () {
    expect(earnedBadges(const []), isEmpty);
  });

  test('one place earns First Steps only', () {
    expect(earnedBadges([_at('Rome', 'Italy', 41.9, 12.5)]), {
      AppBadge.firstSteps,
    });
  });

  test('three hikes earn Summit Seeker, two do not', () {
    final hikes = [
      for (var i = 0; i < 3; i++)
        _at('Göreme', 'Türkiye', 38.6, 34.8, PlaceCategory.hike),
    ];
    expect(
      earnedBadges(hikes.take(2).toList()),
      isNot(contains(AppBadge.summitSeeker)),
    );
    expect(earnedBadges(hikes), contains(AppBadge.summitSeeker));
  });

  test('Road Tripper needs two places at least 500 km apart', () {
    final near = [
      _at('Istanbul', 'Türkiye', 41.0, 28.9),
      _at('Bursa', 'Türkiye', 40.2, 29.0),
    ];
    final far = [
      _at('Istanbul', 'Türkiye', 41.0, 28.9),
      _at('Cairo', 'Egypt', 30.0, 31.2),
    ];
    expect(earnedBadges(near), isNot(contains(AppBadge.roadTripper)));
    expect(earnedBadges(far), contains(AppBadge.roadTripper));
  });

  test('the 15 sample places earn the travel badges', () {
    final earned = earnedBadges(samplePlaces());
    expect(
      earned,
      containsAll([
        AppBadge.firstSteps,
        AppBadge.cityHopper,
        AppBadge.globetrotter,
        AppBadge.frequentFlyer,
        AppBadge.roadTripper,
      ]),
    );
    expect(earned, isNot(contains(AppBadge.backpacker)));
  });
}
