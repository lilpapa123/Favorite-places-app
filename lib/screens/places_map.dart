import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/screens/places_detail.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_map.dart';
import 'package:favorite_places/widgets/glass_tab_bar.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/place_photo.dart';
import 'package:favorite_places/widgets/search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// The Map tab: every place with a location as a round category pin.
/// Tapping a pin selects it (terracotta, with its name underneath) and shows
/// a preview card with "View place".
class PlacesMapScreen extends ConsumerStatefulWidget {
  const PlacesMapScreen({super.key});

  @override
  ConsumerState<PlacesMapScreen> createState() => _PlacesMapScreenState();
}

class _PlacesMapScreenState extends ConsumerState<PlacesMapScreen> {
  static const LatLng _worldCenter = LatLng(20, 0);

  /// Height of the gray title area; the map starts just under the title.
  static const double _headerHeight = 118;

  final MapController _map = MapController();
  final TextEditingController _search = TextEditingController();
  String? _selectedId;
  LatLng? _me;
  bool _locating = false;

  @override
  void dispose() {
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  List<Place> _matching(List<Place> pinned) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) {
      return pinned;
    }
    return pinned.where((place) {
      final location = place.location!;
      return place.title.toLowerCase().contains(query) ||
          '${location.title} ${location.areaLabel} ${location.city}'
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  void _select(Place place) {
    setState(() => _selectedId = place.id);
    _map.move(place.location!.latLng, _map.camera.zoom < 14 ? 15 : _map.camera.zoom);
  }

  Future<void> _locateMe() async {
    if (_locating) {
      return;
    }
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMessage('Location services are off. Turn them on in Settings.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Allow location access to see where you are.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) {
        return;
      }
      final me = LatLng(position.latitude, position.longitude);
      setState(() => _me = me);
      _map.move(me, 15);
    } catch (error) {
      _showMessage('Could not get your location: $error');
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// "Lisbon · 3" when every pin is in one city, otherwise "3 pinned".
  String _chipLabel(List<Place> pinned) {
    final cities = {
      for (final p in pinned)
        if (p.city.isNotEmpty) p.city,
    };
    if (cities.length == 1 && pinned.every((p) => p.city.isNotEmpty)) {
      return '${cities.first} · ${pinned.length}';
    }
    return '${pinned.length} pinned';
  }

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(userPlacesProvider);
    final pinned = places.where((place) => place.location != null).toList();
    final shown = _matching(pinned);
    final selected = shown.where((p) => p.id == _selectedId).firstOrNull;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final points = [for (final place in pinned) place.location!.latLng];

    final MapOptions options;
    if (points.length > 1) {
      options = MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: points,
          padding: EdgeInsets.fromLTRB(
            56,
            topInset + 120,
            56,
            GlassTabBar.height + 180,
          ),
          maxZoom: 15,
        ),
        onTap: (_, _) => setState(() => _selectedId = null),
      );
    } else {
      options = MapOptions(
        initialCenter: points.isEmpty ? _worldCenter : points.first,
        initialZoom: points.isEmpty ? 2 : 14,
        onTap: (_, _) => setState(() => _selectedId = null),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            top: topInset + _headerHeight,
            child: FlutterMap(
              mapController: _map,
              // Re-fit the camera whenever a pin is added or removed.
              key: ValueKey(points.length),
              options: options,
              children: [
                AppMap.tiles(),
                MarkerLayer(
                  markers: [
                    if (_me != null) AppMap.userDot(_me!),
                    for (final place in shown)
                      AppMap.categoryPin(
                        point: place.location!.latLng,
                        category: place.category,
                        selected: place.id == _selectedId,
                        semanticLabel: place.title,
                        onTap: () => _select(place),
                      ),
                    if (selected != null)
                      AppMap.pinLabel(
                        point: selected.location!.latLng,
                        text: selected.title,
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: AppMap.attribution(),
                ),
              ],
            ),
          ),
          // Gray title area.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              color: AppColors.background,
              padding: EdgeInsets.fromLTRB(
                AppSpace.page,
                topInset + AppSpace.sm,
                AppSpace.page,
                0,
              ),
              height: topInset + _headerHeight + 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Map', style: AppText.heading()),
                  Text(
                    'Your favorites, a little closer.',
                    style: AppText.meta().copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          // Search box overlapping the top of the map.
          Positioned(
            left: AppSpace.page,
            right: AppSpace.page,
            top: topInset + 94,
            child: SearchField(
              controller: _search,
              hintText: 'Search your places',
              shadow: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                final matches = _matching(pinned);
                if (matches.length == 1) {
                  _select(matches.first);
                }
              },
            ),
          ),
          if (pinned.isNotEmpty)
            Positioned(
              left: AppSpace.page,
              top: topInset + 156,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(_chipLabel(pinned), style: AppText.labelMedium()),
              ),
            ),
          if (pinned.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.all(AppSpace.page),
                padding: const EdgeInsets.all(AppSpace.xxl),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardAll,
                  boxShadow: AppShadow.floating,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon('pin_location', size: 32),
                    const SizedBox(height: AppSpace.sm),
                    Text('No pins yet', style: AppText.title()),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'Add a place with a location\nand it shows up here.',
                      textAlign: TextAlign.center,
                      style: AppText.meta(),
                    ),
                  ],
                ),
              ),
            ),
          // "Center on my location", above the preview card when it shows.
          AnimatedPositioned(
            duration: AppMotion.medium,
            curve: AppMotion.ease,
            right: AppSpace.page,
            bottom: bottomInset + AppSpace.md + (selected == null ? 0 : 168),
            child: CircleIconButton(
              size: 48,
              shadow: true,
              semanticLabel: 'Center on my location',
              icon: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.navy,
                      ),
                    )
                  : const AppIcon('locate'),
              onPressed: _locateMe,
            ),
          ),
          // Preview card for the selected pin, above the glass bar.
          AnimatedPositioned(
            duration: AppMotion.medium,
            curve: AppMotion.ease,
            left: AppSpace.page,
            right: AppSpace.page,
            bottom: selected == null ? -200 : bottomInset + AppSpace.md,
            child: AnimatedOpacity(
              duration: AppMotion.fast,
              opacity: selected == null ? 0 : 1,
              child: selected == null
                  ? const SizedBox(height: 148)
                  : _PreviewCard(
                      place: selected,
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (ctx) =>
                              PlacesDetailScreen(placeId: selected.id),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.place, required this.onOpen});

  final Place place;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final location = place.location!;
    final meta = [
      place.category.label,
      if (location.area.isNotEmpty) location.area
      else if (location.city.isNotEmpty) location.city,
    ].join(' · ');

    return Container(
      height: 148,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardAll,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A1A1F2E),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.fieldAll,
            child: SizedBox(
              width: 104,
              height: 124,
              child: PlacePhoto(
                image: place.image,
                tint: AppColors.tintFor(place.id),
                iconSize: 24,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelMedium(color: AppColors.muted)
                      .copyWith(fontSize: 11),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  place.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title().copyWith(height: 1.4),
                ),
                const SizedBox(height: 3),
                Text(
                  place.note.isNotEmpty ? place.note : location.areaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.meta().copyWith(height: 1.4),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'View place',
                  excludeSemantics: true,
                  child: Material(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: onOpen,
                      child: SizedBox(
                        height: 36,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'View place',
                                  style: AppText.label(color: AppColors.accent)
                                      .copyWith(fontSize: 13),
                                ),
                              ),
                              const AppIcon('arrow_right'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
