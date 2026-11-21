import 'package:favorite_places/models/place.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

/// Turns coordinates into a readable address with the phone's built-in
/// geocoder (Apple Maps on iOS, Google on Android) — no API key needed.
///
/// If the lookup fails (offline, nothing found) the location is still
/// returned, just without an address.
/// geocoding 5.x works through an instance instead of top-level functions.
final Geocoding _geocoding = Geocoding();

Future<PlaceLocation> describeLocation(LatLng point) async {
  final fallback = PlaceLocation.fromLatLng(point);
  try {
    final List<Placemark> results = await _geocoding.placemarkFromCoordinates(
      point.latitude,
      point.longitude,
    );
    if (results.isEmpty) {
      return fallback;
    }
    final Placemark mark = results.first;
    String clean(String? s) => (s ?? '').trim();
    final street = <String>[
      clean(mark.thoroughfare),
      clean(mark.subThoroughfare),
    ].where((part) => part.isNotEmpty).join(', ');
    final name = clean(mark.name);
    return PlaceLocation(
      latitude: point.latitude,
      longitude: point.longitude,
      // iOS often puts the house number in `name`; prefer a real name.
      name: (name.isEmpty || RegExp(r'^\d').hasMatch(name)) ? street : name,
      street: street,
      area: clean(mark.subLocality),
      city: clean(mark.locality).isEmpty
          ? clean(mark.subAdministrativeArea)
          : clean(mark.locality),
      country: clean(mark.country),
    );
  } catch (_) {
    return fallback;
  }
}

/// Finds a place or address by name ("Galata Tower", "Kadıköy, Istanbul")
/// with the phone's geocoder. Returns null when nothing is found or the
/// lookup fails (offline, too vague).
Future<LatLng?> findPlace(String query) async {
  final text = query.trim();
  if (text.isEmpty) {
    return null;
  }
  try {
    final List<Location> results = await _geocoding.locationFromAddress(text);
    if (results.isEmpty) {
      return null;
    }
    return LatLng(results.first.latitude, results.first.longitude);
  } catch (_) {
    return null;
  }
}
