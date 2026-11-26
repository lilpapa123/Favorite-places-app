import 'dart:async';

import 'package:favorite_places/firebase_options.dart';
import 'package:favorite_places/providers/settings_provider.dart';
import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/screens/home_shell.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/splash_scene.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      home: const _Splash(child: HomeShell()),
    );
  }
}

/// The splash scene for 3 seconds at launch; the app loads underneath, then
/// shows through as the splash fades out. The native launch screens use the
/// scene's top cream, so there is no flash before it.
class _Splash extends StatefulWidget {
  const _Splash({required this.child});

  final Widget child;

  static const shown = Duration(seconds: 3);
  static const fade = Duration(milliseconds: 400);

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  /// The skyline is loaded (or took too long); the scene shows whole from
  /// then on, for 3 seconds.
  bool _ready = false;
  bool _fading = false;
  bool _gone = false;
  bool _started = false;
  Timer? _fallback;
  Timer? _timer;

  void _show() {
    if (_ready || !mounted) {
      return;
    }
    _fallback?.cancel();
    setState(() => _ready = true);
    _timer = Timer(_Splash.shown, () => setState(() => _fading = true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    SplashScene.precache(night: AppColors.isDark).whenComplete(_show);
    _fallback = Timer(const Duration(milliseconds: 600), _show);
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _Splash.fade;
    final night = AppColors.isDark;
    return Stack(
      children: [
        // Status bar icons that show on the app's own background; the splash
        // sets dark ones over itself.
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppColors.isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: widget.child,
        ),
        if (!_gone)
          IgnorePointer(
            ignoring: _fading,
            child: AnimatedOpacity(
              opacity: _fading ? 0 : 1,
              duration: fade,
              onEnd: () => setState(() => _gone = true),
              // Status bar icons that show on the splash's sky.
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: night
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                child: SplashScene(night: night),
              ),
            ),
          ),
      ],
    );
  }
}
