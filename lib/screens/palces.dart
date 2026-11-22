import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/screens/add_place.dart';
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
  newest,
  oldest,
  name;

  String label(AppLocalizations l10n) => switch (this) {
    newest => l10n.sortNewest,
    oldest => l10n.sortOldest,
    name => l10n.sortName,
  };
}

/// All of the user's own places, opened from Account: search, type filters,
/// sort, and the cards.
class PalcesScreen extends ConsumerStatefulWidget {
  const PalcesScreen({super.key, this.onAddPlace});

  /// Opens the add form; by default it opens as a page on top.
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
      return query.isEmpty || place.matches(query);
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
              Text(context.l10n.sortPlaces, style: AppText.title()),
              const SizedBox(height: AppSpace.sm),
              for (final order in _SortOrder.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(order.label(context.l10n), style: AppText.row()),
                  trailing: order == _sort
                      ? Icon(Icons.check, color: AppColors.accent)
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
    // The first three types always show; the rest once a place uses them.
    final filters = [
      for (final c in PlaceCategory.values)
        if (c.index < 3 || places.any((p) => p.category == c)) c,
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: context.l10n.tabMyPlaces,
              subtitle: context.l10n.favoritePlacesCount(count),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleIconButton(
                    icon: const AppIcon('sliders'),
                    semanticLabel: context.l10n.sortPlaces,
                    onPressed: _chooseSort,
                  ),
                  if (Navigator.of(context).canPop()) ...[
                    const SizedBox(width: AppSpace.sm),
                    CircleIconButton(
                      icon: const AppIcon('close'),
                      semanticLabel: context.l10n.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ],
              ),
            ),
            if (places.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
                child: SearchField(
                  controller: _search,
                  hintText: context.l10n.findFavoritePlace,
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
                      label: context.l10n.allCount(count),
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final category in filters) ...[
                      const SizedBox(width: AppSpace.sm),
                      ChoicePill(
                        label: category.plural(context.l10n),
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
                  ? EmptyPlaces(
                      onAdd:
                          widget.onAddPlace ??
                          () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (ctx) => const AddedPlaceScreen(),
                            ),
                          ),
                    )
                  : visible.isEmpty
                  ? NoMatches(
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

/// "No places match" with a button that clears the search and filter.
class NoMatches extends StatelessWidget {
  const NoMatches({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.noPlacesMatch, style: AppText.title()),
            const SizedBox(height: AppSpace.xs),
            Text(context.l10n.tryAnotherWord, style: AppText.meta()),
            const SizedBox(height: AppSpace.lg),
            PillButton(
              label: context.l10n.showAllPlaces,
              variant: PillButtonVariant.outlined,
              onPressed: onClear,
            ),
          ],
        ),
      ),
    );
  }
}
