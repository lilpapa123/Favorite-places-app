import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the "ASCII" theme (text-mode art).
///
/// Components never hardcode a color, font, radius or duration: everything
/// resolves through these tokens so the whole app can be re-skinned in one
/// place, exactly like the stylesheet the theme ships with.
class AsciiPalette {
  const AsciiPalette._();

  static const Color canvas = Color(0xFF0D0F0C);
  static const Color surface = Color(0xFF141712);
  static const Color surfaceRaised = Color(0xFF1C2019);
  static const Color ink = Color(0xFFD8F5D0);
  static const Color mute = Color(0xFF7E9D77);
  static const Color accent = Color(0xFF7FE06A);
  static const Color accentSoft = Color(0xFFD8F5D0);
  static const Color accentInk = Color(0xFF0D0F0C);
  static const Color line = Color(0xFF2D3629);
  static const Color lineStrong = Color(0xFF44543D);
}

class AsciiSpace {
  const AsciiSpace._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AsciiShape {
  const AsciiShape._();

  /// The theme is square-cornered on purpose: 0 radius everywhere.
  static const double radius = 0;
  static const double borderWidth = 1;
  static const double tapTarget = 44;
  static const BorderRadius none = BorderRadius.zero;
}

class AsciiMotion {
  const AsciiMotion._();

  static const Duration fast = Duration(milliseconds: 110);
  static const Duration blink = Duration(milliseconds: 700);
  static const Curve ease = StepsCurve(4);
  static const double pressScale = 0.96;
}

/// `steps(4, end)` — the theme's easing curve, used for taps and presses.
class StepsCurve extends Curve {
  const StepsCurve(this.steps);

  final int steps;

  @override
  double transformInternal(double t) {
    return (t * steps).floorToDouble() / steps;
  }
}

class AsciiType {
  const AsciiType._();

  static TextStyle display({Color color = AsciiPalette.ink}) => _body(
    size: 30,
    weight: FontWeight.w600,
    color: color,
    letterSpacing: -0.5,
  );

  static TextStyle heading({Color color = AsciiPalette.ink}) =>
      _body(size: 20, weight: FontWeight.w600, color: color);

  static TextStyle title({Color color = AsciiPalette.ink}) =>
      _body(size: 15, weight: FontWeight.w600, color: color);

  static TextStyle body({Color color = AsciiPalette.ink}) =>
      _body(size: 14, color: color);

  static TextStyle small({Color color = AsciiPalette.mute}) =>
      _body(size: 12, color: color);

  static TextStyle button({Color color = AsciiPalette.accentInk}) => _body(
    size: 14,
    weight: FontWeight.w600,
    color: color,
    letterSpacing: 1.2,
  );

  static TextStyle meta({Color color = AsciiPalette.mute}) =>
      _code(size: 11, color: color, letterSpacing: 0.8);

  static TextStyle label({Color color = AsciiPalette.mute}) =>
      _code(size: 10, color: color, letterSpacing: 1.6);

  static TextStyle _body({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: GoogleFonts.ibmPlexMono().fontFamily,
      fontSize: size,
      height: 1.35,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle _code({
    required double size,
    required Color color,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
      fontSize: size,
      height: 1.3,
      fontWeight: FontWeight.w400,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}

class AsciiTheme {
  const AsciiTheme._();

  static const ColorScheme _scheme = ColorScheme.dark(
    primary: AsciiPalette.accent,
    onPrimary: AsciiPalette.accentInk,
    secondary: AsciiPalette.accentSoft,
    onSecondary: AsciiPalette.accentInk,
    surface: AsciiPalette.surface,
    onSurface: AsciiPalette.ink,
    surfaceContainerHighest: AsciiPalette.surfaceRaised,
    onSurfaceVariant: AsciiPalette.mute,
    outline: AsciiPalette.line,
    outlineVariant: AsciiPalette.lineStrong,
    error: Color(0xFFFF6B5E),
    onError: AsciiPalette.accentInk,
  );

  static ThemeData get data {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

    return base.copyWith(
      colorScheme: _scheme,
      scaffoldBackgroundColor: AsciiPalette.canvas,
      canvasColor: AsciiPalette.canvas,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: AsciiPalette.line,
        thickness: AsciiShape.borderWidth,
        space: AsciiShape.borderWidth,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AsciiPalette.accent,
        selectionColor: AsciiPalette.accent.withValues(alpha: 0.28),
        selectionHandleColor: AsciiPalette.accent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AsciiPalette.canvas,
        foregroundColor: AsciiPalette.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleSpacing: AsciiSpace.lg,
        titleTextStyle: AsciiType.heading(),
        iconTheme: const IconThemeData(color: AsciiPalette.ink, size: 20),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AsciiPalette.surfaceRaised,
        contentTextStyle: AsciiType.body(),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AsciiSpace.md),
        shape: const RoundedRectangleBorder(
          side: BorderSide(
            color: AsciiPalette.lineStrong,
            width: AsciiShape.borderWidth,
          ),
          borderRadius: AsciiShape.none,
        ),
      ),
      iconTheme: const IconThemeData(color: AsciiPalette.mute, size: 20),
    );
  }
}
