import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The design's drawn world map, from `assets/maps/world.json`: every
/// country from Natural Earth 1:50m in Mercator, with each larger country
/// split into 5–6 regions. Everything is in the design's 1308.2×874 space,
/// so no map service is needed. `tool/build_world_map.py` makes the file.
class WorldMap {
  WorldMap._({
    required this.size,
    required this.graticule,
    required this.countries,
    required this.scale,
    required this.translate,
    required this.startX,
    required this.total,
  });

  factory WorldMap.fromJson(Map<String, dynamic> json) {
    final translate = (json['translate'] as List).cast<num>();
    return WorldMap._(
      size: Size((json['w'] as num).toDouble(), (json['h'] as num).toDouble()),
      graticule: parseSvgPath(json['grat'] as String),
      countries: [
        for (final c in json['countries'] as List)
          MapCountry._fromJson(c as Map<String, dynamic>),
      ],
      scale: (json['scale'] as num).toDouble(),
      translate: Offset(translate[0].toDouble(), translate[1].toDouble()),
      startX: (json['startX'] as num).toDouble(),
      total: json['total'] as int,
    );
  }

  /// The map's own size at zoom 1; it fills the screen's height.
  final Size size;
  final Path graticule;
  final List<MapCountry> countries;

  /// Mercator scale and the position of 0°, 0°.
  final double scale;
  final Offset translate;

  /// Where the map opens: this far in from its left edge, on Europe.
  final double startX;

  /// Countries in the world, for "6 of 195 countries".
  final int total;

  /// Where [lat], [lng] falls on the map (d3's geoMercator).
  Offset project(double lat, double lng) {
    final phi = lat.clamp(-85.0, 85.0) * math.pi / 180;
    final lambda = lng * math.pi / 180;
    return translate +
        Offset(
          lambda * scale,
          -math.log(math.tan(math.pi / 4 + phi / 2)) * scale,
        );
  }

  /// The country under [point]; a coastal place that lands just offshore
  /// (the map is 1:50m, so Istanbul falls in the Bosporus) counts for the
  /// land within 4 px. Null further out at sea.
  MapCountry? countryAt(Offset point) {
    for (final radius in const [0.0, 1.0, 2.0, 3.0, 4.0]) {
      for (var step = 0; step < (radius == 0 ? 1 : 8); step++) {
        final angle = step * math.pi / 4;
        final probe = point + Offset(math.cos(angle), math.sin(angle)) * radius;
        for (final country in countries) {
          if (country.bounds.contains(probe) && country.shape.contains(probe)) {
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
      label = Offset(
        ((json['label'] as List)[0] as num).toDouble(),
        (json['label'][1] as num).toDouble(),
      ),
      labelWidth = (json['label'][2] as num).toDouble(),
      regions = [
        for (final d in json['cells'] as List) parseSvgPath(d as String),
      ] {
    bounds = shape.getBounds();
  }

  final String name;

  /// ISO 3166 two-letter code, for the chips and the country count.
  final String code;
  final Path shape;
  late final Rect bounds;

  /// Where its name goes: the middle of its biggest piece of land.
  final Offset label;

  /// How wide that biggest piece is, so its name only shows where it fits.
  final double labelWidth;

  /// Region cells; draw them clipped to [shape]. Empty for countries too
  /// small to split.
  final List<Path> regions;

  /// How a region is saved on a profile: `"Turkey#3"`.
  String regionKey(int region) => '$name#$region';

  /// The region [point] is in; for a point just off the coast, the cell
  /// whose middle is nearest. Null if the country isn't split.
  int? regionAt(Offset point) {
    int? best;
    var bestDistance = double.infinity;
    for (final (i, cell) in regions.indexed) {
      if (cell.contains(point)) {
        return i;
      }
      final distance = (cell.getBounds().center - point).distanceSquared;
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

final worldMapProvider = FutureProvider<WorldMap>((ref) async {
  final text = await rootBundle.loadString('assets/maps/world.json');
  return WorldMap.fromJson(jsonDecode(text) as Map<String, dynamic>);
});
