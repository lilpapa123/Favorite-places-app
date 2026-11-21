import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_map.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Full-screen map: tap anywhere to drop the pin, then confirm.
/// Pops with the chosen [LatLng], or null if the user backs out.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, this.initial});

  final LatLng? initial;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _worldCenter = LatLng(20, 0);

  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.initial ?? _worldCenter,
              initialZoom: widget.initial == null ? AppMap.minZoom : 15,
              cameraConstraint: AppMap.worldConstraint,
              minZoom: AppMap.minZoom,
              onTap: (tapPosition, point) => setState(() => _picked = point),
            ),
            children: [
              AppMap.tiles(),
              if (picked != null)
                MarkerLayer(markers: [AppMap.pin(point: picked, selected: true)]),
              Padding(
                padding: EdgeInsets.only(bottom: bottomInset + 92),
                child: AppMap.attribution(),
              ),
            ],
          ),
          Positioned(
            left: AppSpace.lg,
            right: AppSpace.lg,
            top: topInset + AppSpace.sm,
            child: Row(
              children: [
                CircleIconButton(
                  icon: const AppIcon('back'),
                  semanticLabel: 'Back',
                  shadow: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Container(
                    height: 44,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: AppShadow.floating,
                    ),
                    child: Text(
                      picked == null
                          ? 'Tap the map to drop a pin'
                          : '${picked.latitude.toStringAsFixed(5)}, '
                                '${picked.longitude.toStringAsFixed(5)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong().copyWith(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: AppSpace.page,
            right: AppSpace.page,
            bottom: bottomInset + AppSpace.lg,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: AppShadow.floating,
              ),
              child: PillButton(
                label: 'Use this spot',
                icon: Icons.check,
                large: true,
                expanded: true,
                onPressed: picked == null
                    ? null
                    : () => Navigator.of(context).pop(picked),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
