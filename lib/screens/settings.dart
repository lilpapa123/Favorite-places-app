import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/providers/settings_provider.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Appearance (system / light / dark) and language (system / en / ar / tr).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
          children: [
            PageHeader(
              title: l10n.settingsTitle,
              subtitle: l10n.settingsSubtitle,
              trailing: CircleIconButton(
                icon: const AppIcon('close'),
                semanticLabel: l10n.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.appearance, style: AppText.overline()),
                  const SizedBox(height: 9),
                  _OptionCard(
                    options: [
                      (l10n.themeSystem, Icons.brightness_auto_outlined),
                      (l10n.themeLight, Icons.light_mode_outlined),
                      (l10n.themeDark, Icons.dark_mode_outlined),
                    ],
                    selected: switch (settings.themeMode) {
                      ThemeMode.system => 0,
                      ThemeMode.light => 1,
                      ThemeMode.dark => 2,
                    },
                    onSelect: (i) => notifier.setThemeMode(
                      [ThemeMode.system, ThemeMode.light, ThemeMode.dark][i],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xxl),
                  Text(l10n.language, style: AppText.overline()),
                  const SizedBox(height: 9),
                  _OptionCard(
                    // Language names stay in their own script so anyone can
                    // find theirs.
                    options: [
                      (l10n.languageSystem, Icons.phone_iphone),
                      ('English', Icons.translate),
                      ('العربية', Icons.translate),
                      ('Türkçe', Icons.translate),
                    ],
                    selected: switch (settings.locale?.languageCode) {
                      null => 0,
                      'en' => 1,
                      'ar' => 2,
                      _ => 3,
                    },
                    onSelect: (i) => notifier.setLocale(
                      i == 0 ? null : supportedLocales[i - 1],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card of single-choice rows with a check on the selected one.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<(String, IconData)> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 60, end: 16),
                child: Divider(height: 1),
              ),
            Semantics(
              selected: i == selected,
              inMutuallyExclusiveGroup: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: SizedBox(
                    height: 54,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: i == selected
                                    ? AppColors.accentSoft
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                options[i].$2,
                                size: 18,
                                color: i == selected
                                    ? AppColors.accent
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Text(options[i].$1, style: AppText.row()),
                          ),
                          if (i == selected)
                            Icon(
                              Icons.check,
                              size: 20,
                              color: AppColors.accent,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
