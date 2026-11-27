import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:favorite_places/services/profile_photo.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_text_field.dart';
import 'package:favorite_places/widgets/golden_hour.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:favorite_places/widgets/profile_photo_picker.dart';
import 'package:favorite_places/widgets/social_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Profile & preferences": photo, optional name, required username and bio.
///
/// The photo saves as soon as it is picked. Name, username and bio live in
/// Firestore; the sign-in account only gets a copy of the name.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.user,
    required this.shownName,
    this.setup = false,
  });

  final User user;

  /// The name, or the username or email when there is none. Only for the
  /// avatar's letter, never saved.
  final String shownName;

  /// Stands in for Account until a username is picked: there is nothing to
  /// close, so it offers signing out instead.
  final bool setup;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  /// Only a first suggestion, for before there is a profile.
  late final String _accountName = widget.user.displayName?.trim() ?? '';
  late final _name = TextEditingController(text: _accountName);
  final _username = TextEditingController();
  final _bio = TextEditingController();

  /// As stored online; null until loaded. Only differences from it are
  /// written, so a profile that failed to load is never overwritten by blanks.
  UserProfile? _saved;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(myProfileProvider, (_, next) {
      final profile = next.value;
      if (profile == null || _saved != null) {
        return;
      }
      _saved = profile;
      // It can arrive late: don't replace what is already being typed.
      if (_name.text == _accountName) {
        _name.text = profile.displayName;
      }
      if (_username.text.isEmpty) {
        _username.text = profile.username;
      }
      if (_bio.text.isEmpty) {
        _bio.text = profile.bio;
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    void say(String text) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));

    final name = _name.text.trim();
    final username = _username.text.trim().replaceFirst(RegExp('^@'), '');
    final bio = _bio.text.trim();
    final usernameChanged = username != (_saved?.username ?? '');
    final bioChanged = bio != (_saved?.bio ?? '');
    if (username.isEmpty) {
      say(l10n.usernameRequired);
      return;
    }
    if (usernameChanged && !usernamePattern.hasMatch(username)) {
      say(l10n.usernameInvalid);
      return;
    }

    FocusScope.of(context).unfocus();
    final social = ref.read(socialProvider);
    final user = widget.user;
    setState(() => _saving = true);
    try {
      final saved = await social.saveProfile(
        uid: user.uid,
        displayName: name,
        username: usernameChanged ? username : null,
        bio: bioChanged ? bio : null,
      );
      if (!saved) {
        say(l10n.usernameTaken);
        return;
      }
      if (name != _accountName) {
        try {
          // '' and not null: the iOS SDK leaves null out of the request, so
          // the old name would come straight back.
          await user.updateDisplayName(name);
          await user.reload();
        } on Exception catch (error) {
          // Only the copy: the saved profile is what the app shows.
          debugPrint('Account name copy failed: $error');
        }
      }
      say(l10n.profileSaved);
      // In setup, Account replaces this screen once the profile arrives.
      if (mounted && !widget.setup) {
        Navigator.of(context).pop();
      }
    } on Exception catch (error) {
      debugPrint('Profile save failed: $error');
      say(l10n.profileSaveFailed);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final uid = widget.user.uid;
    final photo = ref.watch(profilePhotoProvider(uid)).value;
    final shared =
        ref.watch(myProfileProvider).value?.photoUrl ?? widget.user.photoURL;
    void changePhoto() => changeProfilePhoto(
      context,
      uid: uid,
      hasPhoto: photo != null || shared != null,
    );

    return Scaffold(
      body: GoldenHour(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              PageHeader(
                title: widget.setup
                    ? l10n.chooseUsername
                    : l10n.profilePreferences,
                subtitle: widget.setup
                    ? l10n.chooseUsernameBody
                    : l10n.makeYourselfAtHome,
                trailing: widget.setup
                    ? null
                    : CircleIconButton(
                        icon: AppIcon('close', color: AppColors.ink),
                        background: AppColors.surface.withValues(alpha: .82),
                        semanticLabel: l10n.close,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
                child: Container(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  decoration: GoldenHour.card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: changePhoto,
                            // The button beside it is the accessible way.
                            excludeFromSemantics: true,
                            child: Container(
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
                              child: Avatar(
                                name: widget.shownName,
                                image: photo,
                                photoUrl: shared,
                                size: 84,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: changePhoto,
                                  icon: Icon(
                                    Icons.photo_camera_outlined,
                                    size: 16,
                                    color: AppColors.accent,
                                  ),
                                  label: Text(
                                    l10n.changePhoto,
                                    style: AppText.label(
                                      color: AppColors.accent,
                                    ).copyWith(fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.accent,
                                      width: 1.5,
                                    ),
                                    shape: const StadiumBorder(),
                                    minimumSize: const Size(0, 36),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.photoOnThisPhone,
                                  style: AppText.meta().copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      AppTextField(
                        label: l10n.yourName,
                        trailingLabel: l10n.optional,
                        controller: _name,
                        hintText: l10n.yourNameHint,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: AppSpace.lg),
                      AppTextField(
                        label: l10n.username,
                        controller: _username,
                        hintText: l10n.usernameHint,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpace.lg),
                      AppTextField(
                        label: l10n.bio,
                        trailingLabel: l10n.optional,
                        controller: _bio,
                        hintText: l10n.bioHint,
                        maxLines: 3,
                        maxLength: maxBioLength,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      PillButton(
                        label: _saving ? l10n.pleaseWait : l10n.saveChanges,
                        large: true,
                        expanded: true,
                        glow: true,
                        onPressed: _saving ? null : _save,
                      ),
                      if (widget.setup) ...[
                        const SizedBox(height: AppSpace.md),
                        PillButton(
                          label: l10n.signOut,
                          variant: PillButtonVariant.outlined,
                          expanded: true,
                          onPressed: _saving
                              ? null
                              : () => ref.read(firebaseAuthProvider).signOut(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
