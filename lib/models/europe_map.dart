import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The design's drawn Europe map, from `assets/maps/europe.json`: country
/// shapes from Natural Earth 1:50m, each European country split into 5–6
/// regions. Everything is in the design's 402×874 artboard space, with the
/// same azimuthal equal-area projection (centred on 12°E 53°N), so no map
/// service is needed. `tool/build_europe_map.mjs` makes the file.
class EuropeMap {
  EuropeMap._({
    required this.size,
    required this.graticule,
    required this.countries,
    required this.scale,
    required this.translate,
    required double lon0,
    required double lat0,
  }) : _lon0 = lon0 * math.pi / 180,
       _lat0 = lat0 * math.pi / 180;

  factory EuropeMap.fromJson(Map<String, dynamic> json) {
    final translate = (json['translate'] as List).cast<num>();
    final center = (json['center'] as List).cast<num>();
    return EuropeMap._(
      size: Size((json['w'] as num).toDouble(), (json['h'] as num).toDouble()),
      graticule: parseSvgPath(json['grat'] as String),
      countries: [
        for (final c in json['countries'] as List)
          MapCountry._fromJson(c as Map<String, dynamic>),
      ],
      scale: (json['scale'] as num).toDouble(),
      translate: Offset(translate[0].toDouble(), translate[1].toDouble()),
      lon0: center[0].toDouble(),
      lat0: center[1].toDouble(),
    );
  }

  /// The artboard the shapes are drawn in.
  final Size size;
  final Path graticule;
  final List<MapCountry> countries;

  /// Projection scale and offset, as d3 fitted them to the artboard.
  final double scale;
  final Offset translate;
  final double _lon0;
  final double _lat0;

  /// Every region on the map.
  int get regionCount => countries.fold(0, (sum, c) => sum + c.regions.length);

  /// Where [lat], [lng] falls on the artboard (d3's geoAzimuthalEqualArea).
  Offset project(double lat, double lng) {
    final phi = lat * math.pi / 180;
    final lambda = lng * math.pi / 180 - _lon0;
    final k = math.sqrt(
      2 /
          (1 +
              math.sin(_lat0) * math.sin(phi) +
              math.cos(_lat0) * math.cos(phi) * math.cos(lambda)),
    );
    final x = k * math.cos(phi) * math.sin(lambda);
    final y =
        k *
        (math.cos(_lat0) * math.sin(phi) -
            math.sin(_lat0) * math.cos(phi) * math.cos(lambda));
    return translate + Offset(x * scale, -y * scale);
  }

  /// The country under [point]; a coastal place that lands just offshore
  /// (the map is 1:50m, so Istanbul falls in the Bosporus) counts for the
  /// land within 4 px, about 25 km. Null further out at sea or off the map.
  MapCountry? countryAt(Offset point) {
    for (final radius in const [0.0, 1.0, 2.0, 3.0, 4.0]) {
      for (var step = 0; step < (radius == 0 ? 1 : 8); step++) {
        final angle = step * math.pi / 4;
        final probe = point + Offset(math.cos(angle), math.sin(angle)) * radius;
        for (final country in countries) {
          if (country.shape.getBounds().contains(probe) &&
              country.shape.contains(probe)) {
            return country;
          }
        }
      }
    }
    return null;
  }
}

class MapCountry {
  MapCountry._fromJson(Map<String, dynamic> json)
    : name = json['name'] as String,
      code = json['code'] as String,
      shape = parseSvgPath(json['d'] as String),
      _centers = [
        for (final p in json['centers'] as List)
          Offset(((p as List)[0] as num).toDouble(), (p[1] as num).toDouble()),
      ],
      regions = [
        for (final d in json['cells'] as List) parseSvgPath(d as String),
      ];

  final String name;

  /// ISO 3166 two-letter code, for the chips.
  final String code;
  final Path shape;

  /// Region cells; draw them clipped to [shape]. Empty for countries that
  /// aren't split (outside Europe, or too small).
  final List<Path> regions;
  final List<Offset> _centers;

  /// How a region is saved on a profile: `"Turkey#3"`.
  String regionKey(int region) => '$name#$region';

  /// The region [point] is in: the one with the nearest centre, as the
  /// cells are the Voronoi cells around those centres. Null if unsplit.
  int? regionAt(Offset point) {
    int? best;
    var bestDistance = double.infinity;
    for (final (i, centre) in _centers.indexed) {
      final distance = (centre - point).distanceSquared;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return best;
  }
}

/// A path from the asset's SVG `d` strings, which only use M, L and Z.
Path parseSvgPath(String d) {
  final path = Path();
  for (final match in RegExp(r'([MLZ])([^MLZ]*)').allMatches(d)) {
    final command = match.group(1);
    if (command == 'Z') {
      path.close();
      continue;
    }
    final xy = match.group(2)!.split(',');
    final x = double.parse(xy[0]);
    final y = double.parse(xy[1]);
    command == 'M' ? path.moveTo(x, y) : path.lineTo(x, y);
  }
  return path;
}

final europeMapProvider = FutureProvider<EuropeMap>((ref) async {
  final text = await rootBundle.loadString('assets/maps/europe.json');
  return EuropeMap.fromJson(jsonDecode(text) as Map<String, dynamic>);
});
