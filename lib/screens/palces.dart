import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/category_chips.dart';
import 'package:favorite_places/widgets/empty_places.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/palces_list.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _SortOrder {
  newest('Newest first'),
  oldest('Oldest first'),
  name('Name, A to Z');

  const _SortOrder(this.label);
  final String label;
}

/// The "My places" tab: search, type filters, sort, and the feed.
class PalcesScreen extends ConsumerStatefulWidget {
  const PalcesScreen({super.key, this.onAddPlace});

  /// Opens the add form (the shell switches pages).
  final VoidCallback? onAddPlace;

  @override
  ConsumerState<PalcesScreen> createState() => _PalcesScreenState();
}

class _PalcesScreenState extends ConsumerState<PalcesScreen> {
  final TextEditingController _search = TextEditingController();
  PlaceCategory? _filter;
  _SortOrder _sort = _SortOrder.newest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Place> _visible(List<Place> places) {
    final query = _search.text.trim().toLowerCase();
    final result = places.where((place) {
      if (_filter != null && place.category != _filter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final location = place.location;
      return place.title.toLowerCase().contains(query) ||
          place.note.toLowerCase().contains(query) ||
          (location != null &&
              '${location.title} ${location.areaLabel} ${location.city}'
                  .toLowerCase()
                  .contains(query));
    }).toList();

    switch (_sort) {
      case _SortOrder.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortOrder.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortOrder.name:
        result.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return result;
  }

  Future<void> _chooseSort() async {
    final choice = await showModalBottomSheet<_SortOrder>(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sort places', style: AppText.title()),
              const SizedBox(height: AppSpace.sm),
              for (final order in _SortOrder.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(order.label, style: AppText.row()),
                  trailing: order == _sort
                      ? const Icon(Icons.check, color: AppColors.accent)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(order),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice != null) {
      setState(() => _sort = choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(userPlacesProvider);
    final visible = _visible(places);
    final count = places.length;
    final filters = [
      PlaceCategory.cafe,
      PlaceCategory.viewpoint,
      PlaceCategory.walk,
      if (places.any((p) => p.category == PlaceCategory.other))
        PlaceCategory.other,
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'My places',
              subtitle:
                  '$count ${count == 1 ? 'favorite place' : 'favorite places'}',
              trailing: CircleIconButton(
                icon: const AppIcon('sliders'),
                semanticLabel: 'Sort places',
                onPressed: _chooseSort,
              ),
            ),
            if (places.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
                child: SearchField(
                  controller: _search,
                  hintText: 'Find a favorite place',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.page,
                  ),
                  children: [
                    ChoicePill(
                      label: 'All · $count',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final category in filters) ...[
                      const SizedBox(width: AppSpace.sm),
                      ChoicePill(
                        label: category.plural,
                        selected: _filter == category,
                        onTap: () => setState(
                          () => _filter = _filter == category ? null : category,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
            ],
            Expanded(
              child: places.isEmpty
                  ? EmptyPlaces(onAdd: widget.onAddPlace)
                  : visible.isEmpty
                  ? _NoMatches(
                      onClear: () => setState(() {
                        _filter = null;
                        _search.clear();
                      }),
                    )
                  : PalcesList(places: visible),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No places match', style: AppText.title()),
            const SizedBox(height: AppSpace.xs),
            Text('Try another word or type.', style: AppText.meta()),
            const SizedBox(height: AppSpace.lg),
            PillButton(
              label: 'Show all places',
              variant: PillButtonVariant.outlined,
              onPressed: onClear,
            ),
          ],
        ),
      ),
    );
  }
}
