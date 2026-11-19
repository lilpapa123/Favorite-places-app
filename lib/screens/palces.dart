import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/screens/add_place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/ascii_button.dart';
import 'package:favorite_places/widgets/blinking_cursor.dart';
import 'package:favorite_places/widgets/palces_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PalcesScreen extends ConsumerWidget {
  const PalcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPlaces = ref.watch(userPlacesProvider);
    final int photoCount = userPlaces
        .where((place) => place.image != null)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('>', style: AsciiType.heading(color: AsciiPalette.accent)),
            const SizedBox(width: AsciiSpace.sm),
            Flexible(
              child: Text(
                'favorite_places',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AsciiType.heading(),
              ),
            ),
            const SizedBox(width: AsciiSpace.sm),
            const BlinkingCursor(height: 18),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(AsciiShape.borderWidth),
          child: Divider(),
        ),
      ),
      body: Column(
        children: [
          _StatusStrip(placeCount: userPlaces.length, photoCount: photoCount),
          Expanded(child: PalcesList(places: userPlaces)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AsciiPalette.canvas,
            border: Border(
              top: BorderSide(
                color: AsciiPalette.line,
                width: AsciiShape.borderWidth,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AsciiSpace.lg,
            AsciiSpace.md,
            AsciiSpace.lg,
            AsciiSpace.md,
          ),
          child: AsciiButton(
            label: 'add place',
            icon: Icons.add,
            expanded: true,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (ctx) => const AddedPlaceScreen(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.placeCount, required this.photoCount});

  final int placeCount;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AsciiSpace.lg,
        vertical: AsciiSpace.sm,
      ),
      decoration: const BoxDecoration(
        color: AsciiPalette.surface,
        border: Border(
          bottom: BorderSide(
            color: AsciiPalette.line,
            width: AsciiShape.borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              '// $placeCount ${placeCount == 1 ? 'entry' : 'entries'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AsciiType.meta(),
            ),
          ),
          const SizedBox(width: AsciiSpace.md),
          Text(
            '$photoCount ${photoCount == 1 ? 'photo' : 'photos'}',
            style: AsciiType.meta(color: AsciiPalette.accent),
          ),
          const Spacer(),
          const Icon(
            Icons.folder_open_outlined,
            size: 14,
            color: AsciiPalette.mute,
          ),
        ],
      ),
    );
  }
}
