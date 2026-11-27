import 'package:favorite_places/models/europe_map.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Marks the Europe map region the phone is in as visited for [uid], and
/// returns its country when that region is new; null when it was already
/// marked, the phone is outside the map, or location isn't available.
/// Asks for location permission only when [ask] is true, so a check at
/// launch never pops a prompt.
Future<MapCountry?> markCurrentRegion({
  required EuropeMap map,
  required Social social,
  required String uid,
  required Set<String> known,
  bool ask = false,
}) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && ask) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );
    final point = map.project(position.latitude, position.longitude);
    final country = map.countryAt(point);
    final region = country?.regionAt(point);
    if (country == null || region == null) {
      return null;
    }
    final key = country.regionKey(region);
    if (known.contains(key)) {
      return null;
    }
    await social.markVisitedRegion(uid, key);
    return country;
  } catch (error) {
    debugPrint('Marking the current region failed: $error');
    return null;
  }
}
