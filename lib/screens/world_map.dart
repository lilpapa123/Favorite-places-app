import 'dart:math' as math;

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/world_map.dart';
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

/// One person's places on the design's drawn world map: countries they
/// have been to in light green, regions with a saved place in deep green
/// and regions they have only been to (from their phone's location) in a
/// lighter green, a pin per place, and how many of the world's countries
/// that is. It fills the screen and opens on Europe; pinch or drag to move.
/// Zoomed out, nearby pins join into one with a count. Opening your own map
/// marks the region you are in. Drawn from a bundled asset, so it needs no
/// map service. Tap a pin for its name, tap the name to open the place.
class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({super.key, required this.uid});

  final String uid;

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  final TransformationController _zoom = TransformationController();
  bool _placed = false;
  String? _selectedId;

  /// Below this zoom, nearby pins show as one, as in the design.
  static const double _clusterBelow = 1.8;

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
    final map = await ref.read(worldMapProvider.future);
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
    for (final name in _nameCache.values) {
      name.dispose();
    }
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

  /// Each country's name, laid out once per theme.
  final Map<String, TextPainter> _nameCache = {};
  bool? _namesDark;

  Map<String, TextPainter> _names(bool dark) {
    if (_namesDark != dark) {
      _namesDark = dark;
      for (final name in _nameCache.values) {
        name.dispose();
      }
      _nameCache.clear();
    }
    return _nameCache;
  }

  /// Zooms in twice as far around [at], to open a group of pins.
  void _zoomInAt(Offset at) {
    final factor = (10 / _zoom.value.getMaxScaleOnAxis()).clamp(1.0, 2.2);
    _zoom.value = Matrix4.translationValues(at.dx, at.dy, 0)
      ..multiply(Matrix4.diagonal3Values(factor, factor, 1))
      ..multiply(Matrix4.translationValues(-at.dx, -at.dy, 0))
      ..multiply(_zoom.value);
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
    final map = ref.watch(worldMapProvider).value;
    final dark = AppColors.isDark;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0E1A2B) : const Color(0xFFDCEAD3),
      body: map == null
          ? const SizedBox.expand()
          : LayoutBuilder(
              builder: (context, box) {
                final visit = _Visit.of(map, places, been);
                // The map fills the screen's height, as in the design.
                final scale = box.maxHeight / map.size.height;
                final content = map.size * scale;
                if (!_placed) {
                  _placed = true;
                  final x = math.min(
                    map.startX * scale,
                    math.max(0.0, content.width - box.maxWidth),
                  );
                  _zoom.value = Matrix4.translationValues(-x, 0, 0);
                }
                return Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        transformationController: _zoom,
                        constrained: false,
                        minScale: 1,
                        maxScale: 10,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _selectedId = null),
                          child: RepaintBoundary(
                            child: ValueListenableBuilder(
                              valueListenable: _zoom,
                              builder: (context, matrix, _) => CustomPaint(
                                size: content,
                                isComplex: true,
                                painter: _WorldPainter(
                                  map: map,
                                  visit: visit,
                                  scale: scale,
                                  // Lines stay thin as the map zooms; repainted
                                  // in steps, not on every frame.
                                  zoom:
                                      (matrix.getMaxScaleOnAxis() * 2).round() /
                                      2,
                                  dark: dark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Country names, sized for the screen, where they fit.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _NamesPainter(
                              map: map,
                              zoom: _zoom,
                              scale: scale,
                              names: _names(dark),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Pins stay the same size while the map zooms.
                    AnimatedBuilder(
                      animation: _zoom,
                      builder: (context, _) =>
                          Stack(children: _pins(visit, scale, mine)),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: MediaQuery.paddingOf(context).top + 8,
                      child: _Header(
                        title: name.isEmpty
                            ? l10n.worldTitleMine
                            : l10n.worldTitle(name),
                        subtitle: mine
                            ? l10n.worldSubtitleMine
                            : l10n.worldSubtitleOf,
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
    );
  }

  /// Each place's pin on screen; zoomed out, pins closer than a finger
  /// join into one that zooms in when tapped.
  List<Widget> _pins(_Visit visit, double scale, bool mine) {
    final matrix = _zoom.value;
    final points = [
      for (final (place, point) in visit.pins)
        (place, MatrixUtils.transformPoint(matrix, point * scale)),
    ];
    if (matrix.getMaxScaleOnAxis() >= _clusterBelow) {
      return [for (final (place, at) in points) _pin(place, at, mine)];
    }
    final groups = <List<(Place, Offset)>>[];
    for (final pin in points) {
      final near = groups.where((g) => (g.first.$2 - pin.$2).distance < 44);
      near.isEmpty ? groups.add([pin]) : near.first.add(pin);
    }
    return [
      for (final group in groups)
        group.length == 1
            ? _pin(group.first.$1, group.first.$2, mine)
            : _cluster(group),
    ];
  }

  Widget _cluster(List<(Place, Offset)> group) {
    final at =
        group.fold(Offset.zero, (sum, pin) => sum + pin.$2) /
        group.length.toDouble();
    const size = 34.0;
    return Positioned(
      left: at.dx - size / 2,
      top: at.dy - size / 2,
      child: Semantics(
        button: true,
        label: '${group.length}',
        child: GestureDetector(
          onTap: () => _zoomInAt(at),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF2A7C13),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 8),
              ],
            ),
            child: Text(
              '${group.length}',
              style: AppText.stat(color: Colors.white)
                  .copyWith(fontSize: 13, height: 1),
            ),
          ),
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
  _Visit._(this.pins, this.countries, this.saved, this.been);

  factory _Visit.of(WorldMap map, List<Place> places, Set<String> beenKeys) {
    final pins = <(Place, Offset)>[];
    final countries = <MapCountry>{};
    final saved = <MapCountry, Set<int>>{};
    for (final place in places) {
      final location = place.location;
      if (location == null) {
        continue;
      }
      final point = map.project(location.latitude, location.longitude);
      pins.add((place, point));
      final country = map.countryAt(point);
      if (country == null) {
        continue;
      }
      countries.add(country);
      final region = country.regionAt(point);
      if (region != null) {
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
    return _Visit._(pins, countries, saved, been);
  }

  final List<(Place, Offset)> pins;

  /// Countries with a place or a visit.
  final Set<MapCountry> countries;

  /// Regions with a saved place, by country.
  final Map<MapCountry, Set<int>> saved;

  /// Regions only been to, by country.
  final Map<MapCountry, Set<int>> been;

  int get regionCount =>
      [...saved.values, ...been.values].fold(0, (sum, r) => sum + r.length);

  /// The countries' codes, once each (Northern Cyprus counts as Cyprus).
  List<String> get codes => {for (final c in countries) c.code}.toList();
}

class _WorldPainter extends CustomPainter {
  _WorldPainter({
    required this.map,
    required this.visit,
    required this.scale,
    required this.zoom,
    required this.dark,
  });

  final WorldMap map;
  final _Visit visit;
  final double scale;
  final double zoom;
  final bool dark;

  // The design's day and night colours.
  Color get _land => dark ? const Color(0xFF233451) : const Color(0xFFFFF6DA);
  Color get _visited =>
      dark ? const Color(0xFF24502A) : const Color(0xFFB9DFA3);
  static const _region = Color(0xFF4E9E33);
  static const _beenRegion = _MapColors.been;
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
      ..scale(scale);
    // Strokes keep their on-screen width whatever the zoom.
    final hairline = 1 / (scale * zoom);
    canvas.drawPath(
      map.graticule,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _graticule
        ..strokeWidth = 0.6 * hairline,
    );
    final fill = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * hairline;
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
      line.color = visited ? _visitedCellLine : _cellLine;
      for (final cell in country.regions) {
        canvas.drawPath(cell, line);
      }
      canvas.restore();
    }
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7 * hairline
      ..strokeJoin = StrokeJoin.round;
    for (final country in map.countries) {
      border.color = visit.countries.contains(country) ? _region : _border;
      canvas.drawPath(country.shape, border);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WorldPainter old) =>
      old.visit != visit ||
      old.scale != scale ||
      old.zoom != zoom ||
      old.dark != dark ||
      old.map != map;
}

/// Country names over the map, at the same size whatever the zoom; a name
/// shows once its country is wide enough on screen and doesn't overlap a
/// bigger country's name.
class _NamesPainter extends CustomPainter {
  _NamesPainter({
    required this.map,
    required this.zoom,
    required this.scale,
    required this.names,
  }) : super(repaint: zoom);

  final WorldMap map;
  final TransformationController zoom;
  final double scale;
  final Map<String, TextPainter> names;

  /// Biggest first, so they win a spot over their small neighbours.
  late final List<MapCountry> _bySize = [...map.countries]
    ..sort((a, b) => b.labelWidth.compareTo(a.labelWidth));

  TextPainter _name(MapCountry country) => names[country.name] ??= TextPainter(
    text: TextSpan(
      text: country.name,
      style: AppText.labelMedium(
        color: AppColors.isDark
            ? const Color(0xB3F3EED6)
            : const Color(0xFF7A6A45),
      ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final matrix = zoom.value;
    final k = matrix.getMaxScaleOnAxis() * scale;
    final screen = Offset.zero & size;
    final taken = <Rect>[];
    for (final country in _bySize) {
      final width = country.labelWidth * k;
      if (width < 40) {
        break;
      }
      final at = MatrixUtils.transformPoint(matrix, country.label * scale);
      final name = _name(country);
      if (name.width + 8 > width) {
        continue;
      }
      final box = Rect.fromCenter(
        center: at,
        width: name.width + 6,
        height: name.height + 2,
      );
      // Whole names only: none cut off by the screen's edge.
      if (!screen.contains(box.topLeft) ||
          !screen.contains(box.bottomRight) ||
          taken.any(box.overlaps)) {
        continue;
      }
      taken.add(box);
      name.paint(canvas, at - Offset(name.width / 2, name.height / 2));
    }
  }

  @override
  bool shouldRepaint(_NamesPainter old) =>
      old.map != map || old.scale != scale || old.names != names;
}

class _MapColors {
  /// Regions only been to: a lighter green than regions with a saved place.
  static const been = Color(0xFF80C162);
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
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
      decoration: _frosted(),
      child: Row(
        children: [
          CircleIconButton(
            icon: AppIcon('back', color: AppColors.ink),
            semanticLabel: context.l10n.back,
            background: AppColors.accentSoft,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  final WorldMap map;
  final _Visit visit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = map.total;
    final chips = visit.codes;
    final done = chips.length;
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
              Text(l10n.countriesOf(total), style: AppText.bodyStrong()),
              const Spacer(),
              Text(
                l10n.regionsAndPlaces(visit.regionCount, visit.pins.length),
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
                    widthFactor: (done / total).clamp(0, 1),
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
          const SizedBox(height: 12),
          if (chips.isEmpty)
            Text(
              l10n.worldEmpty,
              style: AppText.labelMedium(color: AppColors.muted),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final code in chips)
                  Container(
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
                        code,
                        style: AppText.labelMedium(color: AppColors.accent)
                            .copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .5,
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

/// The way into someone's world map: the design's globe button beside their
/// name in the account details.
class WorldMapButton extends StatelessWidget {
  const WorldMapButton({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    // The design's Globe icon, swapped for contrast: navy sea on the light
    // theme, green sea on the dark one.
    return Semantics(
      button: true,
      label: context.l10n.worldMap,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => WorldMapScreen(uid: uid)),
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
          child: const _SpinningGlobe(size: 48),
        ),
      ),
    );
  }
}

/// The design's Globe icon, turning: its land slides past under the shading,
/// mirrored every other turn so the seam never shows. Still when the phone
/// asks for less motion. Colours swapped for contrast: navy sea on the light
/// theme, green sea on the dark one.
class _SpinningGlobe extends StatefulWidget {
  const _SpinningGlobe({required this.size});

  final double size;

  @override
  State<_SpinningGlobe> createState() => _SpinningGlobeState();
}

class _SpinningGlobeState extends State<_SpinningGlobe>
    with SingleTickerProviderStateMixin {
  // One turn is two widths of land (one plain, one mirrored).
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final dark = AppColors.isDark;
    final land = AppIcon(
      dark ? 'globe_land_day' : 'globe_land_night',
      size: size,
    );
    final mirrored = Transform.flip(flipX: true, child: land);
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: dark ? const Color(0xFF2A7C13) : const Color(0xFF1C3A5E),
              ),
            ),
            AnimatedBuilder(
              animation: _turn,
              builder: (context, child) => Transform.translate(
                offset: Offset(-_turn.value * 2 * size, 0),
                child: child,
              ),
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: size * 3,
                child: Row(children: [land, mirrored, land]),
              ),
            ),
            // The design's shading, darker towards the lower right.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.24, -0.36),
                    radius: 0.75,
                    stops: [0.6, 1],
                    colors: [Color(0x00000000), Color(0x2E000000)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
