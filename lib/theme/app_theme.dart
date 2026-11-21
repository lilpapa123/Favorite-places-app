import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the app's light, friendly look.
///
/// Every color, size and text style resolves through these classes, so the
/// whole app can be re-skinned from this one file.
class AppColors {
  const AppColors._();

  /// Set by MyApp from the resolved theme (Settings or the phone's mode).
  /// Every token below reads it, so the whole palette flips at once.
  static bool isDark = false;

  /// Text and icons on accent fills: white in both modes.
  static const Color onAccent = Color(0xFFFFFFFF);

  static Color get background =>
      isDark ? const Color(0xFF0E0F12) : const Color(0xFFF3F4F6);
  static Color get surface =>
      isDark ? const Color(0xFF1A1C21) : const Color(0xFFFFFFFF);

  static Color get ink =>
      isDark ? const Color(0xFFF2F3F5) : const Color(0xFF15171C);
  static Color get inkSoft =>
      isDark ? const Color(0xFFD9DCE1) : const Color(0xFF2B2F37);
  static Color get label =>
      isDark ? const Color(0xFFC3C7CF) : const Color(0xFF3A3F48);
  static Color get muted =>
      isDark ? const Color(0xFF9EA3AD) : const Color(0xFF5B606B);
  static Color get faint =>
      isDark ? const Color(0xFF7A808B) : const Color(0xFF8A8F99);

  static Color get border =>
      isDark ? const Color(0xFF3A3F48) : const Color(0xFFC9CDD4);
  static Color get divider =>
      isDark ? const Color(0xFF2A2D34) : const Color(0xFFE2E4E8);
  static Color get dashed =>
      isDark ? const Color(0xFF4A505A) : const Color(0xFFA9AEB8);

  static Color get accent =>
      isDark ? const Color(0xFFE0603F) : const Color(0xFFB8391F);
  static Color get accentPressed =>
      isDark ? const Color(0xFFC04A2C) : const Color(0xFF8F2A15);
  static Color get accentSoft =>
      isDark ? const Color(0xFF3A1F19) : const Color(0xFFFBE9E5);
  static Color get accentDisabled =>
      isDark ? const Color(0xFF6B4A42) : const Color(0xFFC9A39A);

  static Color get success =>
      isDark ? const Color(0xFF4FB58A) : const Color(0xFF1F6B4F);
  static Color get successSoft =>
      isDark ? const Color(0xFF16302A) : const Color(0xFFE7F3EE);
  static Color get navy =>
      isDark ? const Color(0xFF6E97CC) : const Color(0xFF1E3A5F);

  /// Soft backgrounds for places without a photo, picked by position.
  static List<Color> get tints => isDark
      ? const [
          Color(0xFF243040),
          Color(0xFF3A3026),
          Color(0xFF302A3C),
          Color(0xFF20352E),
          Color(0xFF3A3220),
        ]
      : const [
          Color(0xFFDCE6F0),
          Color(0xFFEFE3D6),
          Color(0xFFE4DDEE),
          Color(0xFFD8EAE3),
          Color(0xFFF0E6D2),
        ];

  static Color tintFor(String seed) =>
      tints[seed.hashCode.abs() % tints.length];
}

class AppSpace {
  const AppSpace._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Horizontal page margin used by every screen.
  static const double page = 20;
}

class AppRadius {
  const AppRadius._();

  static const double card = 18;
  static const double field = 12;
  static const double toast = 14;
  static const double pill = 999;

  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius fieldAll = BorderRadius.all(Radius.circular(field));
}

class AppShadow {
  const AppShadow._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D141A24), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0F1A2633), blurRadius: 12, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> pin = [
    BoxShadow(color: Color(0x291F2633), blurRadius: 10, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1F14171C), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 280);
  static const Curve ease = Curves.easeOutCubic;
}

/// Space Grotesk for headings, Inter for everything else.
///
/// The base styles are resolved once and reused; each helper only applies
/// size and color, which keeps google_fonts out of the per-build path.
class AppText {
  const AppText._();

