import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/models/place.dart';
import 'package:flutter/widgets.dart';

export 'package:favorite_places/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension PlaceCategoryL10n on PlaceCategory {
  String label(AppLocalizations l10n) => switch (this) {
    PlaceCategory.cafe => l10n.categoryCafe,
    PlaceCategory.viewpoint => l10n.categoryViewpoint,
    PlaceCategory.walk => l10n.categoryWalk,
    PlaceCategory.hike => l10n.categoryHike,
    PlaceCategory.nature => l10n.categoryNature,
    PlaceCategory.beach => l10n.categoryBeach,
    PlaceCategory.camping => l10n.categoryCamping,
    PlaceCategory.night => l10n.categoryNight,
    PlaceCategory.other => l10n.categoryOther,
  };

  String plural(AppLocalizations l10n) => switch (this) {
    PlaceCategory.cafe => l10n.categoryCafePlural,
    PlaceCategory.viewpoint => l10n.categoryViewpointPlural,
    PlaceCategory.walk => l10n.categoryWalkPlural,
    PlaceCategory.hike => l10n.categoryHikePlural,
    PlaceCategory.nature => l10n.categoryNaturePlural,
    PlaceCategory.beach => l10n.categoryBeachPlural,
    PlaceCategory.camping => l10n.categoryCampingPlural,
    PlaceCategory.night => l10n.categoryNightPlural,
    PlaceCategory.other => l10n.categoryOtherPlural,
  };
}
