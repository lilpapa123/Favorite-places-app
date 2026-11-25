import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/screens/palces.dart';
import 'package:favorite_places/screens/profile.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/category_chips.dart';
import 'package:favorite_places/widgets/cover_post_card.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first tab: favorite places everyone shares, newest first. Search and
/// type filters open from the search icon. A card opens the person who shared it.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _search = TextEditingController();
  PlaceCategory? _filter;

  /// The search bar is open; closing it clears the search and filter.
  bool _searching = false;

  /// While the filter sheet is up, taps on it are not "outside" the bar.
  bool _filtersOpen = false;

  /// A tap outside the bar closes it when there is nothing to search for;
  /// with text or a filter, it only hides the keyboard so the results stay.
  void _tapOutside() {
    FocusScope.of(context).unfocus();
    if (!_filtersOpen && _filter == null && _search.text.trim().isEmpty) {
      setState(() => _searching = false);
    }
  }

  /// Type filters, chosen from the search bar.
  void _showFilters(List<PlaceCategory> filters, int total) {
    final l10n = context.l10n;
    // Else the keyboard comes back when the sheet closes.
    FocusScope.of(context).unfocus();
    _filtersOpen = true;
    showModalBottomSheet<void>(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.filterPlaces, style: AppText.title()),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  ChoicePill(
                    label: l10n.allCount(total),
                    selected: _filter == null,
                    background: AppColors.background,
                    onTap: () {
                      setState(() => _filter = null);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  for (final category in filters)
                    ChoicePill(
                      label: category.plural(l10n),
                      selected: _filter == category,
                      background: AppColors.background,
                      onTap: () {
                        setState(
                          () => _filter = _filter == category ? null : category,
                        );
                        Navigator.of(ctx).pop();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => _filtersOpen = false);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final signedIn = ref.watch(authStateProvider).value != null;
    final shared = ref.watch(discoverProvider).value ?? const [];
    final query = _search.text.trim().toLowerCase();
    final visible = [
      for (final entry in shared)
        if ((_filter == null || entry.$2.category == _filter) &&
            (query.isEmpty || entry.$2.matches(query)))
          entry,
    ];
    final filters = [
      for (final c in PlaceCategory.values)
        if (c.index < 3 || shared.any((e) => e.$2.category == c)) c,
    ];

    Widget message(String title, String body) => Padding(
      padding: const EdgeInsets.all(AppSpace.page),
      child: Column(
        children: [
          const SizedBox(height: AppSpace.xxxl),
          Text(title, style: AppText.title(), textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.xs),
          Text(body, style: AppText.meta(), textAlign: TextAlign.center),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            PageHeader(
              title: l10n.tabDiscover,
              subtitle: l10n.discoverSubtitle,
              trailing: shared.isEmpty || _searching
                  ? null
                  : CircleIconButton(
                      icon: const AppIcon('search'),
                      semanticLabel: l10n.findFavoritePlace,
                      onPressed: () => setState(() => _searching = true),
                    ),
            ),
            if (!signedIn && shared.isEmpty)
              message(l10n.tabDiscover, l10n.signInForDiscover)
            else if (shared.isEmpty)
              message(l10n.discoverEmptyTitle, l10n.discoverEmptyBody)
            else ...[
              AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.fast,
                curve: AppMotion.ease,
                alignment: Alignment.topCenter,
                child: !_searching
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.page,
                        ),
                        child: TapRegion(
                          onTapOutside: (_) => _tapOutside(),
                          child: SearchField(
                            controller: _search,
                            hintText: l10n.findFavoritePlace,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            trailing: IconButton(
                              tooltip: l10n.filterPlaces,
                              onPressed: () =>
                                  _showFilters(filters, shared.length),
                              // Orange while a filter is on.
                              icon: AppIcon(
                                'sliders',
                                color: _filter == null
                                    ? null
                                    : AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpace.lg),
              if (visible.isEmpty)
                NoMatches(
                  onClear: () => setState(() {
                    _filter = null;
                    _search.clear();
                  }),
                ),
              for (final (owner, place) in visible)
                CoverPostCard(
                  key: ValueKey(place.id),
                  owner: owner,
                  place: place,
                  onTap: () => openProfile(context, owner),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
