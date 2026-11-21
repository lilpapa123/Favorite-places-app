import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_text_field.dart';
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: authState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.page),
              child: Text(
                'Sign-in is unavailable right now.\n$error',
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
      _showMessage('Enter your email and password');
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
        await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
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
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Type your email first, then tap "Forgot password"');
      return;
    }
    try {
      await ref.read(firebaseAuthProvider).sendPasswordResetEmail(email: email);
      _showMessage('Reset link sent to $email');
    } on FirebaseAuthException catch (error) {
      _showMessage(_messageFor(error));
    }
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email. Sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled in the Firebase console '
            '(Authentication > Sign-in method).';
      default:
        return error.message ?? 'Sign-in failed (${error.code}).';
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
          title: _isSignUp ? 'Create account' : 'Welcome back',
          subtitle: _isSignUp
              ? 'Sign up to keep your places with you'
              : 'Sign in to your account',
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
                    label: 'Email',
                    controller: _emailController,
                    hintText: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    hintText: _isSignUp ? 'At least 6 characters' : '••••••',
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
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isBusy ? null : _resetPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: AppText.label(color: AppColors.accent),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpace.lg),
                  PillButton(
                    label: _isBusy
                        ? 'Please wait...'
                        : (_isSignUp ? 'Create account' : 'Sign in'),
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
              _isSignUp ? 'Already have an account?' : 'New here?',
              style: AppText.meta(),
            ),
            TextButton(
              onPressed: _isBusy
                  ? null
                  : () => setState(() => _isSignUp = !_isSignUp),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: Text(
                _isSignUp ? 'Sign in' : 'Create an account',
                style: AppText.label(color: AppColors.accent),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
          child: Text(
            'Your places stay on this phone either way.',
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

  String get _name {
    final display = user.displayName?.trim() ?? '';
    if (display.isNotEmpty) {
      return display;
    }
    final email = user.email ?? '';
    final local = email.split('@').first;
    return local.isEmpty ? 'You' : local[0].toUpperCase() + local.substring(1);
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: user.displayName ?? '');
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Your name', style: AppText.title()),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'How should we call you?',
            fillColor: AppColors.background,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppText.label(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text('Save', style: AppText.label(color: AppColors.accent)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) {
      return;
    }
    await user.updateDisplayName(name);
    await user.reload();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated')),
      );
    }
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
    final cities = {
      for (final p in places)
        if (p.city.isNotEmpty) p.city,
    }.length;
    final types = {for (final p in places) p.category}.length;
    final photo = user.photoURL;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
      children: [
        const PageHeader(
          title: 'Account',
          subtitle: 'A small collection, all yours.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile card.
              Container(
                padding: const EdgeInsets.all(AppSpace.lg),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardAll,
                ),
                child: Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: photo != null
                            ? Image.network(photo, fit: BoxFit.cover)
                            : Container(
                                color: AppColors.navy,
                                alignment: Alignment.center,
                                child: Text(
                                  _name[0].toUpperCase(),
                                  style: AppText.heading(color: Colors.white),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name,
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
                          Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              places.isEmpty ? 'New explorer' : 'Memory collector',
                              style: AppText.labelMedium(color: AppColors.accent)
                                  .copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              // Stats card.
              Container(
                height: 82,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardAll,
                ),
                child: Row(
                  children: [
                    _Stat(value: places.length, label: places.length == 1 ? 'Place' : 'Places'),
                    const _StatDivider(),
                    _Stat(value: cities, label: cities == 1 ? 'City' : 'Cities'),
                    const _StatDivider(),
                    _Stat(value: types, label: types == 1 ? 'Type' : 'Types'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xxl),
              Text('YOUR SPACE', style: AppText.overline()),
              const SizedBox(height: 9),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardAll,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _SettingRow(
                      icon: 'person_small',
                      iconBackground: AppColors.background,
                      title: 'Profile & preferences',
                      subtitle: 'Make yourself at home',
                      onTap: () => _editName(context),
                    ),
                    const _RowDivider(),
                    _SettingRow(
                      icon: 'lock',
                      iconBackground: AppColors.accentSoft,
                      title: 'Private by default',
                      subtitle: 'Your places are just for you',
                      onTap: () => _info(
                        context,
                        'Private by default',
                        'Your places, photos and notes are kept on this phone. '
                            'Nobody else can see them — not even with your '
                            'account.',
                      ),
                    ),
                    const _RowDivider(),
                    _SettingRow(
                      icon: 'cloud',
                      iconBackground: AppColors.background,
                      title: 'Backup & sync',
                      subtitle: 'Your memories, kept safe',
                      onTap: () => _info(
                        context,
                        'Backup & sync',
                        'Coming soon: your places will be backed up to your '
                            'account, so they follow you to a new phone. For '
                            'now they live on this device only.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardAll,
                ),
                clipBehavior: Clip.antiAlias,
                child: _SettingRow(
                  icon: 'help',
                  title: 'A little help?',
                  height: 56,
                  onTap: () => _info(
                    context,
                    'A little help',
                    'Tap the camera in the middle of the bar to snap a place '
                        'and save it. Give it a name, a type and a note, and '
                        'add a location to see it on the map. Open a place '
                        'to edit it or find it in Maps.',
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              PillButton(
                label: 'Sign out',
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$value', style: AppText.stat()),
          Text(label, style: AppText.meta().copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 38, color: AppColors.divider);
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 60, right: 16),
    child: Divider(height: 1),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconBackground,
    this.height = 58,
  });

  final String icon;
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
                      ? Center(child: AppIcon(icon))
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            color: iconBackground,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(child: AppIcon(icon)),
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
