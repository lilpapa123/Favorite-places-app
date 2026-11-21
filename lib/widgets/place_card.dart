import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/place_photo.dart';
import 'package:flutter/material.dart';

/// A place in the "My places" feed: photo with an "On map" badge, then the
/// name with its type pill, the note, and the neighborhood.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place, required this.onTap});

  static const double photoHeight = 180;

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = place.location;

    return Semantics(
      button: true,
      label: place.title,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: AppRadius.cardAll,
          boxShadow: AppShadow.card,
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: AppRadius.cardAll,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: photoHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'photo-${place.id}',
                        child: PlacePhoto(
                          image: place.image,
                          tint: AppColors.tintFor(place.id),
                        ),
                      ),
                      if (location != null)
                        const Positioned(
                          right: AppSpace.md,
                          top: AppSpace.md,
                          child: _OnMapBadge(),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    14,
                    AppSpace.lg,
                    AppSpace.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              place.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.title().copyWith(height: 1.47),
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          TypePill(label: place.category.label),
                        ],
                      ),
                      if (place.note.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          place.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.note(color: AppColors.muted)
                              .copyWith(height: 1.43),
                        ),
                      ],
                      if (location != null) ...[
                        const SizedBox(height: AppSpace.lg),
                        Row(
                          children: [
                            const AppIcon('pin_small'),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location.areaLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.meta().copyWith(height: 1.46),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pink pill with the place's type: "Café", "Viewpoint"…
class TypePill extends StatelessWidget {
  const TypePill({super.key, required this.label, this.large = false});

  final String label;

  /// 28 px tall with 13 pt text (detail screen) instead of 25 px / 11 pt.
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: large ? 28 : 25,
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppText.labelMedium(color: AppColors.accent)
            .copyWith(fontSize: large ? 13 : 11),
      ),
    );
  }
}

class _OnMapBadge extends StatelessWidget {
  const _OnMapBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.only(left: 10, right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon('pin_badge'),
          const SizedBox(width: 6),
          Text(
            'On map',
            style: AppText.label(color: AppColors.label).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
