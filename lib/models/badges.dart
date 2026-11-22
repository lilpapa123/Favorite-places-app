import 'package:favorite_places/models/place.dart';
import 'package:latlong2/latlong.dart';

/// Achievement badges (art in `assets/badges/<name>.svg`), earned from the
/// places a user has saved.
enum AppBadge {
  firstSteps('first_steps'),
  cityHopper('city_hopper'),
  globetrotter('globetrotter'),
  frequentFlyer('frequent_flyer'),
  roadTripper('road_tripper'),
  backpacker('backpacker'),
  shutterbug('shutterbug'),
  summitSeeker('summit_seeker'),
  jungleExplorer('jungle_explorer'),
  beachBum('beach_bum'),
  happyCamper('happy_camper'),
  stargazer('stargazer');

  const AppBadge(this.asset);

  final String asset;

  String get path => 'assets/badges/$asset.svg';
}

/// Badges earned by [places], in [AppBadge] order.
Set<AppBadge> earnedBadges(List<Place> places) {
  int ofType(PlaceCategory c) => places.where((p) => p.category == c).length;
  final located = [for (final p in places) ?p.location];
  final cities = {
    for (final l in located)
      if (l.city.isNotEmpty) l.city,
  };
  final countries = {
    for (final l in located)
      if (l.country.isNotEmpty) l.country,
  };
  final continents = {for (final l in located) _continent(l.latLng)};

  return {
    if (places.isNotEmpty) AppBadge.firstSteps,
    if (cities.length >= 5) AppBadge.cityHopper,
    if (countries.length >= 5) AppBadge.globetrotter,
    if (continents.length >= 3) AppBadge.frequentFlyer,
    if (_farthestKm(located) >= 500) AppBadge.roadTripper,
    if (places.length >= 25) AppBadge.backpacker,
    if (places.where((p) => p.photos.isNotEmpty).length >= 10)
      AppBadge.shutterbug,
    if (ofType(PlaceCategory.hike) >= 3) AppBadge.summitSeeker,
    if (ofType(PlaceCategory.nature) >= 3) AppBadge.jungleExplorer,
    if (ofType(PlaceCategory.beach) >= 3) AppBadge.beachBum,
    if (ofType(PlaceCategory.camping) >= 3) AppBadge.happyCamper,
    if (ofType(PlaceCategory.night) >= 3) AppBadge.stargazer,
  };
}

double _farthestKm(List<PlaceLocation> located) {
  const distance = Distance();
  var best = 0.0;
  for (var i = 0; i < located.length; i++) {
    for (var j = i + 1; j < located.length; j++) {
      final km = distance.as(
        LengthUnit.Kilometer,
        located[i].latLng,
        located[j].latLng,
      );
      if (km > best) {
        best = km;
      }
    }
  }
  return best;
}

/// shortcut: continents from rough coordinate boxes, so places near a border
/// (e.g. Istanbul, Suez) can land on either side; use country codes for an
/// exact answer.
String _continent(LatLng p) {
  final lat = p.latitude;
  final lng = p.longitude;
  if (lat < -60) return 'antarctica';
  if (lng < -25) return lat > 12 ? 'north_america' : 'south_america';
  if (lat < -10 && lng > 110) return 'oceania';
  if (lng < 60 && lat < 36 && !(lng > 34 && lat > 12)) return 'africa';
  if (lng < 40 && lat >= 36) return 'europe';
  return 'asia';
}
