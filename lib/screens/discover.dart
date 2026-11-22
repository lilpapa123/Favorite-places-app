import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/screens/palces.dart';
import 'package:favorite_places/screens/profile.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/category_chips.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/place_card.dart';
import 'package:favorite_places/widgets/search_field.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first tab: favorite places everyone shares, newest first, with search
/// and type filters. A card opens the person who shared it.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _search = TextEditingController();
  PlaceCategory? _filter;

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
            ),
            if (!signedIn && shared.isEmpty)
              message(l10n.tabDiscover, l10n.signInForDiscover)
            else if (shared.isEmpty)
              message(l10n.discoverEmptyTitle, l10n.discoverEmptyBody)
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
                child: SearchField(
                  controller: _search,
                  hintText: l10n.findFavoritePlace,
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
                      label: l10n.allCount(shared.length),
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final category in filters) ...[
                      const SizedBox(width: AppSpace.sm),
                      ChoicePill(
                        label: category.plural(l10n),
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
              if (visible.isEmpty)
                NoMatches(
                  onClear: () => setState(() {
                    _filter = null;
                    _search.clear();
                  }),
                ),
              for (final (owner, place) in visible)
                Padding(
                  key: ValueKey(place.id),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.page,
                    0,
                    AppSpace.page,
                    AppSpace.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OwnerRow(uid: owner),
                      const SizedBox(height: AppSpace.sm),
                      PlaceCard(
                        place: place,
                        onTap: () => openProfile(context, owner),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