  static final TextStyle _inter400 = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
  );
  static final TextStyle _inter500 = GoogleFonts.inter(
    fontWeight: FontWeight.w500,
  );
  static final TextStyle _inter600 = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
  );
  static final TextStyle _grotesk700 = GoogleFonts.spaceGrotesk(
    fontWeight: FontWeight.w700,
  );

  /// Big page title: "My places".
  static TextStyle heading({Color? color}) => _grotesk700.copyWith(
    fontSize: 28,
    height: 1.4,
    letterSpacing: -0.8,
    color: color ?? AppColors.ink,
  );

  /// Big numbers on the Account stats card.
  static TextStyle stat({Color? color}) => _grotesk700.copyWith(
    fontSize: 25,
    height: 1.4,
    color: color ?? AppColors.accent,
  );

  /// "MY LITTLE NOTE", "YOUR SPACE" section captions.
  static TextStyle overline({Color? color}) => _inter600.copyWith(
    fontSize: 11,
    height: 1.36,
    letterSpacing: 1,
    color: color ?? AppColors.faint,
  );

  /// Medium 13 — field labels, chips, secondary actions.
  static TextStyle labelMedium({Color? color}) => _inter500.copyWith(
    fontSize: 13,
    height: 1.4,
    color: color ?? AppColors.label,
  );

  /// Medium 15 — list rows.
  static TextStyle row({Color? color}) => _inter500.copyWith(
    fontSize: 15,
    height: 1.4,
    color: color ?? AppColors.ink,
  );

  /// Large title on the detail screen.
  static TextStyle display({Color? color}) => _grotesk700.copyWith(
    fontSize: 26,
    height: 1.15,
    letterSpacing: -0.5,
    color: color ?? AppColors.ink,
  );

  /// Card and section titles.
  static TextStyle title({Color? color}) => _inter600.copyWith(
    fontSize: 17,
    height: 1.3,
    color: color ?? AppColors.ink,
  );

  static TextStyle body({Color? color}) => _inter400.copyWith(
    fontSize: 15,
    height: 1.4,
    color: color ?? AppColors.ink,
  );

  static TextStyle bodyStrong({Color? color}) => _inter600.copyWith(
    fontSize: 15,
    height: 1.3,
    color: color ?? AppColors.ink,
  );

  /// "Why you love it" notes.
  static TextStyle note({Color? color}) => _inter400.copyWith(
    fontSize: 14,
    height: 1.45,
    color: color ?? AppColors.inkSoft,
  );

  /// "Kadıköy · Walk" and other secondary lines.
  static TextStyle meta({Color? color}) => _inter400.copyWith(
    fontSize: 13,
    height: 1.35,
    color: color ?? AppColors.muted,
  );

  /// Form field labels.
  static TextStyle label({Color? color}) => _inter600.copyWith(
    fontSize: 13,
    height: 1.3,
    color: color ?? AppColors.label,
  );

  static TextStyle chip({Color? color}) => _inter500.copyWith(
    fontSize: 14,
    height: 1.2,
    color: color ?? AppColors.ink,
  );

  static TextStyle button({Color? color, double size = 15}) =>
      _inter600.copyWith(
        fontSize: size,
        height: 1.2,
        color: color ?? AppColors.onAccent,
      );

  static TextStyle tab({Color? color}) => _inter600.copyWith(
    fontSize: 11,
    height: 1.1,
    color: color ?? AppColors.muted,
  );
}

class AppTheme {
  const AppTheme._();

  /// Theme for [brightness]. Callers must set [AppColors.isDark] first so
  /// the tokens resolve to the matching palette.
  static ThemeData data(Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    const fieldBorder = OutlineInputBorder(
      borderRadius: AppRadius.fieldAll,
      borderSide: BorderSide.none,
    );

    return base.copyWith(
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.accent,
        onPrimary: AppColors.onAccent,
        secondary: AppColors.navy,
        onSecondary: AppColors.onAccent,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.muted,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
        error: AppColors.accent,
        onError: AppColors.onAccent,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.accent.withValues(alpha: 0.22),
        selectionHandleColor: AppColors.accent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppText.title(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppText.body(color: AppColors.faint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldAll,
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.bodyStrong(color: AppColors.surface)
            .copyWith(fontSize: 14),
        actionTextColor: const Color(0xFFFFB4A3),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          0,
          AppSpace.page,
          AppSpace.md,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.toast)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.muted, size: 22),
    );
  }
}
