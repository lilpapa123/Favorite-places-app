import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:favorite_places/data/sample_posts.dart';
import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/screens/palces.dart';
import 'package:favorite_places/screens/profile.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/category_chips.dart';
import 'package:favorite_places/widgets/cover_post_card.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/search_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped when the Discover tab is tapped while already open: Discover then
/// scrolls to the top and refreshes.
class DiscoverRefresh extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final discoverRefreshProvider = NotifierProvider<DiscoverRefresh, int>(
  DiscoverRefresh.new,
);

/// [ids] in a new random order, never the same order as before when there
/// are two or more.
@visibleForTesting
List<String> reshuffle(List<String> ids, [Random? random]) {
  final shuffled = [...ids]..shuffle(random);
  if (shuffled.length > 1 && listEquals(shuffled, ids)) {
    shuffled.add(shuffled.removeAt(0));
  }
  return shuffled;
}

/// The first tab: favorite places everyone shares, newest first. Search and
/// type filters open from the search icon. A card opens the person who shared it.
/// Pull down (or tap the tab again) to refresh: new posts come first; with
/// none, the same posts come back in another order.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refresher = GlobalKey();
  PlaceCategory? _filter;

  /// Place ids in their shuffled order; null shows the newest first.
  List<String>? _order;

  /// Place ids already shown at the last refresh, to tell if any are new.
  Set<String>? _seen;

  Future<void> _refresh() async {
    // Ask the server, not the phone's cache, so the spinner lasts as long
    // as the connection takes; offline, say so and keep what is shown.
    if (ref.read(authStateProvider).value != null) {
      final messenger = ScaffoldMessenger.of(context);
      final noConnection = context.l10n.noConnection;
      try {
        await ref
            .read(firestoreProvider)
            .collection('places')
            .orderBy('createdAt', descending: true)
            .limit(ref.read(discoverLimitProvider))
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 15));
      } catch (_) {
        messenger.showSnackBar(SnackBar(content: Text(noConnection)));
        return;
      }
    }
    ref.invalidate(discoverProvider);
    final List<(String, Place)> posts;
    try {
      posts = await ref.read(discoverProvider.future);
    } catch (_) {
      return; // Offline: keep what is on screen.
    }
    if (!mounted) {
      return;
    }
    final ids = [for (final (_, place) in posts) place.id];
    final seen = _seen;
    final hasNew = seen != null && ids.any((id) => !seen.contains(id));
    setState(() {
      _order = hasNew ? null : reshuffle(ids);
      _seen = ids.toSet();
    });
  }

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
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final signedIn = ref.watch(authStateProvider).value != null;
    ref.listen(discoverRefreshProvider, (_, _) {
      if (_scroll.hasClients) {
        _scroll.animateTo(0, duration: AppMotion.fast, curve: AppMotion.ease);
      }
      _refresher.currentState?.show();
    });
    final newest = ref.watch(discoverProvider).value ?? const [];
    if (newest.isNotEmpty) {
      _seen ??= {for (final (_, place) in newest) place.id};
    }
    // Posts that arrived after a shuffle go on top, newest first.
    final rank = {for (final (i, id) in (_order ?? const []).indexed) id: i};
    final shared = rank.isEmpty
        ? newest
        : [
            for (final e in newest)
              if (!rank.containsKey(e.$2.id)) e,
            ...[
              for (final e in newest)
                if (rank.containsKey(e.$2.id)) e,
            ]..sort((a, b) => rank[a.$2.id]!.compareTo(rank[b.$2.id]!)),
          ];
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
        // Near the end of the list, ask for the next page of places.
        child: RefreshIndicator(
          key: _refresher,
          onRefresh: _refresh,
          color: AppColors.accent,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 800) {
                ref
                    .read(discoverLimitProvider.notifier)
                    .more(shared.where((e) => !isSampleUid(e.$1)).length);
              }
              return false;
            },
            child: ListView(
              controller: _scroll,
              // Pull to refresh works even when the list is short.
              physics: const AlwaysScrollableScrollPhysics(),
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
        ),
      ),
    );
  }
}
