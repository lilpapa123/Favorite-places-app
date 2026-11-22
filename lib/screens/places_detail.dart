import 'dart:io' show Platform;

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/screens/add_place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_map.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/place_card.dart';
import 'package:favorite_places/widgets/place_photo.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// One saved place: photo, name, type and date, the note, where it is, and
/// "Edit place". Opens inside a tab, so the glass bar stays visible.
class PlacesDetailScreen extends ConsumerWidget {
  const PlacesDetailScreen({super.key, required this.placeId});

  /// Looked up live, so edits show up straight away.
  final String placeId;

  void _remove(BuildContext context, WidgetRef ref, Place place) {
    final notifier = ref.read(userPlacesProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    final index = notifier.removePlace(place);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.removedFromMyPlaces),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () => notifier.restorePlace(place, index),
          ),
        ),
      );
  }

  void _edit(BuildContext context, Place place) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => AddedPlaceScreen(existing: place),
      ),
    );
  }

  Future<void> _more(BuildContext context, WidgetRef ref, Place place) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
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
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AppIcon('edit'),
                title: Text(context.l10n.editPlace, style: AppText.row()),
                onTap: () => Navigator.of(ctx).pop('edit'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AppIcon('heart_accent'),
                title: Text(
                  context.l10n.removeFromMyPlaces,
                  style: AppText.row(color: AppColors.accent),
                ),
                onTap: () => Navigator.of(ctx).pop('remove'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    if (choice == 'edit') {
      _edit(context, place);
    } else if (choice == 'remove') {
      _remove(context, ref, place);
    }
  }

  Future<void> _openInMaps(BuildContext context, PlaceLocation location) async {
    final lat = location.latitude;
    final lng = location.longitude;
    final label = Uri.encodeComponent(location.title);
    final url = Platform.isIOS
        ? Uri.parse('https://maps.apple.com/?ll=$lat,$lng&q=$label')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
          );
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenMaps)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref
        .watch(userPlacesProvider)
        .where((p) => p.id == placeId)
        .firstOrNull;
    if (place == null) {
      // Removed while open (e.g. undo window passed): nothing to show.
      return const Scaffold(body: SizedBox.shrink());
    }
    final location = place.location;
    final saved = place.createdAt;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.sm,
            AppSpace.page,
            bottomBarClearance(context),
          ),
          children: [
            Row(
              children: [
                CircleIconButton(
                  icon: AppIcon('back', color: AppColors.accent),
                  semanticLabel: context.l10n.back,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    context.l10n.savedPlace,
                    textAlign: TextAlign.center,
                    style: AppText.row(color: AppColors.label),
                  ),
                ),
                CircleIconButton(
                  icon: AppIcon('more', color: AppColors.accent),
                  semanticLabel: context.l10n.morePlaceActions,
                  onPressed: () => _more(context, ref, place),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            SizedBox(
              height: 204,
              child: ClipRRect(
                borderRadius: AppRadius.cardAll,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'photo-${place.id}',
                      child: PlacePhotos(
                        photos: place.photos,
                        tint: AppColors.tintFor(place.id),
                        iconSize: 40,
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: CircleIconButton(
                        size: 42,
                        icon: const AppIcon('heart_accent'),
                        semanticLabel: context.l10n.removeFromMyPlaces,
                        onPressed: () => _remove(context, ref, place),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(place.title, style: AppText.display()),
            const SizedBox(height: 5),
            Row(
              children: [
                TypePill(label: place.category.label(context.l10n), large: true),
                const SizedBox(width: AppSpace.md),
                Text(
                  context.l10n.savedOn(DateFormat.MMMMd(context.l10n.localeName).format(saved)),
                  style: AppText.meta().copyWith(fontSize: 12),
                ),
              ],
            ),
            if (place.note.isNotEmpty) ...[
              const SizedBox(height: AppSpace.lg),
              _Card(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.myLittleNote,
                      style: AppText.overline().copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      place.note,
                      style: AppText.note(color: AppColors.label)
                          .copyWith(height: 1.43),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            if (location != null)
              _LocationCard(
                location: location,
                onOpen: () => _openInMaps(context, location),
              )
            else
              _Card(
                child: Row(
                  children: [
                    const AppIcon('pin_location'),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        context.l10n.noLocationYet,
                        style: AppText.meta(),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpace.lg),
            PillButton(
              label: context.l10n.editPlace,
              leading: const AppIcon('edit'),
              variant: PillButtonVariant.outlined,
              expanded: true,
              large: true,
              onPressed: () => _edit(context, place),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location, required this.onOpen});

  final PlaceLocation location;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small live map with the round terracotta pin.
          ClipRRect(
            borderRadius: AppRadius.fieldAll,
            child: SizedBox(
              width: 96,
              height: 100,
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: location.latLng,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    AppMap.tiles(),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: location.latLng,
                          width: 36,
                          height: 36,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const AppIcon('pin_white'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  location.areaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong().copyWith(height: 1.4),
                ),
                const SizedBox(height: 5),
                if (location.street.isNotEmpty)
                  Text(
                    location.street,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta().copyWith(height: 1.4),
                  ),
                if (location.cityCountry.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    location.cityCountry,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta().copyWith(height: 1.4),
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                Semantics(
                  button: true,
                  label: context.l10n.openInMaps,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onOpen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.openInMaps,
                            style: AppText.label(color: AppColors.accent),
                          ),
                          const SizedBox(width: AppSpace.md),
                          const AppIcon('arrow_up_right'),
                        ],
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

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardAll,
      ),
      child: child,
    );
  }
}
