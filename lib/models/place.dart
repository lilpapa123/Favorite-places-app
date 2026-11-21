import 'dart:io';

import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

/// The "Type of place" chips. [plural] is used by the filters on My places,
/// [icon] by the map pins.
enum PlaceCategory {
  cafe('Café', 'Cafés', 'coffee'),
  viewpoint('Viewpoint', 'Views', 'view'),
  walk('Walk', 'Walks', 'tree'),
  other('Other', 'Other', 'pin_white');

  const PlaceCategory(this.label, this.plural, this.icon);

  final String label;
  final String plural;
  final String icon;
}

/// Where a place is, plus a readable address when one could be found.
class PlaceLocation {
  const PlaceLocation({
    required this.latitude,
    required this.longitude,
    this.name = '',
    this.street = '',
    this.area = '',
    this.city = '',
    this.country = '',
  });

  factory PlaceLocation.fromLatLng(LatLng point) =>
      PlaceLocation(latitude: point.latitude, longitude: point.longitude);

  final double latitude;
  final double longitude;

  /// Short name of the spot, e.g. "Ribeira das Naus".
  final String name;

  /// Street and number, e.g. "Rua da Rosa, 72".
  final String street;

  /// Neighborhood, e.g. "Bairro Alto".
  final String area;
  final String city;
  final String country;

  LatLng get latLng => LatLng(latitude, longitude);

  bool get hasAddress => name.isNotEmpty || area.isNotEmpty || city.isNotEmpty;

  /// `41.00820, 28.97840`
  String get coordinates =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  /// "Bairro Alto, Lisbon" — falls back to the coordinates.
  String get areaLabel {
    final parts = [
      if (area.isNotEmpty) area,
      if (city.isNotEmpty && city != area) city,
    ];
    return parts.isEmpty ? coordinates : parts.join(', ');
  }

  /// "Lisbon, Portugal".
  String get cityCountry => [
    if (city.isNotEmpty) city,
    if (country.isNotEmpty) country,
  ].join(', ');

  /// Best one-line title for the location row: name, area, or coordinates.
  String get title =>
      name.isNotEmpty ? name : (area.isNotEmpty ? area : coordinates);
}

class Place {
  Place({
    String? id,
    required this.title,
    this.category = PlaceCategory.cafe,
    this.note = '',
    this.image,
    this.location,
    DateTime? createdAt,
  }) : id = id ?? uuid.v4(),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final PlaceCategory category;
  final String note;
  final File? image;
  final PlaceLocation? location;
  final DateTime createdAt;

  String get city => location?.city ?? '';

  /// Same place with some fields changed (keeps id and save date).
  Place copyWith({
    String? title,
    PlaceCategory? category,
    String? note,
    File? image,
    PlaceLocation? location,
    bool clearLocation = false,
  }) {
    return Place(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      note: note ?? this.note,
      image: image ?? this.image,
      location: clearLocation ? null : (location ?? this.location),
      createdAt: createdAt,
    );
  }
}
