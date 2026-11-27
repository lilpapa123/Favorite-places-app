import 'package:favorite_places/l10n/app_localizations.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/screens/edit_profile.dart';
import 'package:favorite_places/services/profile_photo.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:favorite_places/providers/settings_provider.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings, from the design: your profile card, appearance as three little
/// previews, language as a grid, and signing out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final user = ref.watch(authStateProvider).value;
    final theme = switch (settings.themeMode) {
      ThemeMode.system => 0,
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
    };
    final language = switch (settings.locale?.languageCode) {
      null => 0,
      'en' => 1,
      'ar' => 2,
      _ => 3,
    };

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
                  if (user != null) _ProfileCard(user: user),
                  _Heading(l10n.appearance),
                  Row(
                    children: [
                      for (final (i, (label, icon)) in [
                        (l10n.languageAutoCode, Icons.brightness_auto_outlined),
                        (l10n.themeLight, Icons.light_mode_outlined),
                        (l10n.themeDark, Icons.dark_mode_outlined),
                      ].indexed) ...[
                        if (i > 0) const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: _ThemeTile(
                            look: _ThemeLook.values[i],
                            label: label,
                            icon: icon,
                            selected: theme == i,
                            onTap: () => notifier.setThemeMode(
                              [
                                ThemeMode.system,
                                ThemeMode.light,
                                ThemeMode.dark,
                              ][i],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  _Heading(l10n.language),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpace.sm,
                    crossAxisSpacing: AppSpace.sm,
                    childAspectRatio: 2.9,
                    // Language names stay in their own script so anyone can
                    // find theirs.
                    children: [
                      for (final (i, (code, label)) in [
                        (l10n.languageAutoCode, l10n.phoneLanguage),
                        ('EN', 'English'),
                        ('AR', 'العربية'),
                        ('TR', 'Türkçe'),
                      ].indexed)
                        _LanguageTile(
                          code: code,
                          label: label,
                          selected: language == i,
                          onTap: () => notifier.setLocale(
                            i == 0 ? null : supportedLocales[i - 1],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),
                  PillButton(
                    label: l10n.signOut,
                    leading: AppIcon('logout', color: AppColors.accent),
                    variant: PillButtonVariant.outlined,
                    expanded: true,
                    large: true,
                    onPressed: () async {
                      await ref.read(firebaseAuthProvider).signOut();
                      // Settings sits on top of Account, now the sign-in form.
                      if (context.mounted) {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    '${l10n.appTitle} 1.0.0\n${l10n.settingsFooter}',
                    textAlign: TextAlign.center,
                    style: AppText.meta(color: AppColors.faint)
                        .copyWith(fontSize: 12, height: 1.5),
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

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
    child: Text(
      text.toUpperCase(),
      style: AppText.overline(color: AppColors.muted).copyWith(fontSize: 11),
    ),
  );
}

/// Your photo, name, @username and places, on green; opens Edit profile.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider).value;
    final places = ref.watch(userPlacesProvider).length;
    final localPhoto = ref.watch(profilePhotoProvider(user.uid)).value;
    final shared = profile?.photoUrl ?? user.photoURL;
    final name = (profile?.name ?? '').isNotEmpty
        ? profile!.name
        : (user.displayName ?? '');
    final handle = profile?.username.isNotEmpty ?? false
        ? '@${profile!.username} · '
        : '';
    const green = Color(0xFF2A7C13);
    return Semantics(
      button: true,
      label: '${l10n.edit}: $name',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (ctx) => EditProfileScreen(user: user, shownName: name),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(top: AppSpace.sm),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [green, Color(0xFF4E9E33)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: green.withValues(alpha: .25),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .7),
                ),
                child: localPhoto != null || shared != null
                    ? Avatar(
                        name: name,
                        // The shared photo wins: it is the same everywhere.
                        image: shared == null ? localPhoto : null,
                        photoUrl: shared,
                        size: 52,
                      )
                    : CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFFBE6C2),
                        child: Text(
                          name.isEmpty ? '?' : name[0].toUpperCase(),
                          style: AppText.heading(color: green)
                              .copyWith(fontSize: 22),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong(color: Colors.white)
                          .copyWith(fontSize: 17),
                    ),
                    Text(
                      '$handle${l10n.placesSavedCount(places)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.meta(
                        color: Colors.white.withValues(alpha: .85),
                      ).copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFBE6),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.edit,
                      style: AppText.label(color: Colors.white)
                          .copyWith(fontSize: 13),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What each appearance looks like, for its little preview.
enum _ThemeLook {
  system(Color(0xFFFFFBE6), Color(0xFFDCCF9E)),
  light(Color(0xFFFFFBE6), Color(0xFFDCCF9E)),
  dark(Color(0xFF18263C), Color(0xFF3A4B68));

  const _ThemeLook(this.card, this.line);

  final Color card;
  final Color line;
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.look,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final _ThemeLook look;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const _cream = Color(0xFFFFF8CF);
  static const _navy = Color(0xFF0E1A2B);

  @override
  Widget build(BuildContext context) {
    final preview = BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: switch (look) {
        _ThemeLook.light => _cream,
        _ThemeLook.dark => _navy,
        _ThemeLook.system => null,
      },
      // Half light, half dark.
      gradient: look == _ThemeLook.system
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cream, _cream, _navy, _navy],
              stops: [0, .5, .5, 1],
            )
          : null,
    );
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 76,
                padding: const EdgeInsets.all(8),
                decoration: preview,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 26,
                      decoration: BoxDecoration(
                        color: look.card,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 5),
                    _bar(.7, look.line),
                    const SizedBox(height: 5),
                    _bar(.45, look.line),
                    const Spacer(),
                    _bar(.4, const Color(0xFF2A7C13), height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: selected ? AppColors.accent : AppColors.muted,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(color: AppColors.ink).copyWith(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _bar(double width, Color color, {double height = 5}) =>
      FractionallySizedBox(
        widthFactor: width,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      );
}

/// "EN  English": the code in a badge, green when picked.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    inMutuallyExclusiveGroup: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 32),
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: AppText.label(
                  color: selected ? AppColors.onAccent : AppColors.accent,
                ).copyWith(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(color: AppColors.ink)
                    .copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
