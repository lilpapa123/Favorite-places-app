import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Shared map pieces (OpenStreetMap tiles and data).
class AppMap {
  const AppMap._();

  /// Standard OpenStreetMap tiles: free and keyless. Fine for building and
  /// testing; flutter_map prints a reminder in the console that the public
  /// OSM servers aren't meant for apps with lots of users. Before a public
  /// launch, switch [urlTemplate] to a provider with a free API key (e.g.
  /// MapTiler or Stadia Maps). OSM's policy also requires a real user agent.
  static TileLayer tiles() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.khaledwaled.favoriteplaces',
      maxNativeZoom: 19,
    );
  }

  /// The edges of the world map (Web Mercator stops at ±85.05°).
  static final LatLngBounds worldBounds = LatLngBounds(
    const LatLng(-85.05, -180),
    const LatLng(85.05, 180),
  );

  /// Keeps the camera inside the world: no gray space above or below it,
  /// no scrolling past its edges, and no zooming out beyond the point where
  /// the map fills the screen.
  static final CameraConstraint worldConstraint = CameraConstraint.contain(
    bounds: worldBounds,
  );

  /// Lowest zoom the interactive maps allow; at zoom 2 the world is ~1000 px
  /// tall, so it always covers a phone screen.
  static const double minZoom = 2;

  /// Map data is from OpenStreetMap (ODbL): the credit must stay visible on
  /// every map.
  static Widget attribution() {
    return SimpleAttributionWidget(
      backgroundColor: Colors.white.withValues(alpha: 0.85),
      source: Text(
        '© OpenStreetMap contributors',
        style: AppText.meta(),
      ),
    );
  }

  /// A marker whose pin tip sits exactly on [point] (used when picking a
  /// spot, where there is no category yet).
  static Marker pin({
    required LatLng point,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: point,
      width: MapPin.size,
      height: MapPin.size,
      alignment: Alignment.topCenter,
      child: MapPin(selected: selected, onTap: onTap),
    );
  }

  /// Round category pin from the design, centered on [point].
  static Marker categoryPin({
    required LatLng point,
    required PlaceCategory category,
    bool selected = false,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    return Marker(
      point: point,
      width: CategoryPin.size,
      height: CategoryPin.size,
      child: CategoryPin(
        category: category,
        selected: selected,
        onTap: onTap,
        semanticLabel: semanticLabel,
      ),
    );
  }

  /// The terracotta name label under the selected pin.
  static Marker pinLabel({required LatLng point, required String text}) {
    return Marker(
      point: point,
      width: 180,
      height: CategoryPin.size / 2 + 6 + 28,
      // Top edge on the point, then pushed below the 44 px pin.
      alignment: Alignment.bottomCenter,
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.only(top: CategoryPin.size / 2 + 6),
          child: Center(
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(color: Colors.white).copyWith(fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Navy "you are here" dot with a soft accuracy halo.
  static Marker userDot(LatLng point) {
    return Marker(
      point: point,
      width: 38,
      height: 38,
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.navy,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 44 px round pin with the category icon: white with a terracotta icon, or
/// terracotta with a white icon when selected.
class CategoryPin extends StatelessWidget {
  const CategoryPin({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
    this.semanticLabel,
  });

  static const double size = 44;

  final PlaceCategory category;
  final bool selected;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.ease,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: AppShadow.pin,
          ),
          alignment: Alignment.center,
          child: AppIcon(
            category.icon,
            size: 20,
            color: selected ? Colors.white : AppColors.accent,
          ),
        ),
      ),
    );
  }
}

/// Teardrop pin in the accent color; grows when selected.
class MapPin extends StatelessWidget {
  const MapPin({super.key, this.selected = false, this.onTap});

  static const double size = 48;

  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedScale(
          duration: AppMotion.medium,
          curve: Curves.easeOutBack,
          scale: selected ? 1.2 : 1,
          alignment: Alignment.bottomCenter,
          child: Icon(
            Icons.location_on,
            size: 40,
            color: selected ? AppColors.accentPressed : AppColors.accent,
            shadows: const [
              Shadow(
                color: Color(0x5514171C),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
