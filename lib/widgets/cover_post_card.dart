import 'dart:ui';

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/place_photo.dart';
import 'package:favorite_places/widgets/post_sheets.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A shared place as a magazine cover (Discover): the photos edge to edge,
/// swiped sideways, with the type and a big headline on top and who shared
/// it at the bottom; the note follows as a quote.
class CoverPostCard extends StatelessWidget {
  const CoverPostCard({
    super.key,
    required this.owner,
    required this.place,
    this.onTap,
  });

  final String owner;
  final Place place;

  /// Null on the post's own screen, where there's nothing more to open.
  final VoidCallback? onTap;

  /// Light coral: the accent is too dark to read on a photo.
  static const Color _kickerOnPhoto = Color(0xFFFFB199);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final area = place.location?.areaLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: onTap != null,
            label: place.title,
            child: GestureDetector(
              onTap: onTap,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlacePhotos(
                      photos: place.photos,
                      tint: AppColors.tintFor(place.id),
                      iconSize: 40,
                    ),
                    // Dark at the top for the headline and at the bottom for
                    // the person, clear in the middle.
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0, 0.35, 0.7, 1],
                            colors: [
                              Color(0xAA000000),
                              Color(0x00000000),
                              Color(0x00000000),
                              Color(0xAA000000),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpace.page,
                      right: AppSpace.page,
                      top: AppSpace.xl,
                      child: IgnorePointer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              upperCaseFor(
                                l10n.localeName,
                                place.category.label(l10n),
                              ),
                              style: AppText.overline(color: _kickerOnPhoto),
                            ),
                            const SizedBox(height: AppSpace.xs),
                            Text(
                              place.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.display(color: Colors.white)
                                  .copyWith(fontSize: 34, height: 1.1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpace.page,
                      right: AppSpace.page,
                      bottom: 30,
                      child: Row(
                        children: [
                          Expanded(
                            child: IgnorePointer(
                              child: _Owner(
                                uid: owner,
                                details: [
                                  ?area,
                                  timeAgo(l10n, place.createdAt),
                                ].join(' · '),
                              ),
                            ),
                          ),
                          _PhotoAction(
                            icon: CupertinoIcons.chat_bubble,
                            label: l10n.comments,
                            onTap: () => showCommentsSheet(context, place),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          _PhotoAction(
                            icon: CupertinoIcons.paperplane,
                            label: l10n.share,
                            onTap: () => showShareSheet(context, owner, place),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (place.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.lg,
                AppSpace.page,
                0,
              ),
              child: Container(
                padding: const EdgeInsetsDirectional.only(start: AppSpace.md),
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(color: AppColors.accent, width: 3),
                  ),
                ),
                child: Text(
                  '“${place.note}”',
                  style: AppText.body().copyWith(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A frosted glass circle with a white icon, over the photo.
class _PhotoAction extends StatelessWidget {
  const _PhotoAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: const Color(0x33FFFFFF),
          shape: const CircleBorder(side: BorderSide(color: Color(0x55FFFFFF))),
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: _size,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Avatar, name and [details] in white, over the photo.
class _Owner extends ConsumerWidget {
  const _Owner({required this.uid, required this.details});

  final String uid;
  final String details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(uid)).value;
    final name = profile?.name ?? '';
    return Row(
      children: [
        Avatar(name: name, photoUrl: profile?.photoUrl, size: 30),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyStrong(color: Colors.white),
              ),
              Text(
                details,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.meta(color: Colors.white70)
                    .copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "14h ago", "3d ago"… in the app's language.
String timeAgo(AppLocalizations l10n, DateTime time, {DateTime? now}) {
  final age = (now ?? DateTime.now()).difference(time);
  if (age.inDays >= 1) {
    return l10n.agoDays(age.inDays);
  }
  if (age.inHours >= 1) {
    return l10n.agoHours(age.inHours);
  }
  return l10n.agoMinutes(age.inMinutes.clamp(1, 59));
}

/// Upper case that keeps the Turkish dotted i: "Bisiklet" becomes
/// "BİSİKLET", not "BISIKLET".
String upperCaseFor(String localeName, String text) =>
    (localeName == 'tr' ? text.replaceAll('i', 'İ') : text).toUpperCase();
