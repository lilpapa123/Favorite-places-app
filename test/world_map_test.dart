import 'dart:convert';
import 'dart:io';

import 'package:favorite_places/models/world_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final map = WorldMap.fromJson(
    jsonDecode(File('assets/maps/world.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  test('places land where the design draws them', () {
    // The design's pins: Istanbul (759.4, 450.3), Lisbon (620.9, 461.1).
    final istanbul = map.project(41.01, 28.98);
    expect(istanbul.dx, closeTo(759.4, 0.3));
    expect(istanbul.dy, closeTo(450.3, 0.3));
    final lisbon = map.project(38.72, -9.14);
    expect(lisbon.dx, closeTo(620.9, 0.3));
    expect(lisbon.dy, closeTo(461.1, 0.3));

    final country = map.countryAt(istanbul);
    expect(country?.code, 'TR');
    expect(country?.regionAt(istanbul), isNotNull);
    expect(map.countryAt(lisbon)?.code, 'PT');
    expect(map.countryAt(map.project(35.68, 139.69))?.code, 'JP'); // Tokyo
    expect(map.countryAt(map.project(40.71, -74.0))?.code, 'US'); // New York
    expect(map.countryAt(map.project(-33.87, 151.21))?.code, 'AU'); // Sydney
    expect(map.countryAt(map.project(38.5, 5.0)), isNull); // at sea
  });

  test('the world is split into the design\'s 842 regions', () {
    expect(map.countries, hasLength(240));
    expect(map.countries.fold(0, (sum, c) => sum + c.regions.length), 842);
  });

  test('a region is saved by country name and index', () {
    final turkey = map.countries.firstWhere((c) => c.code == 'TR');
    expect(turkey.regionKey(2), 'Turkey#2');
  });
}
