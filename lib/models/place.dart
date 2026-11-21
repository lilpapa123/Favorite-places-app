import 'dart:io';

import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

/// The "Type of place" chips. [icon] is used by the map pins; the
/// translated names live in lib/l10n/l10n.dart.
enum PlaceCategory {
  cafe('coffee'),
  viewpoint('view'),
  walk('tree'),
  hike('view'),
  nature('tree'),
  beach('pin_white'),
  camping('tree'),
  night('pin_white'),
  other('pin_white');

  const PlaceCategory(this.icon);

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

  /// Firestore document for this place, owned by [ownerUid].
  Map<String, Object?> toFirestore(String ownerUid) => {
    'ownerUid': ownerUid,
    'title': title,
    'category': category.name,
    'note': note,
    'createdAt': createdAt.millisecondsSinceEpoch,
    // shortcut: only the photo's path on this phone is stored, so others see
    // no photo; upload to Firebase Storage when photos should be shared.
    'localImagePath': image?.path,
    'location': location == null
        ? null
        : {
            'latitude': location!.latitude,
            'longitude': location!.longitude,
            'name': location!.name,
            'street': location!.street,
            'area': location!.area,
            'city': location!.city,
            'country': location!.country,
          },
  };

  factory Place.fromFirestore(String id, Map<String, dynamic> data) {
    final loc = data['location'] as Map<String, dynamic>?;
    final path = data['localImagePath'] as String?;
    return Place(
      id: id,
      title: data['title'] as String? ?? '',
      category: PlaceCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => PlaceCategory.other,
      ),
      note: data['note'] as String? ?? '',
      image: path != null && File(path).existsSync() ? File(path) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] as int? ?? 0,
      ),
      location: loc == null
          ? null
          : PlaceLocation(
              latitude: (loc['latitude'] as num).toDouble(),
              longitude: (loc['longitude'] as num).toDouble(),
              name: loc['name'] as String? ?? '',
              street: loc['street'] as String? ?? '',
              area: loc['area'] as String? ?? '',
              city: loc['city'] as String? ?? '',
              country: loc['country'] as String? ?? '',
            ),
    );
  }

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
