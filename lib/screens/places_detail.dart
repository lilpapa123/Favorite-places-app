import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/screens/add_place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_map.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/place_photo.dart';
import 'package:favorite_places/widgets/post_sheets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// One saved place, in the design's story layout: the photo full-bleed, a
/// cream sheet over it with quick facts, the note and where it is. Opens
/// inside a tab, so the glass bar stays visible.
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.couldNotOpenMaps)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final place = ref
        .watch(userPlacesProvider)
        .where((p) => p.id == placeId)
        .firstOrNull;
    if (place == null) {
      // Removed while open (e.g. undo window passed): nothing to show.
      return const Scaffold(body: SizedBox.shrink());
    }
    final me = ref.watch(authStateProvider).value?.uid;
    final location = place.location;
    final top = MediaQuery.paddingOf(context).top;
    const heroHeight = 404.0;
    // The sheet rises 28 px over the photo.
    const sheetTop = heroHeight - 28;

    // Story layout from the design: the photo leads full-bleed, a cream
    // sheet rises over it with quick facts, the note and where it is.
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: heroHeight,
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
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x610C1E08),
                              Color(0x000C1E08),
                              Color(0x000C1E08),
                              Color(0xB80C1E08),
                            ],
                            stops: [0, 0.26, 0.46, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpace.lg,
                      right: AppSpace.lg,
                      top: top + 4,
                      child: Row(
                        children: [
                          _GlassButton(
                            label: l10n.back,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const AppIcon('back', color: _onGlass),
                          ),
                          const Spacer(),
                          _GlassButton(
                            label: l10n.share,
                            onPressed: () =>
                                showShareSheet(context, me ?? '', place),
                            child: const Icon(
                              Icons.ios_share_rounded,
                              size: 20,
                              color: _onGlass,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          _GlassButton(
                            label: l10n.morePlaceActions,
                            onPressed: () => _more(context, ref, place),
                            child: const AppIcon('more', color: _onGlass),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 48,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CategoryChip(category: place.category),
                          const SizedBox(height: 10),
                          Text(
                            place.title,
                            style: AppText.display(color: Colors.white)
                                .copyWith(
                                  fontSize: 32,
                                  height: 1.1,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          if (location != null &&
                              location.cityCountry.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const AppIcon(
                                  'pin_small',
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    location.cityCountry,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(
                                      color: Colors.white.withValues(
                                        alpha: .92,
                                      ),
                                    ).copyWith(fontSize: 14),
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
              Padding(
                padding: const EdgeInsets.only(top: sheetTop),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Fact(
                              label: l10n.factSaved,
                              value: DateFormat.MMMd(l10n.localeName)
                                  .format(place.createdAt),
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: _Fact(
                              label: l10n.factPhotos,
                              value: '${place.photos.length}',
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: _Fact(
                              label: l10n.factVisibleTo,
                              value: l10n.visibleToEveryone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      _NoteCard(
                        note: place.note,
                        onEdit: () => _edit(context, place),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      if (location != null)
                        _LocationCard(
                          location: location,
                          category: place.category,
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
                                  l10n.noLocationYet,
                                  style: AppText.meta(),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 20,
                top: sheetTop - 28,
                child: _SavedHeart(
                  label: l10n.removeFromMyPlaces,
                  onPressed: () => _remove(context, ref, place),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dark icons on the cream glass circles over the photo.
const _onGlass = Color(0xFF15171C);

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.label,
    required this.onPressed,
    required this.child,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: const Color(0xD1FFFBE6),
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(dimension: 44, child: Center(child: child)),
          ),
        ),
      ),
    ),
  );
}

/// "☕ Café" on cream over the photo.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final PlaceCategory category;

  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
    decoration: BoxDecoration(
      color: const Color(0xEBFFFBE6),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(category.icon, size: 16, color: _green),
        const SizedBox(width: 6),
        Text(
          category.label(context.l10n),
          style: AppText.label(color: _green).copyWith(fontSize: 13),
        ),
      ],
    ),
  );
}

/// The palette's deep green, on the light chip whatever the theme.
const _green = Color(0xFF2A7C13);

/// The big green heart on the sheet's edge: saved; tap to remove.
class _SavedHeart extends StatelessWidget {
  const _SavedHeart({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: .35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: AppColors.accent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 56,
            child: Icon(
              Icons.favorite_rounded,
              size: 26,
              color: AppColors.onAccent,
            ),
          ),
        ),
      ),
    ),
  );
}

/// One quick fact on peach: "SAVED / Nov 12".
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.overline(color: AppColors.muted)
              .copyWith(fontSize: 11, letterSpacing: 0.6),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.bodyStrong().copyWith(fontSize: 15),
        ),
      ],
    ),
  );
}

/// "MY LITTLE NOTE" with an edit button, the note as a quote beside a green
/// bar. With no note yet, the edit button still invites one.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onEdit});

  final String note;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 4, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: const Color(0xFF76C457), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.myLittleNote,
                  style: AppText.overline(color: AppColors.muted)
                      .copyWith(fontSize: 11, letterSpacing: 0.6),
                ),
              ),
              IconButton(
                tooltip: l10n.editPlace,
                onPressed: onEdit,
                icon: AppIcon('edit', size: 18, color: AppColors.accent),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              note.isEmpty ? l10n.editPlace : '“$note”',
              style: AppText.note(
                color: note.isEmpty ? AppColors.muted : AppColors.inkSoft,
              ).copyWith(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.category,
    required this.onOpen,
  });

  final PlaceLocation location;
  final PlaceCategory category;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final address = [
      location.street,
      location.cityCountry,
    ].where((part) => part.isNotEmpty).join(', ');
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 92,
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
                          width: CategoryPin.size,
                          height: CategoryPin.size,
                          child: CategoryPin(
                            category: category,
                            selected: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.areaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyStrong().copyWith(fontSize: 15),
                        ),
                        if (address.isNotEmpty)
                          Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.meta().copyWith(fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  PillButton(
                    label: l10n.directions,
                    icon: Icons.north_east_rounded,
                    onPressed: onOpen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardAll,
      ),
      child: child,
    );
  }
}
