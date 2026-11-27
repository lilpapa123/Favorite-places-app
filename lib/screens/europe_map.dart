import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/europe_map.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/screens/places_detail.dart';
import 'package:favorite_places/screens/profile.dart';
import 'package:favorite_places/services/region_tracker.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_map.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One person's places on the design's drawn Europe map: countries they
/// have been to in light green, regions with a saved place in deep green
/// and regions they have only been to (from their phone's location) in a
/// lighter green, a pin per place, and how much of Europe that is. Opening
/// your own map marks the region you are in. Drawn from a bundled asset, so it
/// needs no map service. Pinch to zoom; tap a pin for its name, tap the name
/// to open the place.
class EuropeMapScreen extends ConsumerStatefulWidget {
  const EuropeMapScreen({super.key, required this.uid});

  final String uid;

  @override
  ConsumerState<EuropeMapScreen> createState() => _EuropeMapScreenState();
}

class _EuropeMapScreenState extends ConsumerState<EuropeMapScreen> {
  final TransformationController _zoom = TransformationController();
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markHere());
  }

  /// On your own map, marks the region you are in and says so when new.
  Future<void> _markHere() async {
    final me = ref.read(authStateProvider).value?.uid;
    if (me == null || me != widget.uid) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final map = await ref.read(europeMapProvider.future);
    final profile = await ref.read(profileProvider(me).future);
    final country = await markCurrentRegion(
      map: map,
      social: ref.read(socialProvider),
      uid: me,
      known: profile?.visitedRegions ?? const {},
      ask: true,
    );
    if (country != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.newRegion(country.name))),
      );
    }
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _open(Place place, bool mine) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => mine
            ? PlacesDetailScreen(placeId: place.id)
            : PostScreen(owner: widget.uid, place: place),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(authStateProvider).value?.uid;
    final mine = widget.uid == me;
    // Yours include places not synced yet.
    final places = mine
        ? ref.watch(userPlacesProvider)
        : ref.watch(placesOfUserProvider(widget.uid)).value ?? const [];
    final profile = ref.watch(profileProvider(widget.uid)).value;
    final name = profile?.name ?? '';
    final been = profile?.visitedRegions ?? const <String>{};
    final map = ref.watch(europeMapProvider).value;
    final dark = AppColors.isDark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [Color(0xFF0E1A2B), Color(0xFF132239)]
                : const [Color(0xFFDCEAD3), Color(0xFFE9F1DE)],
          ),
        ),
        child: map == null
            ? const SizedBox.expand()
            : LayoutBuilder(
                builder: (context, box) {
                  final visit = _Visit.of(map, places, been);
                  // The artboard fills the width; its map band stays centred.
                  final scale = box.maxWidth / map.size.width;
                  final top = (box.maxHeight - map.size.height * scale) / 2;
                  Offset toScreen(Offset p) =>
                      Offset(p.dx * scale, top + p.dy * scale);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: InteractiveViewer(
                          transformationController: _zoom,
                          maxScale: 6,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _selectedId = null),
                            child: RepaintBoundary(
                              child: CustomPaint(
                                size: box.biggest,
                                isComplex: true,
                                painter: _EuropePainter(
                                  map: map,
                                  visit: visit,
                                  scale: scale,
                                  top: top,
                                  dark: dark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Pins stay the same size while the map zooms.
                      AnimatedBuilder(
                        animation: _zoom,
                        builder: (context, _) => Stack(
                          children: [
                            for (final (place, point) in visit.pins)
                              _pin(
                                place,
                                MatrixUtils.transformPoint(
                                  _zoom.value,
                                  toScreen(point),
                                ),
                                mine,
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        top: MediaQuery.paddingOf(context).top + 8,
                        child: _Header(
                          subtitle: mine
                              ? l10n.europeSubtitleMine
                              : l10n.europeSubtitleOf(name),
                        ),
                      ),
                      Positioned(
                        left: AppSpace.page - 4,
                        right: AppSpace.page - 4,
                        bottom: bottomBarClearance(context) + 52,
                        child: _Progress(map: map, visit: visit),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _pin(Place place, Offset at, bool mine) {
    const size = 34.0;
    final selected = place.id == _selectedId;
    return Positioned(
      left: at.dx - 90,
      top: at.dy - size / 2,
      width: 180,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: size,
            child: CategoryPin(
              category: place.category,
              selected: selected,
              semanticLabel: place.title,
              onTap: () =>
                  setState(() => _selectedId = selected ? null : place.id),
            ),
          ),
          if (selected) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _open(place, mine),
              child: Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: .95),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F000000), blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        place.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.labelMedium(
                          color: AppColors.ink,
                        ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AppIcon('arrow_right', size: 14, color: AppColors.accent),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Where one person's places and visits fall on the map.
class _Visit {
  _Visit._(
    this.pins,
    this.countries,
    this.saved,
    this.been,
    this.placesInEurope,
  );

  factory _Visit.of(EuropeMap map, List<Place> places, Set<String> beenKeys) {
    final pins = <(Place, Offset)>[];
    final countries = <MapCountry>{};
    final saved = <MapCountry, Set<int>>{};
    var inEurope = 0;
    final bounds = Offset.zero & map.size;
    for (final place in places) {
      final location = place.location;
      if (location == null) {
        continue;
      }
      final point = map.project(location.latitude, location.longitude);
      if (!bounds.contains(point)) {
        continue;
      }
      pins.add((place, point));
      final country = map.countryAt(point);
      if (country == null) {
        continue;
      }
      countries.add(country);
      final region = country.regionAt(point);
      if (region != null) {
        inEurope++;
        saved.putIfAbsent(country, () => {}).add(region);
      }
    }
    // Regions from the phone's location, unless a saved place covers them.
    final been = <MapCountry, Set<int>>{};
    for (final country in map.countries) {
      for (var i = 0; i < country.regions.length; i++) {
        if (beenKeys.contains(country.regionKey(i)) &&
            !(saved[country]?.contains(i) ?? false)) {
          been.putIfAbsent(country, () => {}).add(i);
          countries.add(country);
        }
      }
    }
    return _Visit._(pins, countries, saved, been, inEurope);
  }

  final List<(Place, Offset)> pins;

  /// Countries with a place or a visit.
  final Set<MapCountry> countries;

  /// Regions with a saved place, by country.
  final Map<MapCountry, Set<int>> saved;

  /// Regions only been to, by country.
  final Map<MapCountry, Set<int>> been;

  /// Places that landed in one of the regions.
  final int placesInEurope;

  int get regionCount =>
      [...saved.values, ...been.values].fold(0, (sum, r) => sum + r.length);

  /// Countries with a place or visit that are split into regions, for the
  /// chips.
  List<MapCountry> get europeanCountries => [
    for (final c in countries)
      if (c.regions.isNotEmpty) c,
  ];
}

class _EuropePainter extends CustomPainter {
  _EuropePainter({
    required this.map,
    required this.visit,
    required this.scale,
    required this.top,
    required this.dark,
  });

  final EuropeMap map;
  final _Visit visit;
  final double scale;
  final double top;
  final bool dark;

  // The design's day and night colours.
  Color get _land => dark ? const Color(0xFF233451) : const Color(0xFFFFF6DA);
  Color get _visited =>
      dark ? const Color(0xFF24502A) : const Color(0xFFB9DFA3);
  static const _region = Color(0xFF4E9E33);
  Color get _beenRegion => _EuropeColors.been(dark);
  Color get _cellLine =>
      dark ? const Color(0x29FFFFFF) : const Color(0xFFEADBB3);
  Color get _visitedCellLine =>
      dark ? const Color(0x8C0E1A2B) : const Color(0xD9FFFBE6);
  Color get _border => dark ? const Color(0xFF0E1A2B) : const Color(0xFFE3CFA2);
  Color get _graticule =>
      dark ? const Color(0x0DFFFFFF) : const Color(0x142A7C13);

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(0, top)
      ..scale(scale);
    final stroke = Paint()..style = PaintingStyle.stroke;
    canvas.drawPath(
      map.graticule,
      stroke
        ..color = _graticule
        ..strokeWidth = 0.8,
    );
    final fill = Paint();
    for (final country in map.countries) {
      final visited = visit.countries.contains(country);
      canvas.drawPath(country.shape, fill..color = visited ? _visited : _land);
      if (country.regions.isEmpty) {
        continue;
      }
      canvas
        ..save()
        ..clipPath(country.shape);
      for (final i in visit.saved[country] ?? const <int>{}) {
        canvas.drawPath(country.regions[i], fill..color = _region);
      }
      for (final i in visit.been[country] ?? const <int>{}) {
        canvas.drawPath(country.regions[i], fill..color = _beenRegion);
      }
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = visited ? _visitedCellLine : _cellLine;
      for (final cell in country.regions) {
        canvas.drawPath(cell, line);
      }
      canvas.restore();
    }
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeJoin = StrokeJoin.round
      ..color = _border;
    for (final country in map.countries) {
      canvas.drawPath(country.shape, border);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EuropePainter old) =>
      old.visit != visit ||
      old.scale != scale ||
      old.top != top ||
      old.dark != dark ||
      old.map != map;
}

class _EuropeColors {
  /// Regions only been to: a lighter green than regions with a saved place.
  static Color been(bool dark) => const Color(0xFF80C162);
}

BoxDecoration _frosted() => BoxDecoration(
  color: AppColors.surface.withValues(alpha: .86),
  borderRadius: BorderRadius.circular(22),
  border: Border.all(
    color: Colors.white.withValues(alpha: AppColors.isDark ? .08 : .8),
  ),
  boxShadow: [
    BoxShadow(
      color: AppColors.isDark
          ? const Color(0x66000000)
          : const Color(0x38B98E7A),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ],
);

class _Header extends StatelessWidget {
  const _Header({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
      decoration: _frosted(),
      child: Row(
        children: [
          CircleIconButton(
            icon: AppIcon('back', color: AppColors.ink),
            semanticLabel: l10n.back,
            background: AppColors.accentSoft,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.europeTitle,
                  style: AppText.heading().copyWith(fontSize: 24, height: 1.2),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelMedium(color: AppColors.muted)
                      .copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.map, required this.visit});

  final EuropeMap map;
  final _Visit visit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = map.regionCount;
    final done = visit.regionCount;
    final chips = visit.europeanCountries;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _frosted(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$done',
                style: AppText.stat().copyWith(fontSize: 30, height: 1),
              ),
              const SizedBox(width: 8),
              Text(l10n.regionsOf(total), style: AppText.bodyStrong()),
              const Spacer(),
              Text(
                l10n.countriesAndPlaces(chips.length, visit.placesInEurope),
                style: AppText.labelMedium(color: AppColors.muted)
                    .copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppColors.isDark
                          ? Colors.white.withValues(alpha: .10)
                          : AppColors.accent.withValues(alpha: .12),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: total == 0 ? 0 : (done / total).clamp(0, 1),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2A7C13), Color(0xFF76C457)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LegendDot(
                color: const Color(0xFF4E9E33),
                label: l10n.legendSaved,
              ),
              const SizedBox(width: 16),
              _LegendDot(
                color: _EuropeColors.been(AppColors.isDark),
                label: l10n.legendBeen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (chips.isEmpty)
            Text(
              l10n.europeEmpty,
              style: AppText.labelMedium(color: AppColors.muted),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final country in chips)
                  Tooltip(
                    message: country.name,
                    child: Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: BoxDecoration(
                        color: AppColors.isDark
                            ? const Color(0xFF233451)
                            : AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          country.code,
                          style: AppText.labelMedium(color: AppColors.accent)
                              .copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .5,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.labelMedium(color: AppColors.muted)
              .copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

/// The way into someone's Europe map: a round map button beside their name
/// in the account details.
class EuropeMapButton extends StatelessWidget {
  const EuropeMapButton({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    // The design's Globe icon, swapped for contrast: navy sea on the light
    // theme, green sea on the dark one.
    return Semantics(
      button: true,
      label: context.l10n.europeMap,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => EuropeMapScreen(uid: uid)),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: AppIcon(
            AppColors.isDark ? 'globe_day' : 'globe_night',
            size: 48,
          ),
        ),
      ),
    );
  }
}
