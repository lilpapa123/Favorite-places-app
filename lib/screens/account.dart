import 'package:favorite_places/screens/palces.dart';
import 'package:favorite_places/widgets/places_grid.dart';
import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/providers/auth_provider.dart';

import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/widgets/badge_widgets.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:favorite_places/screens/edit_profile.dart';
import 'package:favorite_places/screens/world_map.dart';
import 'package:favorite_places/screens/phone_verify.dart';
import 'package:favorite_places/screens/settings.dart';
import 'package:favorite_places/services/profile_photo.dart';
import 'package:favorite_places/widgets/profile_photo_picker.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_text_field.dart';
import 'package:favorite_places/widgets/golden_hour.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Account tab: a sign-in form when signed out, the profile when signed in.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final profile = ref.watch(myProfileProvider);
    final user = authState.value;

    // A username is required. Only ask once it's known to be missing: while
    // loading or after an error the account stays usable.
    if (user != null &&
        profile.hasValue &&
        (profile.value?.username ?? '').isEmpty) {
      return EditProfileScreen(
        // Keeps what is typed when the account refreshes mid-save.
        key: ValueKey(user.uid),
        user: user,
        shownName: _shownName(
          context,
          user,
          user.displayName?.trim() ?? '',
          '',
        ),
        setup: true,
      );
    }

    return Scaffold(
      body: GoldenHour(
        child: SafeArea(
          bottom: false,
          child: authState.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.page),
                child: Text(
                  context.l10n.signInUnavailable('$error'),
                  textAlign: TextAlign.center,
                  style: AppText.meta(),
                ),
              ),
            ),
            data: (user) =>
                user == null ? const _SignInForm() : _Profile(user: user),
          ),
        ),
      ),
    );
  }
}

/// The name, else the username, else the start of the email: for the avatar's
/// letter. The name line on Account only ever shows a real name.
String _shownName(
  BuildContext context,
  User user,
  String name,
  String username,
) {
  if (name.isNotEmpty) {
    return name;
  }
  if (username.isNotEmpty) {
    return username;
  }
  final email = user.email ?? '';
  final local = email.split('@').first;
  return local.isEmpty
      ? context.l10n.you
      : local[0].toUpperCase() + local.substring(1);
}

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm();

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isBusy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage(context.l10n.enterEmailPassword);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isBusy = true);
    final auth = ref.read(firebaseAuthProvider);
    try {
      if (_isSignUp) {
        await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      }
      // authStateProvider swaps this form for the profile automatically.
    } on FirebaseAuthException catch (error) {
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage(l10n.typeEmailFirst);
      return;
    }
    try {
      await ref.read(firebaseAuthProvider).sendPasswordResetEmail(email: email);
      _showMessage(l10n.resetLinkSent(email));
    } on FirebaseAuthException catch (error) {
      _showMessage(_messageFor(error));
    }
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return context.l10n.errInvalidEmail;
      case 'user-disabled':
        return context.l10n.errUserDisabled;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return context.l10n.errWrongCredentials;
      case 'email-already-in-use':
        return context.l10n.errEmailInUse;
      case 'weak-password':
        return context.l10n.errWeakPassword;
      case 'too-many-requests':
        return context.l10n.errTooManyAttempts;
      case 'network-request-failed':
        return context.l10n.noConnection;
      case 'operation-not-allowed':
        return context.l10n.errEmailNotEnabled;
      default:
        return error.message ?? context.l10n.errSignInFailed(error.code);
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
      children: [
        PageHeader(
          title: _isSignUp
              ? context.l10n.createAccount
              : context.l10n.welcomeBack,
          subtitle: _isSignUp
              ? context.l10n.signUpSubtitle
              : context.l10n.signInSubtitle,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.sm,
            AppSpace.page,
            0,
          ),
          child: AutofillGroup(
            // The form on a frosted card over the golden wash.
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: GoldenHour.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: context.l10n.email,
                    controller: _emailController,
                    hintText: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppTextField(
                    label: context.l10n.password,
                    controller: _passwordController,
                    hintText: _isSignUp ? context.l10n.atLeast6Chars : '••••••',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    autofillHints: [
                      _isSignUp
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                  ),
                  if (!_isSignUp)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: _isBusy ? null : _resetPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                        ),
                        child: Text(
                          context.l10n.forgotPassword,
                          style: AppText.label(color: AppColors.accent),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpace.lg),
                  PillButton(
                    label: _isBusy
                        ? context.l10n.pleaseWait
                        : (_isSignUp
                              ? context.l10n.createAccount
                              : context.l10n.signIn),
                    icon: Icons.arrow_forward_rounded,
                    large: true,
                    expanded: true,
                    glow: true,
                    onPressed: _isBusy ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isSignUp
                  ? context.l10n.alreadyHaveAccount
                  : context.l10n.newHere,
              style: AppText.meta(),
            ),
            TextButton(
              onPressed: _isBusy
                  ? null
                  : () => setState(() => _isSignUp = !_isSignUp),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: Text(
                _isSignUp ? context.l10n.signIn : context.l10n.createAnAccount,
                style: AppText.label(color: AppColors.accent),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
          child: Text(
            context.l10n.placesStayOnPhone,
            textAlign: TextAlign.center,
            style: AppText.meta(color: AppColors.faint),
          ),
        ),
      ],
    );
  }
}

