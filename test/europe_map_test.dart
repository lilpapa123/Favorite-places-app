import 'dart:convert';
import 'dart:io';

import 'package:favorite_places/models/europe_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final map = EuropeMap.fromJson(
    jsonDecode(File('assets/maps/europe.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  test('places land where the design draws them', () {
    // d3 put Istanbul at (336.6, 501.8) on the design's artboard.
    final istanbul = map.project(41.01, 28.98);
    expect(istanbul.dx, closeTo(336.6, 0.1));
    expect(istanbul.dy, closeTo(501.8, 0.1));
    final country = map.countryAt(istanbul);
    expect(country?.code, 'TR');
    expect(country?.regionAt(istanbul), isNotNull);

    expect(map.countryAt(map.project(38.72, -9.14))?.code, 'PT'); // Lisbon
    expect(map.countryAt(map.project(41.9, 12.5))?.code, 'IT'); // Rome
    expect(map.countryAt(map.project(38.5, 5.0)), isNull); // at sea
  });

  test('Europe is split into the design\'s 204 regions', () {
    expect(map.regionCount, 204);
  });

  test('a region is saved by country name and index', () {
    final turkey = map.countries.firstWhere((c) => c.code == 'TR');
    expect(turkey.regionKey(2), 'Turkey#2');
  });
}
