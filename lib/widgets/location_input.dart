import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/screens/map_picker.dart';
import 'package:favorite_places/services/address_lookup.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// The "Location" row of the add form: a white card with a pin tile, the
/// place's address and a chevron. Tapping it offers "Use my location" or
/// "Pick on the map", then looks up a readable address.
class LocationInput extends StatefulWidget {
  const LocationInput({super.key, this.onLocationPicked, this.initial});

  final ValueChanged<PlaceLocation?>? onLocationPicked;
  final PlaceLocation? initial;

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  PlaceLocation? _location;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _location = widget.initial;
  }

  void _setLocation(PlaceLocation? location) {
    setState(() => _location = location);
    widget.onLocationPicked?.call(location);
  }

  Future<void> _choose() async {
    if (_isBusy) {
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            0,
            AppSpace.page,
            AppSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.whereIsIt, style: AppText.title()),
              const SizedBox(height: AppSpace.md),
              _SheetOption(
                icon: Icons.my_location,
                label: context.l10n.useMyLocation,
                onTap: () => Navigator.of(ctx).pop('current'),
              ),
              const SizedBox(height: AppSpace.sm),
              _SheetOption(
                icon: Icons.map_outlined,
                label: context.l10n.pickOnMap,
                onTap: () => Navigator.of(ctx).pop('map'),
              ),
              if (_location != null) ...[
                const SizedBox(height: AppSpace.sm),
                _SheetOption(
                  icon: Icons.location_off_outlined,
                  label: context.l10n.removeLocation,
                  onTap: () => Navigator.of(ctx).pop('clear'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) {
      return;
    }
    switch (choice) {
      case 'current':
        await _useCurrentLocation();
      case 'map':
        await _pickOnMap();
      case 'clear':
        _setLocation(null);
    }
  }

  Future<void> _useCurrentLocation() async {
    final l10n = context.l10n;
    setState(() => _isBusy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMessage(l10n.locationServicesOff);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showMessage(l10n.locationPermissionDenied);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          l10n.locationBlocked,
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await _describe(LatLng(position.latitude, position.longitude));
    } catch (error) {
      _showMessage(l10n.couldNotGetLocation('$error'));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _pickOnMap() async {
    final picked = await Navigator.of(context, rootNavigator: true).push<LatLng>(
      MaterialPageRoute<LatLng>(
        builder: (ctx) => MapPickerScreen(initial: _location?.latLng),
      ),
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      await _describe(picked);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _describe(LatLng point) async {
    final location = await describeLocation(point);
    if (mounted) {
      _setLocation(location);
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final location = _location;
    final String title;
    final String subtitle;
    if (_isBusy) {
      title = context.l10n.findingSpot;
      subtitle = context.l10n.takesASecond;
    } else if (location == null) {
      title = context.l10n.addLocation;
      subtitle = context.l10n.addLocationHint;
    } else {
      title = location.title;
      subtitle = location.cityCountry.isNotEmpty
          ? location.cityCountry
          : location.coordinates;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.location, style: AppText.labelMedium()),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: context.l10n.locationSemantic(title),
          excludeSemantics: true,
          child: Material(
            color: AppColors.surface,
            borderRadius: AppRadius.fieldAll,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _choose,
              child: SizedBox(
                height: 68,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.tints.first,
                          borderRadius: AppRadius.fieldAll,
                        ),
                        child: _isBusy
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.navy,
                                ),
                              )
                            : const AppIcon('pin_location'),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.row(),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.meta().copyWith(height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      const AppIcon('chevron'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: AppRadius.fieldAll,
      child: InkWell(
        borderRadius: AppRadius.fieldAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: 14,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent),
              const SizedBox(width: AppSpace.md),
              Text(label, style: AppText.bodyStrong()),
            ],
          ),
        ),
      ),
    );
  }
}