class _Profile extends ConsumerWidget {
  const _Profile({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(userPlacesProvider);
    final profile = ref.watch(myProfileProvider).value;
    final bio = profile?.bio ?? '';
    final username = profile?.username ?? '';
    // From the profile, as everyone else sees it. The copy on the sign-in
    // account can still hold a name that was removed.
    final name = profile?.displayName ?? '';
    final shownName = _shownName(context, user, name, username);
    final photo = profile?.photoUrl ?? user.photoURL;
    final localPhoto = ref.watch(profilePhotoProvider(user.uid)).value;
    return ListView(
      padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
      children: [
        PageHeader(
          title: username.isEmpty ? context.l10n.tabAccount : username,
          titleIsUsername: username.isNotEmpty,
          subtitle: context.l10n.accountSubtitle,
          trailing: CircleIconButton(
            icon: Icon(Icons.menu_rounded, color: AppColors.ink),
            semanticLabel: context.l10n.menu,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (ctx) =>
                    _AccountMenu(user: user, shownName: shownName),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile card, frosted over the golden wash.
              Container(
                padding: const EdgeInsets.all(AppSpace.lg),
                decoration: GoldenHour.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instagram-style: photo with the counters beside it, then
                    // name, email and badge underneath.
                    Row(
                      children: [
                        Semantics(
                          button: true,
                          label: context.l10n.changeProfilePhoto,
                          excludeSemantics: true,
                          child: GestureDetector(
                            onTap: () => changeProfilePhoto(
                              context,
                              uid: user.uid,
                              hasPhoto: localPhoto != null || photo != null,
                            ),
                            child: Container(
                              width: 72,
                              height: 72,
                              // A cream ring inside a light-green one.
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2A7C13)
                                        .withValues(alpha: .3),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                  const BoxShadow(
                                    color: Color(0xFF76C457),
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: AppColors.surface,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipOval(
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      // The shared photo is the same on
                                      // every phone; this phone's file is
                                      // only for when there is none yet.
                                      child: photo != null
                                          ? Image(
                                              image: sharedPhoto(photo),
                                              fit: BoxFit.cover,
                                            )
                                          : localPhoto != null
                                          ? Image.file(
                                              localPhoto,
                                              fit: BoxFit.cover,
                                              cacheWidth: 216,
                                            )
                                          : Container(
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color(0xFF2A7C13),
                                                    Color(0xFF76C457),
                                                  ],
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                shownName[0].toUpperCase(),
                                                style: AppText.heading(
                                                  color: Colors.white,
                                                ).copyWith(fontSize: 28),
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: ProfileStats(
                            uid: user.uid,
                            places: places.length,
                            card: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (name.isNotEmpty) ...[
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.title().copyWith(height: 1.4),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                user.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.meta().copyWith(height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        WorldMapButton(uid: user.uid),
                      ],
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(bio, style: AppText.note()),
                    ],
                    const SizedBox(height: AppSpace.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: EarnedBadgesRow(places: places),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xxl),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.yourPlaces,
                      style: AppText.overline(),
                    ),
                  ),
                  if (places.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (ctx) => const PalcesScreen(),
                        ),
                      ),
                      child: Text(
                        context.l10n.seeAll,
                        style: AppText.label(color: AppColors.accent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              if (places.isEmpty)
                Text(context.l10n.noPlacesYetHint, style: AppText.meta())
              else
                PlacesGrid(places: places),
            ],
          ),
        ),
      ],
    );
  }
}

/// The Account menu (top-left button): phone, profile, settings, privacy,
/// backup, and help.
class _AccountMenu extends ConsumerWidget {
  const _AccountMenu({required this.user, required this.shownName});

  final User user;
  final String shownName;

  void _editProfile(BuildContext context, String shownName) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => EditProfileScreen(user: user, shownName: shownName),
      ),
    );
  }

  void _verifyPhone(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (ctx) => const PhoneVerifyScreen()),
    );
  }

  void _info(BuildContext context, String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            0,
            AppSpace.page,
            AppSpace.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.title()),
              const SizedBox(height: AppSpace.sm),
              Text(body, style: AppText.note(color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live, so a number verified here shows when coming back.
    final phone = (ref.watch(authStateProvider).value ?? user).phoneNumber;
    return Scaffold(
      body: GoldenHour(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
            children: [
              PageHeader(
                leading: CircleIconButton(
                  icon: AppIcon('back', color: AppColors.ink),
                  semanticLabel: context.l10n.back,
                  background: AppColors.surface.withValues(alpha: .82),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: context.l10n.menu,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.l10n.yourSpace, style: AppText.overline()),
                    const SizedBox(height: 9),
                    Container(
                      decoration: GoldenHour.card(),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _SettingRow(
                            iconWidget: Icon(
                              phone == null || phone.isEmpty
                                  ? Icons.phone_iphone
                                  : Icons.verified_outlined,
                              size: 18,
                              color: AppColors.accent,
                            ),
                            iconBackground: phone == null || phone.isEmpty
                                ? AppColors.background
                                : AppColors.successSoft,
                            title: phone == null || phone.isEmpty
                                ? context.l10n.phoneNumber
                                : phone,
                            subtitle: phone == null || phone.isEmpty
                                ? context.l10n.verifyWithSms
                                : context.l10n.verifiedTapToChange,
                            onTap: () => _verifyPhone(context),
                          ),
                          const _RowDivider(),
                          _SettingRow(
                            icon: 'person_small',
                            iconBackground: AppColors.background,
                            title: context.l10n.profilePreferences,
                            subtitle: context.l10n.makeYourselfAtHome,
                            onTap: () => _editProfile(context, shownName),
                          ),
                          const _RowDivider(),
                          _SettingRow(
                            iconWidget: Icon(
                              Icons.tune,
                              size: 18,
                              color: AppColors.accent,
                            ),
                            iconBackground: AppColors.background,
                            title: context.l10n.settingsTitle,
                            subtitle: context.l10n.settingsRowSubtitle,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (ctx) => const SettingsScreen(),
                              ),
                            ),
                          ),
                          const _RowDivider(),
                          _SettingRow(
                            icon: 'lock',
                            iconBackground: AppColors.accentSoft,
                            title: context.l10n.privateByDefault,
                            subtitle: context.l10n.placesJustForYou,
                            onTap: () => _info(
                              context,
                              context.l10n.privateByDefault,
                              context.l10n.privateBody,
                            ),
                          ),
                          const _RowDivider(),
                          _SettingRow(
                            icon: 'cloud',
                            iconBackground: AppColors.background,
                            title: context.l10n.backupSync,
                            subtitle: context.l10n.memoriesKeptSafe,
                            onTap: () => _info(
                              context,
                              context.l10n.backupSync,
                              context.l10n.backupBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _HelpCard(
                      label: context.l10n.aLittleHelpQ,
                      onTap: () => _info(
                        context,
                        context.l10n.aLittleHelp,
                        context.l10n.helpBody,
                      ),
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

/// "A little help?" on gradient green.
class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2A7C13), Color(0xFF4E9E33)],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2A7C13).withValues(alpha: .3),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const AppIcon('help', size: 22, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppText.bodyStrong(color: Colors.white)
                      .copyWith(fontSize: 15),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.only(start: 60, end: 16),
    child: Divider(height: 1),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    this.icon,
    this.iconWidget,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconBackground,
  });

  /// Design icon name, or [iconWidget] for one the design doesn't have.
  final String? icon;
  final Widget? iconWidget;
  final String title;
  final String? subtitle;
  final Color? iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accentSoft,
                        AppColors.isDark
                            ? AppColors.surface
                            : const Color(0xFFFFF1D6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child:
                        iconWidget ??
                        AppIcon(icon!, size: 18, color: AppColors.accent),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.row()),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppText.meta().copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const AppIcon('chevron_small'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
