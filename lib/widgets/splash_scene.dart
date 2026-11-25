import 'dart:math' as math;

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The launch splash, from the design canvas: the icon's world over the whole
/// screen. Drawn for a 402×874 screen and scaled to the real width; the sky
/// sits at the top and the skyline at the bottom on any height.
class SplashScene extends StatefulWidget {
  const SplashScene({super.key});

  static const skyline = 'assets/splash/skyline.svg';

  /// Loads the skyline so the scene shows whole from its first frame.
  static Future<void> precache() {
    const loader = SvgAssetLoader(skyline);
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
    return LayoutBuilder(
      builder: (context, box) {
        // Design px to screen px.
        final k = box.maxWidth / 402;
        final rise = CurvedAnimation(
          parent: _rise,
          curve: const Cubic(0.2, 0.8, 0.2, 1),
        );
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF3EDC8), Color(0xFFF5E3C7), Color(0xFFF6D9C6)],
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
                    painter: _SkyPainter(_time, k: k, still: _still),
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
                          style: AppText.display(color: _ink).copyWith(
                            fontSize: 48 * k,
                            height: 1.1,
                            letterSpacing: -1.5 * k,
                          ),
                        ),
                        SizedBox(height: 8 * k),
                        Text(
                          l10n.splashTagline,
                          style: AppText.body(color: _tagline).copyWith(
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
                    SplashScene.skyline,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HikerPainter(_time, k: k, still: _still),
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

/// The icon's hiker walking the trail along the grass, left to right.
class _HikerPainter extends CustomPainter {
  _HikerPainter(this.time, {required this.k, required this.still})
    : super(repaint: time);

  final ValueNotifier<double> time;
  final double k;
  final bool still;

  static const _dark = Color(0xFF123F2F);
  static const _darker = Color(0xFF0D3024);
  static const _cream = Color(0xFFF3EBD8);

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

    canvas
      ..drawCircle(const Offset(111, 64), 10, Paint()..color = _dark)
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
