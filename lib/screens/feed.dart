import 'dart:async';

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/screens/profile.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/place_card.dart';
import 'package:favorite_places/widgets/search_field.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void _openSearch(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (ctx) => const PeopleSearchScreen()));

/// The Feed tab: newest places from the people you follow.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final signedIn = ref.watch(authStateProvider).value != null;
    final feed = ref.watch(feedProvider).value ?? const [];

    Widget message(String title, String body, {bool search = false}) => Padding(
      padding: const EdgeInsets.all(AppSpace.page),
      child: Column(
        children: [
          const SizedBox(height: AppSpace.xxxl),
          Text(title, style: AppText.title(), textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.xs),
          Text(body, style: AppText.meta(), textAlign: TextAlign.center),
          if (search) ...[
            const SizedBox(height: AppSpace.lg),
            PillButton(
              label: l10n.findPeople,
              onPressed: () => _openSearch(context),
            ),
          ],
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
          children: [
            PageHeader(
              title: l10n.tabFeed,
              subtitle: l10n.feedSubtitle,
              trailing: signedIn
                  ? CircleIconButton(
                      icon: const AppIcon('search'),
                      semanticLabel: l10n.findPeople,
                      onPressed: () => _openSearch(context),
                    )
                  : null,
            ),
            if (!signedIn)
              message(l10n.tabFeed, l10n.signInForFeed)
            else if (feed.isEmpty)
              message(l10n.feedEmptyTitle, l10n.feedEmptyBody, search: true)
            else
              for (final (owner, place) in feed)
                Padding(
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
        ),
      ),
    );
  }
}

/// Search people by @username or name.
class PeopleSearchScreen extends ConsumerStatefulWidget {
  const PeopleSearchScreen({super.key});

  @override
  ConsumerState<PeopleSearchScreen> createState() => _PeopleSearchState();
}

class _PeopleSearchState extends ConsumerState<PeopleSearchScreen> {
  final TextEditingController _query = TextEditingController();
  Timer? _debounce;
  List<UserProfile> _results = const [];
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final me = ref.read(authStateProvider).value?.uid;
      try {
        final results = await ref
            .read(socialProvider)
            .search(text, exclude: me);
        if (mounted && text == _query.text) {
          setState(() {
            _results = results;
            _searched = text.trim().isNotEmpty;
          });
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.somethingWentWrong)),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            PageHeader(
              title: l10n.findPeople,
              trailing: CircleIconButton(
                icon: const AppIcon('close'),
                semanticLabel: l10n.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                0,
                AppSpace.page,
                AppSpace.md,
              ),
              child: SearchField(
                controller: _query,
                hintText: l10n.searchPeopleHint,
                autofocus: true,
                onChanged: _onChanged,
              ),
            ),
            if (_searched && _results.isEmpty)
              Center(child: Text(l10n.noPeopleFound, style: AppText.meta())),
            for (final p in _results) PersonTile(profile: p),
          ],
        ),
      ),
    );
  }
}
