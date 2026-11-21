import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages the app is translated into.
const supportedLocales = [Locale('en'), Locale('ar'), Locale('tr')];

/// Appearance and language picked in Settings. A null [locale] means
/// "follow the phone".
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.locale});

  final ThemeMode themeMode;
  final Locale? locale;
}

/// Loaded in main() before the first frame so the app never flashes the
/// wrong theme or language.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _themeKey = 'themeMode';
  static const _localeKey = 'locale';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final theme = _prefs.getString(_themeKey);
    final code = _prefs.getString(_localeKey);
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == theme,
        orElse: () => ThemeMode.system,
      ),
      locale: code == null ? null : Locale(code),
    );
  }

  void setThemeMode(ThemeMode mode) {
    _prefs.setString(_themeKey, mode.name);
    state = AppSettings(themeMode: mode, locale: state.locale);
  }

  /// Pass null to follow the phone's language.
  void setLocale(Locale? locale) {
    if (locale == null) {
      _prefs.remove(_localeKey);
    } else {
      _prefs.setString(_localeKey, locale.languageCode);
    }
    state = AppSettings(themeMode: state.themeMode, locale: locale);
  }
}
