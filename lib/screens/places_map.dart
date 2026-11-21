import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/screens/places_detail.dart';
import 'package:favorite_places/services/address_lookup.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_map.dart';
import 'package:favorite_places/widgets/glass_tab_bar.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/place_photo.dart';
import 'package:favorite_places/widgets/search_field.dart';
import 'dart:math' as math;

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

class _PlacesMapScreenState extends ConsumerState<PlacesMapScreen>
    with SingleTickerProviderStateMixin {
  static const LatLng _worldCenter = LatLng(20, 0);

  /// Height of the gray title area; the map starts right under the
  /// subtitle and the search box floats on top of the map.
  static const double _headerHeight = 50;


  final MapController _map = MapController();
  late final AnimationController _flight = AnimationController(vsync: this);
  final TextEditingController _search = TextEditingController();
  String? _selectedId;
  LatLng? _me;
  bool _searchOpen = false;

  /// A place found by name (not one of the user's), shown as a pin.
  LatLng? _found;
  bool _finding = false;
  bool _locating = false;

  @override
  void dispose() {
    _flight.dispose();
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

  /// Smoothly flies the camera to [target] like Apple/Google Maps: for long
  /// trips it zooms out, glides across, then zooms back in on the spot.
  void _flyTo(LatLng target, double zoom) {
    final camera = _map.camera;
    final start = camera.center;
    final startZoom = camera.zoom;

    // How far the trip is, in screen widths at the starting zoom.
    final distance = const Distance().as(LengthUnit.Kilometer, start, target);
    final kmPerScreen = 40075 / math.pow(2, startZoom) * 1.5;
    final screens = distance / kmPerScreen;

    // Zoom out mid-flight by up to ~4 levels on long trips, never below 2.
    final dip = (math.log(1 + screens) / math.ln2).clamp(0.0, 4.0);
    final midZoom = math.max(
      AppMap.minZoom,
      math.min(startZoom, zoom) - dip,
    );

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _map.move(target, zoom);
      return;
    }

    _flight
      ..stop()
      ..duration = Duration(
        milliseconds: (700 + 300 * math.min(dip, 3.0)).round(),
      );

    final curve = CurvedAnimation(parent: _flight, curve: Curves.easeInOutCubic);
    void tick() {
      final t = curve.value;
      final lat = start.latitude + (target.latitude - start.latitude) * t;
      final lng = start.longitude + (target.longitude - start.longitude) * t;
      // Zoom follows a gentle arc: start -> mid (out) -> target (in).
      final linear = startZoom + (zoom - startZoom) * t;
      final arc = linear - (linear - midZoom) * math.sin(math.pi * t);
      _map.move(LatLng(lat, lng), arc);
    }

    curve.addListener(tick);
    _flight.forward(from: 0).whenCompleteOrCancel(() {
      curve
        ..removeListener(tick)
        ..dispose();
    });
  }

  void _closeSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchOpen = false;
      _search.clear();
      _found = null;
    });
  }

  /// Search button on the keyboard: jump to the user's place if exactly one
  /// matches; otherwise look the words up as a real place or address.
  Future<void> _submitSearch(List<Place> pinned) async {
    final query = _search.text.trim();
    if (query.isEmpty) {
      return;
    }
    final matches = _matching(pinned);
    if (matches.length == 1) {
      _select(matches.first);
      return;
    }
    if (matches.isNotEmpty) {
      return; // Several of the user's places match: they're all on the map.
    }
    setState(() => _finding = true);
    final point = await findPlace(query);
    if (!mounted) {
      return;
    }
    setState(() {
      _finding = false;
      _found = point;
      _selectedId = null;
    });
    if (point == null) {
      _showMessage(context.l10n.couldNotFindQuery(query));
    } else {
      FocusScope.of(context).unfocus();
      _flyTo(point, 15);
    }
  }

  void _select(Place place) {
    setState(() => _selectedId = place.id);
    _flyTo(
      place.location!.latLng,
      _map.camera.zoom < 14 ? 15 : _map.camera.zoom,
    );
  }

  Future<void> _locateMe() async {
    final l10n = context.l10n;
    if (_locating) {
      return;
    }
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMessage(l10n.locationServicesOff);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage(l10n.allowLocationToSee);
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
      _flyTo(me, 15);
    } catch (error) {
      _showMessage(l10n.couldNotGetLocation('$error'));
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
      return context.l10n.cityCount(cities.first, pinned.length);
    }
    return context.l10n.pinnedCount(pinned.length);
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
        cameraConstraint: AppMap.worldConstraint,
        minZoom: AppMap.minZoom,
      );
    } else {
      options = MapOptions(
        initialCenter: points.isEmpty ? _worldCenter : points.first,
        initialZoom: points.isEmpty ? AppMap.minZoom : 14,
        onTap: (_, _) => setState(() => _selectedId = null),
        cameraConstraint: AppMap.worldConstraint,
        minZoom: AppMap.minZoom,
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
                    if (_found != null)
                      AppMap.pin(point: _found!, selected: true),
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
                  child: AppMap.attribution(context),
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
                topInset + AppSpace.xs,
                AppSpace.page,
                0,
              ),
              height: topInset + _headerHeight,
              // One compact line: the title (with its subtitle) and a search
              // icon; tapping the icon swaps the line for a search box.
              child: AnimatedSwitcher(
                duration: AppMotion.medium,
                switchInCurve: AppMotion.ease,
                switchOutCurve: AppMotion.ease,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    axisAlignment: 1,
                    child: child,
                  ),
                ),
                child: _searchOpen
                    ? Row(
                        key: const ValueKey('search'),
                        children: [
                          Expanded(
                            child: SearchField(
                              controller: _search,
                              hintText: context.l10n.searchPlacesOrCities,
                              height: 42,
                              autofocus: true,
                              onChanged: (_) => setState(() => _found = null),
                              onSubmitted: (_) => _submitSearch(pinned),
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          CircleIconButton(
                            size: 42,
                            icon: _finding
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.accent,
                                    ),
                                  )
                                : const AppIcon('close'),
                            semanticLabel: context.l10n.closeSearch,
                            onPressed: _closeSearch,
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('title'),
                        children: [
                          // Title and subtitle share a baseline; the icon
                          // is centered on the line.
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(context.l10n.tabMap, style: AppText.heading()),
                                const SizedBox(width: AppSpace.md),
                                Expanded(
                                  child: Text(
                                    context.l10n.mapSubtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.meta(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          CircleIconButton(
                            size: 42,
                            icon: const AppIcon('search'),
                            semanticLabel: context.l10n.searchPlacesOrCities,
                            onPressed: () =>
                                setState(() => _searchOpen = true),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (pinned.isNotEmpty)
            Positioned(
              left: AppSpace.page,
              top: topInset + _headerHeight + AppSpace.md,
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
          if (pinned.isEmpty && !_searchOpen && _found == null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(AppSpace.page),
                padding: const EdgeInsets.all(AppSpace.xxl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardAll,
                  boxShadow: AppShadow.floating,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon('pin_location', size: 32),
                    const SizedBox(height: AppSpace.sm),
                    Text(context.l10n.noPinsYet, style: AppText.title()),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      context.l10n.noPinsBody,
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
              semanticLabel: context.l10n.centerOnMyLocation,
              icon: _locating
                  ? SizedBox(
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
      place.category.label(context.l10n),
      if (location.area.isNotEmpty) location.area
      else if (location.city.isNotEmpty) location.city,
    ].join(' · ');

    return Container(
      height: 148,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
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
                  label: context.l10n.viewPlace,
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
                          padding: const EdgeInsetsDirectional.only(start: 16, end: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.l10n.viewPlace,
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
