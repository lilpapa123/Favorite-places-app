import 'package:favorite_places/firebase_options.dart';
import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/providers/settings_provider.dart';
import 'package:favorite_places/screens/home_shell.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool? _wasDark;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = switch (settings.themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    AppColors.isDark = isDark;
    if (_wasDark != null && _wasDark != isDark) {
      // Widgets read AppColors directly and many are const, so they would
      // keep the old palette; mark the whole tree dirty (state is kept).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        void rebuild(Element element) {
          element.markNeedsBuild();
          element.visitChildren(rebuild);
        }

        if (mounted) {
          (context as Element).visitChildren(rebuild);
        }
      });
    }
    _wasDark = isDark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.data(isDark ? Brightness.dark : Brightness.light),
      locale: settings.locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Same layout in every language: Arabic changes the words, not which
      // side things sit on.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.ltr, child: child!),
      home: const HomeShell(),
    );
  }
}
