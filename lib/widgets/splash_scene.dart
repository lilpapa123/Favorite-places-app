import 'dart:math' as math;

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The launch splash, from the design canvas: the icon's world over the whole
/// screen, by day (sun and birds) or, in dark mode, by night (moon, stars, a
/// shooting star, lit windows and a headlamp). Drawn for a 402×874 screen and
/// scaled to the real width; the sky sits at the top and the skyline at the
/// bottom on any height.
class SplashScene extends StatefulWidget {
  const SplashScene({super.key, this.night = false});

  final bool night;

  static String skyline({required bool night}) =>
      night ? 'assets/splash/skyline_night.svg' : 'assets/splash/skyline.svg';

  /// Loads the skyline so the scene shows whole from its first frame.
  static Future<void> precache({required bool night}) {
    final loader = SvgAssetLoader(skyline(night: night));
    return svg.cache.putIfAbsent(
      loader.cacheKey(null),
      () => loader.loadBytes(null),
    );
  }

  @override
  State<SplashScene> createState() => _SplashSceneState();
}

class _SplashSceneState extends State<SplashScene>
    with TickerProviderStateMixin {
  /// Seconds since the scene appeared; birds and hiker are drawn from it.
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(
    (elapsed) => _time.value = elapsed.inMicroseconds / 1e6,
  );
  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still) {
      _ticker.stop();
      _rise.value = 1;
    } else if (!_ticker.isActive) {
      _ticker.start();
      _rise.forward();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _rise.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final night = widget.night;
    return LayoutBuilder(
      builder: (context, box) {
        // Design px to screen px.
        final k = box.maxWidth / 402;
        final rise = CurvedAnimation(
          parent: _rise,
          curve: const Cubic(0.2, 0.8, 0.2, 1),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: night
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0B1526),
                      Color(0xFF16263F),
                      Color(0xFF2A3A55),
                    ],
                    stops: [0, 0.5, 1],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFF8CF),
                      Color(0xFFFDEFC8),
                      Color(0xFFFBE6C2),
                    ],
                    stops: [0, 0.55, 1],
                  ),
          ),
          // Text styles need a Material above them.
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  width: 402 * k,
                  height: 340 * k,
                  child: CustomPaint(
                    painter: night
                        ? _NightSkyPainter(_time, k: k, still: _still)
                        : _SkyPainter(_time, k: k, still: _still),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 352 * k,
                  child: AnimatedBuilder(
                    animation: rise,
                    builder: (context, child) => Opacity(
                      opacity: rise.value,
                      child: Transform.translate(
                        offset: Offset(0, 12 * k * (1 - rise.value)),
                        child: child,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.appTitle,
                          style: AppText.display(color: night ? _cream : _ink)
                              .copyWith(
                                fontSize: 48 * k,
                                height: 1.1,
                                letterSpacing: -1.5 * k,
                              ),
                        ),
                        SizedBox(height: 8 * k),
                        Text(
                          l10n.splashTagline,
                          style:
                              AppText.body(
                                color: night
                                    ? const Color(0xFFFBE6C2)
                                          .withValues(alpha: .85)
                                    : _tagline,
                              ).copyWith(
                                fontSize: 15 * k,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  width: 402 * k,
                  height: 256 * k,
                  child: SvgPicture.asset(
                    SplashScene.skyline(night: night),
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HikerPainter(
                      _time,
                      k: k,
                      still: _still,
                      headlamp: night,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

const _ink = Color(0xFF2B2B2B);
const _cream = Color(0xFFFFF8CF);
const _tagline = Color(0xFF9A7564);
const _birdColor = Color(0xFFB98E7A);

/// Smooth 0→1→0 over one [period], like CSS ease-in-out between two keys.
double _swing(double t, double period, [double delay = 0]) =>
    (1 - math.cos(2 * math.pi * ((t - delay) / period))) / 2;

double _loop(double t, double period, [double delay = 0]) =>
    (((t - delay) / period) % 1 + 1) % 1;

/// One bird: its height, where it rests with reduced motion, how long one
/// crossing takes, size, and how fast it flaps. Delays as in the design.
typedef _Bird = ({
  double y,
  double rest,
  double cross,
  double crossDelay,
  double size,
  double flap,
  double flapDelay,
});

const List<_Bird> _birds = [
  (
    y: 70,
    rest: 60,
    cross: 22,
    crossDelay: -3,
    size: 1,
    flap: .7,
    flapDelay: -.43,
  ),
  (
    y: 96,
    rest: 300,
    cross: 26,
    crossDelay: -15,
    size: .7,
    flap: .6,
    flapDelay: -2.14,
  ),
  (
    y: 128,
    rest: 120,
    cross: 19,
    crossDelay: -9,
    size: .85,
    flap: .65,
    flapDelay: -1.29,
  ),
  (
    y: 150,
    rest: 240,
    cross: 24,
    crossDelay: -20,
    size: .6,
    flap: .55,
    flapDelay: -2.86,
  ),
  (
    y: 182,
    rest: 40,
    cross: 21,
    crossDelay: -1,
    size: .9,
    flap: .7,
    flapDelay: -.14,
  ),
  (
    y: 204,
    rest: 350,
    cross: 28,
    crossDelay: -12,
    size: .65,
    flap: .6,
    flapDelay: -1.71,
  ),
  (
    y: 232,
    rest: 150,
    cross: 23,
    crossDelay: -6,
    size: .75,
    flap: .62,
    flapDelay: -.86,
  ),
  (
    y: 118,
    rest: 90,
    cross: 30,
    crossDelay: -24,
    size: .55,
    flap: .5,
    flapDelay: -3.43,
  ),
  (
    y: 58,
    rest: 330,
    cross: 25,
    crossDelay: -18,
    size: .6,
    flap: .58,
    flapDelay: -2.57,
  ),
];

/// The sun with its glow, and birds crossing left to right.
class _SkyPainter extends CustomPainter {
  _SkyPainter(this.time, {required this.k, required this.still})
    : super(repaint: time);

  final ValueNotifier<double> time;
  final double k;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(k);
    const sun = Offset(201, 270);
    canvas.drawCircle(
      sun,
      64,
      Paint()..color = const Color(0xFFF8B48E).withValues(alpha: .14),
    );
    canvas.drawCircle(
      sun,
      40,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8B48E), Color(0xFFEE8A62)],
        ).createShader(Rect.fromCircle(center: sun, radius: 40)),
    );

    final t = time.value;
    final stroke = Paint()
      ..color = _birdColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    // Two little arcs, like a "m" seen from afar.
    final wings = Path()
      ..moveTo(-12, 0)
      ..relativeQuadraticBezierTo(6, -6, 12, 0)
      ..relativeQuadraticBezierTo(6, -6, 12, 0);
    for (final bird in _birds) {
      final x = still
          ? bird.rest
          : -40 + 490 * _loop(t, bird.cross, bird.crossDelay);
      // Wings fold from up (1) to down (-0.5), hinged at the body.
      final flap = still ? 1.0 : 1 - 1.5 * _swing(t, bird.flap, bird.flapDelay);
      canvas
        ..save()
        ..translate(x, bird.y)
        ..scale(bird.size, bird.size * flap)
        ..drawPath(wings, stroke)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.k != k || old.still != still;
}

/// One star: where it is, how big, and how it twinkles (as in the design).
typedef _Star = ({double x, double y, double r, double period, double delay});

const List<_Star> _stars = [
  (x: 175, y: 97, r: 1.6, period: 3.6, delay: -0.3),
  (x: 284, y: 68, r: 1.2, period: 3.5, delay: -3.6),
  (x: 119, y: 39, r: 0.8, period: 3.1, delay: -0.3),
  (x: 56, y: 302, r: 1.6, period: 2.1, delay: -2.3),
  (x: 124, y: 318, r: 0.8, period: 3.4, delay: -1.6),
  (x: 123, y: 43, r: 1, period: 2.7, delay: -0.6),
  (x: 70, y: 312, r: 1.2, period: 3.4, delay: -2.7),
  (x: 62, y: 317, r: 1, period: 2.9, delay: -2.2),
  (x: 42, y: 308, r: 0.8, period: 3.5, delay: -2.0),
  (x: 282, y: 238, r: 1.2, period: 3.2, delay: -3.7),
  (x: 195, y: 173, r: 1, period: 4.0, delay: -2.8),
  (x: 134, y: 61, r: 1.2, period: 3.3, delay: -3.5),
  (x: 383, y: 249, r: 1.2, period: 3.5, delay: -0.3),
  (x: 272, y: 234, r: 1, period: 3.9, delay: -0.6),
  (x: 260, y: 235, r: 0.8, period: 4.4, delay: -0.3),
  (x: 295, y: 313, r: 1.2, period: 2.9, delay: -1.4),
  (x: 264, y: 316, r: 1.6, period: 2.2, delay: -0.4),
  (x: 148, y: 262, r: 0.8, period: 2.2, delay: -2.8),
  (x: 341, y: 315, r: 1.6, period: 2.7, delay: -1.5),
  (x: 352, y: 197, r: 0.8, period: 4.4, delay: -1.4),
  (x: 322, y: 79, r: 1.6, period: 2.1, delay: -3.1),
  (x: 76, y: 146, r: 1.6, period: 3.0, delay: -3.5),
  (x: 51, y: 105, r: 1.6, period: 3.0, delay: -1.1),
  (x: 80, y: 240, r: 1.2, period: 3.8, delay: -3.9),
  (x: 359, y: 214, r: 1, period: 2.4, delay: -0.7),
  (x: 128, y: 139, r: 0.8, period: 3.2, delay: -2.4),
  (x: 144, y: 164, r: 0.8, period: 2.4, delay: -2.1),
  (x: 322, y: 309, r: 1.2, period: 4.4, delay: -2.8),
  (x: 273, y: 47, r: 1.6, period: 4.2, delay: -3.1),
  (x: 358, y: 306, r: 1.6, period: 3.0, delay: -1.6),
  (x: 256, y: 225, r: 0.8, period: 2.5, delay: -3.9),
  (x: 235, y: 103, r: 0.8, period: 2.9, delay: -0.2),
  (x: 10, y: 310, r: 1, period: 3.3, delay: -3.8),
  (x: 324, y: 33, r: 0.8, period: 4.2, delay: -2.5),
  (x: 86, y: 149, r: 1.2, period: 3.5, delay: -1.9),
  (x: 69, y: 269, r: 1.6, period: 3.2, delay: -1.2),
  (x: 83, y: 72, r: 1.2, period: 3.9, delay: -1.9),
  (x: 364, y: 102, r: 0.8, period: 2.5, delay: -3.8),
  (x: 195, y: 95, r: 0.8, period: 3.9, delay: -1.2),
  (x: 339, y: 66, r: 1.2, period: 3.3, delay: -3.6),
  (x: 192, y: 134, r: 1.2, period: 3.6, delay: -2.5),
  (x: 109, y: 142, r: 1.6, period: 3.8, delay: -0.9),
  (x: 275, y: 272, r: 1.2, period: 3.8, delay: -4.0),
  (x: 153, y: 261, r: 1.2, period: 2.5, delay: -2.4),
  (x: 186, y: 248, r: 1.2, period: 4.4, delay: -1.5),
  (x: 122, y: 72, r: 1, period: 3.2, delay: -1.4),
];

/// The crescent moon with its glow, twinkling stars, and now and then a
/// shooting star.
class _NightSkyPainter extends CustomPainter {
  _NightSkyPainter(this.time, {required this.k, required this.still})
    : super(repaint: time);

  final ValueNotifier<double> time;
  final double k;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(k);
    const moon = Offset(201, 270);
    canvas.drawCircle(
      moon,
      90,
      Paint()
        ..shader = RadialGradient(
          colors: [_cream.withValues(alpha: .35), _cream.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: moon, radius: 90)),
    );
    // A full disc with a smaller one cut out up and to the right.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: moon, radius: 38)),
        Path()..addOval(
          Rect.fromCircle(center: const Offset(218, 258), radius: 34),
        ),
      ),
      Paint()..color = _cream,
    );

    final t = time.value;
    for (final star in _stars) {
      final glow = still ? 1.0 : .25 + .75 * _swing(t, star.period, star.delay);
      canvas.drawCircle(
        Offset(star.x, star.y),
        star.r,
        Paint()..color = _cream.withValues(alpha: glow),
      );
    }

    // Once every 7 s, starting 1.5 s in: a streak across the top 12% of the
    // loop, fading in fast and out slower.
    if (still || t < 1.5) {
      return;
    }
    final p = _loop(t, 7, 1.5);
    if (p >= .12) {
      return;
    }
    final at = Curves.easeOut.transform(p / .12);
    final fade = p < .03 ? p / .03 : 1 - (p - .03) / .09;
    canvas
      ..save()
      ..translate(60 + 200 * at, 60 + 90 * at)
      ..rotate(25 * math.pi / 180)
      ..drawLine(
        Offset.zero,
        const Offset(46, 0),
        Paint()
          ..color = _cream.withValues(alpha: fade.clamp(0, 1))
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_NightSkyPainter old) => old.k != k || old.still != still;
}

/// The icon's hiker walking the trail along the grass, left to right.
class _HikerPainter extends CustomPainter {
  _HikerPainter(
    this.time, {
    required this.k,
    required this.still,
    this.headlamp = false,
  }) : super(repaint: time);

  final ValueNotifier<double> time;
  final double k;
  final bool still;

  /// At night: a lamp on the head and its beam ahead.
  final bool headlamp;

  static const _dark = Color(0xFF123F2F);
  static const _darker = Color(0xFF0D3024);
  static const _cream = Color(0xFFF3EBD8);
  static const _lamp = Color(0xFFF6CB74);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    // The splash lasts about 3 seconds, so the walk starts on screen rather
    // than off the left edge as in the 7 s design loop.
    final walk = still ? 179.0 : -60 + 480 * _loop(t, 7, -2.6);
    // The design's 44×64 box, 44 px above the bottom; inside it the hiker's
    // own drawing units (viewBox 74 50 72 104).
    const unit = 44 / 72;
    canvas
      ..save()
      ..scale(k)
      ..translate(walk, size.height / k - 44 - 64)
      ..translate(0, (64 - 104 * unit) / 2)
      ..scale(unit)
      ..translate(-74, -50);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(104, 151), width: 32, height: 5),
      Paint()..color = _dark.withValues(alpha: .18),
    );

    final bob = still ? 0.0 : -1.5 * _swing(t, .45);
    final legSwing = still ? 0.0 : -math.cos(2 * math.pi * _loop(t, .9));
    canvas
      ..save()
      ..translate(0, bob);

    void leg(double degrees, Color color) => canvas
      ..save()
      ..translate(102, 114)
      ..rotate(degrees * math.pi / 180)
      ..translate(-102, -114)
      ..drawLine(
        const Offset(102, 114),
        const Offset(102, 149),
        _line(color, 9),
      )
      ..restore();

    leg(still ? 0 : 22 * legSwing, _darker);

    final pole = still ? 0.0 : -1 + 9 * legSwing;
    canvas
      ..save()
      ..translate(130, 82)
      ..rotate(pole * math.pi / 180)
      ..translate(-130, -82)
      ..drawLine(
        const Offset(130, 82),
        const Offset(140, 151),
        _line(_dark, 3.5),
      )
      ..restore();

    canvas
      ..save()
      ..translate(105, 97)
      ..rotate(12 * math.pi / 180)
      ..translate(-105, -97);
    const pack = Rect.fromLTWH(80, 80, 19, 31);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(pack, const Radius.circular(7)),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6CB74), Color(0xFFD9952E)],
          ).createShader(pack),
      )
      ..drawRRect(
        _rr(83, 93, 10, 8, 2),
        Paint()..color = const Color(0xFFB9791F),
      )
      ..drawRRect(_rr(96, 77, 19, 40, 9), Paint()..color = _dark)
      ..drawPath(
        Path()
          ..moveTo(100, 79)
          ..lineTo(111, 102)
          ..moveTo(110, 78)
          ..lineTo(117, 102),
        Paint()
          ..color = _cream.withValues(alpha: .85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      )
      ..drawRRect(_rr(107, 101, 15, 10, 2.5), Paint()..color = _cream)
      ..drawRRect(_rr(109, 99, 5, 3, 1), Paint()..color = _cream)
      ..drawCircle(const Offset(115, 106), 3.6, Paint()..color = _dark)
      ..drawCircle(
        const Offset(115, 106),
        1.5,
        Paint()..color = const Color(0xFF6FB3B8),
      )
      ..drawCircle(
        const Offset(119.6, 103),
        .9,
        Paint()..color = const Color(0xFFD9952E),
      )
      ..restore();

    leg(still ? 0 : -22 * legSwing, _dark);

    if (headlamp) {
      canvas.drawPath(
        Path()
          ..moveTo(119, 62)
          ..lineTo(150, 52)
          ..lineTo(150, 78)
          ..close(),
        Paint()..color = _lamp.withValues(alpha: .28),
      );
    }
    canvas.drawCircle(const Offset(111, 64), 10, Paint()..color = _dark);
    if (headlamp) {
      canvas.drawCircle(const Offset(119, 63), 2.2, Paint()..color = _lamp);
    }
    canvas
      ..drawPath(
        Path()
          ..moveTo(110, 86)
          ..lineTo(121, 97)
          ..lineTo(131, 92),
        _line(_dark, 7)..strokeJoin = StrokeJoin.round,
      )
      ..restore()
      ..restore();
  }

  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  static RRect _rr(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  @override
  bool shouldRepaint(_HikerPainter old) => old.k != k || old.still != still;
}
