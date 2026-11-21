import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/providers/auth_provider.dart';

import 'dart:io';

import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/widgets/badge_widgets.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:favorite_places/screens/phone_verify.dart';
import 'package:favorite_places/screens/settings.dart';
import 'package:favorite_places/services/profile_photo.dart';
import 'package:favorite_places/widgets/image_input.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_text_field.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Account tab: a sign-in form when signed out, the profile when signed in.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: authState.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: AppColors.accent)),
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
    );
  }
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
            // Fields sit straight on the gray page, like the add form.
            child: Padding(
              padding: EdgeInsets.zero,
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
                    large: true,
                    expanded: true,
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

  String _name(BuildContext context) {
    final display = user.displayName?.trim() ?? '';
    if (display.isNotEmpty) {
      return display;
    }
    final email = user.email ?? '';
    final local = email.split('@').first;
    return local.isEmpty
        ? context.l10n.you
        : local[0].toUpperCase() + local.substring(1);
  }

  Future<void> _editUsername(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final username = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => _NameDialog(
        initial: current,
        title: l10n.chooseUsername,
        hint: l10n.usernameHint,
      ),
    );
    if (username == null || username.isEmpty || username == current) {
      return;
    }
    void say(String text) =>
        messenger.showSnackBar(SnackBar(content: Text(text)));
    if (!usernamePattern.hasMatch(username)) {
      say(l10n.usernameInvalid);
      return;
    }
    final displayName = _name(context);
    try {
      final ok = await ref
          .read(socialProvider)
          .claimUsername(
            uid: user.uid,
            username: username,
            displayName: displayName,
            photoUrl: user.photoURL,
          );
      say(ok ? l10n.usernameSaved : l10n.usernameTaken);
    } catch (_) {
      say(l10n.somethingWentWrong);
    }
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => _NameDialog(initial: user.displayName ?? ''),
    );
    if (name == null || name.isEmpty) {
      return;
    }
    try {
      await user.updateDisplayName(name);
      await ref.read(socialProvider).updateDisplayName(user.uid, name);
      // userChanges() in authStateProvider picks this up and refreshes
      // the profile card with the new name.
      await user.reload();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.nameUpdated)));
      }
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? context.l10n.couldNotUpdateName),
          ),
        );
      }
    }
  }

  /// Tap on the avatar: take a photo, choose one, or remove it.
  Future<void> _changePhoto(
    BuildContext context,
    WidgetRef ref,
    bool hasPhoto,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            0,
            AppSpace.page,
            AppSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.profilePhoto, style: AppText.title()),
              const SizedBox(height: AppSpace.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.accent,
                ),
                title: Text(context.l10n.takePhoto, style: AppText.row()),
                onTap: () => Navigator.of(ctx).pop('camera'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.accent,
                ),
                title: Text(
                  context.l10n.chooseFromLibrary,
                  style: AppText.row(),
                ),
                onTap: () => Navigator.of(ctx).pop('gallery'),
              ),
              if (hasPhoto)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: AppColors.accent),
                  title: Text(
                    context.l10n.removePhoto,
                    style: AppText.row(color: AppColors.accent),
                  ),
                  onTap: () => Navigator.of(ctx).pop('remove'),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !context.mounted) {
      return;
    }
    final store = ref.read(profilePhotoStoreProvider);
    try {
      if (choice == 'remove') {
        await store.remove(user.uid);
      } else {
        final picked = await ImagePicker().pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 600,
          imageQuality: 85,
          preferredCameraDevice: CameraDevice.front,
        );
        if (picked == null) {
          return;
        }
        await store.save(user.uid, File(picked.path));
      }
      ref.invalidate(profilePhotoProvider(user.uid));
    } on PlatformException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(photoErrorMessage(context.l10n, error))),
        );
      }
    }
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
    final places = ref.watch(userPlacesProvider);
    final username = ref.watch(myProfileProvider).value?.username ?? '';
    final photo = user.photoURL;
    final localPhoto = ref.watch(profilePhotoProvider(user.uid)).value;
    final phone = user.phoneNumber;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
      children: [
        PageHeader(
          title: context.l10n.tabAccount,
          subtitle: context.l10n.accountSubtitle,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile card.
              Container(
                padding: const EdgeInsets.all(AppSpace.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardAll,
                ),
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
                            onTap: () =>
                                _changePhoto(context, ref, localPhoto != null),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipOval(
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: localPhoto != null
                                          ? Image.file(
                                              localPhoto,
                                              fit: BoxFit.cover,
                                              cacheWidth: 216,
                                            )
                                          : photo != null
                                          ? Image.network(
                                              photo,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: AppColors.accent,
                                              alignment: Alignment.center,
                                              child: Text(
                                                _name(context)[0].toUpperCase(),
                                                style: AppText.heading(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  // Small camera badge: "you can change this".
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.surface,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.photo_camera,
                                        size: 13,
                                        color: Colors.white,
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
                    Text(
                      _name(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title().copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.meta().copyWith(height: 1.4),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    EarnedBadgesRow(places: places),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xxl),
              Text(context.l10n.yourSpace, style: AppText.overline()),
              const SizedBox(height: 9),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardAll,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _SettingRow(
                      iconWidget: Icon(
                        Icons.alternate_email,
                        size: 18,
                        color: username.isEmpty
                            ? AppColors.accent
                            : AppColors.muted,
                      ),
                      iconBackground: username.isEmpty
                          ? AppColors.accentSoft
                          : AppColors.background,
                      title: username.isEmpty
                          ? context.l10n.chooseUsername
                          : '@$username',
                      subtitle: username.isEmpty
                          ? context.l10n.chooseUsernameBody
                          : context.l10n.username,
                      onTap: () => _editUsername(context, ref, username),
                    ),
                    const _RowDivider(),
                    _SettingRow(
                      iconWidget: Icon(
                        phone == null || phone.isEmpty
                            ? Icons.phone_iphone
                            : Icons.verified_outlined,
                        size: 18,
                        color: phone == null || phone.isEmpty
                            ? AppColors.muted
                            : AppColors.success,
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
                      onTap: () => _editName(context, ref),
                    ),
                    const _RowDivider(),
                    _SettingRow(
                      iconWidget: Icon(
                        Icons.tune,
                        size: 18,
                        color: AppColors.muted,
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
              const SizedBox(height: AppSpace.lg),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardAll,
                ),
                clipBehavior: Clip.antiAlias,
                child: _SettingRow(
                  icon: 'help',
                  title: context.l10n.aLittleHelpQ,
                  height: 56,
                  onTap: () => _info(
                    context,
                    context.l10n.aLittleHelp,
                    context.l10n.helpBody,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              PillButton(
                label: context.l10n.signOut,
                leading: const AppIcon('logout'),
                variant: PillButtonVariant.outlined,
                expanded: true,
                onPressed: () => ref.read(firebaseAuthProvider).signOut(),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
    this.height = 58,
  });

  /// Design icon name, or [iconWidget] for one the design doesn't have.
  final String? icon;
  final Widget? iconWidget;
  final String title;
  final String? subtitle;
  final Color? iconBackground;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: iconBackground == null
                      ? Center(child: iconWidget ?? AppIcon(icon!))
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            color: iconBackground,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(child: iconWidget ?? AppIcon(icon!)),
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

/// "Your name" dialog. It owns its text controller and disposes it only once
/// the dialog has fully closed — disposing it right after `showDialog`
/// returns crashes, because the field is still on screen while the dialog
/// animates out.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial, this.title, this.hint});

  final String initial;

  /// Defaults to the "Your name" texts.
  final String? title;
  final String? hint;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(
        widget.title ?? context.l10n.yourName,
        style: AppText.title(),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: widget.title == null
            ? TextCapitalization.words
            : TextCapitalization.none,
        autocorrect: widget.title == null,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          hintText: widget.hint ?? context.l10n.yourNameHint,
          fillColor: AppColors.background,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            context.l10n.cancel,
            style: AppText.label(color: AppColors.muted),
          ),
        ),
        TextButton(
          onPressed: _save,
          child: Text(
            context.l10n.save,
            style: AppText.label(color: AppColors.accent),
          ),
        ),
      ],
    );
  }
}
