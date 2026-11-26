import 'dart:async';
import 'dart:math' as math;

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_text_field.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Adds a verified phone number to the signed-in account with a one-time
/// SMS code (Firebase Phone Auth):
///   1. enter the number (with country code) and tap "Send code";
///   2. type the 6-digit code from the SMS and tap "Verify".
/// The number is then linked to the account; on Android the code is often
/// read automatically.
class PhoneVerifyScreen extends ConsumerStatefulWidget {
  const PhoneVerifyScreen({super.key});

  @override
  ConsumerState<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends ConsumerState<PhoneVerifyScreen> {
  static const int _resendSeconds = 60;

  final TextEditingController _phone = TextEditingController(text: '+90 ');
  final TextEditingController _code = TextEditingController();

  String? _verificationId;
  int? _resendToken;
  bool _busy = false;
  int _secondsLeft = 0;
  Timer? _timer;

  bool get _codeSent => _verificationId != null;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  /// "+90 555 123 45 67" -> "+905551234567"
  String get _e164 => _phone.text.replaceAll(RegExp(r'[^\d+]'), '');

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _secondsLeft <= 1) {
        timer.cancel();
      }
      if (mounted) {
        setState(() => _secondsLeft = _secondsLeft > 0 ? _secondsLeft - 1 : 0);
      }
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    final number = _e164;
    if (!RegExp(r'^\+\d{8,15}$').hasMatch(number)) {
      _showMessage(context.l10n.enterNumberWithCode);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    await ref
        .read(firebaseAuthProvider)
        .verifyPhoneNumber(
          phoneNumber: number,
          forceResendingToken: resend ? _resendToken : null,
          timeout: const Duration(seconds: 60),
          // Android only: the SMS was read automatically.
          verificationCompleted: (credential) => _link(credential),
          verificationFailed: (error) {
            if (!mounted) return;
            setState(() => _busy = false);
            _showMessage(_messageFor(error));
          },
          codeSent: (verificationId, resendToken) {
            if (!mounted) return;
            setState(() {
              _busy = false;
              _verificationId = verificationId;
              _resendToken = resendToken;
            });
            _startTimer();
            _showMessage(context.l10n.codeSentTo(number));
          },
          codeAutoRetrievalTimeout: (verificationId) {
            _verificationId ??= verificationId;
          },
        );
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    final id = _verificationId;
    if (id == null || code.length != 6) {
      _showMessage(context.l10n.enter6DigitCode);
      return;
    }
    FocusScope.of(context).unfocus();
    await _link(
      PhoneAuthProvider.credential(verificationId: id, smsCode: code),
    );
  }

  /// Links the phone to the account (or replaces an earlier number).
  Future<void> _link(PhoneAuthCredential credential) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      _showMessage(context.l10n.signInFirstForPhone);
      return;
    }
    setState(() => _busy = true);
    try {
      if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
        await user.linkWithCredential(credential);
      } else {
        await user.updatePhoneNumber(credential);
      }
      await user.reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.phoneVerified)));
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return context.l10n.errInvalidPhone;
      case 'invalid-verification-code':
        return context.l10n.errInvalidCode;
      case 'session-expired':
      case 'code-expired':
        return context.l10n.errCodeExpired;
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return context.l10n.errNumberInUse;
      case 'provider-already-linked':
        return context.l10n.errAlreadyHasPhone;
      case 'too-many-requests':
        return context.l10n.errTooManyAttemptsLong;
      case 'quota-exceeded':
        return context.l10n.errSmsQuota;
      case 'operation-not-allowed':
        return context.l10n.errPhoneNotEnabled;
      case 'network-request-failed':
        return context.l10n.noConnection;
      default:
        return error.message ?? context.l10n.errVerificationFailed(error.code);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _press(String key) {
    final code = _code.text;
    if (key == 'del') {
      if (code.isNotEmpty) {
        setState(() => _code.text = code.substring(0, code.length - 1));
      }
    } else if (code.length < 6) {
      setState(() => _code.text = code + key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = _code.text;
    final full = code.length == 6;
    final number = _phone.text.trim();
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [AppColors.accentSoft, AppColors.background],
            stops: const [0, .6],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Row(
                children: [
                  CircleIconButton(
                    icon: AppIcon('back', color: AppColors.ink),
                    semanticLabel: l10n.back,
                    background: AppColors.surface.withValues(alpha: .9),
                    onPressed: () => _codeSent
                        ? setState(() {
                            _verificationId = null;
                            _code.clear();
                            _timer?.cancel();
                          })
                        : Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      children: [
                        AppIcon('lock', size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          l10n.secureStep,
                          style: AppText.label(color: AppColors.accent)
                              .copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Center(child: _PhoneArt()),
              const SizedBox(height: 20),
              Text(
                _codeSent ? l10n.checkYourMessages : l10n.phoneNumber,
                textAlign: TextAlign.center,
                style: AppText.display().copyWith(
                  fontSize: 30,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              if (_codeSent)
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.weSentCodeTo(number),
                      textAlign: TextAlign.center,
                      style: AppText.body(color: AppColors.muted)
                          .copyWith(fontSize: 15, height: 1.45),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _verificationId = null;
                        _code.clear();
                        _timer?.cancel();
                      }),
                      child: Text(
                        l10n.change,
                        style: AppText.label(color: AppColors.accent),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  l10n.wellTextYouCode,
                  textAlign: TextAlign.center,
                  style: AppText.body(color: AppColors.muted)
                      .copyWith(fontSize: 15, height: 1.45),
                ),
              const SizedBox(height: 20),
              if (!_codeSent) ...[
                AppTextField(
                  label: l10n.phoneNumber,
                  controller: _phone,
                  hintText: '+90 555 123 45 67',
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendCode(),
                ),
                const SizedBox(height: AppSpace.xl),
                PillButton(
                  label: _busy ? l10n.pleaseWait : l10n.sendCode,
                  large: true,
                  expanded: true,
                  onPressed: _busy ? null : _sendCode,
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  l10n.smsRatesNote,
                  textAlign: TextAlign.center,
                  style: AppText.meta(color: AppColors.faint)
                      .copyWith(fontSize: 12),
                ),
              ] else ...[
                Semantics(
                  label: l10n.sixDigitCode,
                  value: '${code.length}/6',
                  child: Row(
                    children: [
                      for (var i = 0; i < 6; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _CodeBox(
                            digit: i < code.length ? code[i] : '',
                            active: i == code.length,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: _secondsLeft > 0
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(
                                value: _secondsLeft / _resendSeconds,
                                strokeWidth: 3,
                                color: AppColors.accent,
                                backgroundColor: AppColors.divider,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.sendNewCodeIn(_secondsLeft),
                              style: AppText.label(color: AppColors.muted)
                                  .copyWith(fontSize: 13),
                            ),
                          ],
                        )
                      : TextButton(
                          onPressed: _busy
                              ? null
                              : () => _sendCode(resend: true),
                          child: Text(
                            l10n.sendNewCode,
                            style: AppText.label(color: AppColors.accent),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: [
                    for (final key in [
                      '1',
                      '2',
                      '3',
                      '4',
                      '5',
                      '6',
                      '7',
                      '8',
                      '9',
                      '',
                      '0',
                      'del',
                    ])
                      key.isEmpty
                          ? const SizedBox.shrink()
                          : _Key(
                              label: key == 'del' ? l10n.deleteDigit : key,
                              onTap: () => _press(key),
                              plain: key == 'del',
                              child: key == 'del'
                                  ? AppIcon('back', color: AppColors.ink)
                                  : Text(
                                      key,
                                      style: AppText.heading().copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                  ],
                ),
                const SizedBox(height: 20),
                PillButton(
                  label: _busy
                      ? l10n.pleaseWait
                      : full
                      ? l10n.verify
                      : l10n.enterAll6Digits,
                  icon: Icons.arrow_forward_rounded,
                  large: true,
                  expanded: true,
                  onPressed: _busy || !full ? null : _verify,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One code box: the digit, or a blinking caret in the next empty one.
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.digit, required this.active});

  final String digit;
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.fast,
    height: 60,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        width: 2,
        color: active
            ? AppColors.accent
            : digit.isNotEmpty
            ? const Color(0xFF76C457)
            : AppColors.divider,
      ),
      boxShadow: active
          ? [
              BoxShadow(
                color: const Color(0xFF76C457).withValues(alpha: .25),
                spreadRadius: 4,
              ),
            ]
          : null,
    ),
    child: digit.isNotEmpty
        ? Text(digit, style: AppText.heading().copyWith(fontSize: 26))
        : active
        ? Container(width: 2, height: 26, color: AppColors.accent)
        : null,
  );
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    required this.child,
    this.plain = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  /// No fill, for the delete key.
  final bool plain;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: Material(
      color: plain
          ? Colors.transparent
          : AppColors.surface.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(child: child),
      ),
    ),
  );
}

/// A phone receiving the code: pulsing rings around a green disc, the phone
/// floating, a bubble with the first digits.
class _PhoneArt extends StatefulWidget {
  const _PhoneArt();

  @override
  State<_PhoneArt> createState() => _PhoneArtState();
}

class _PhoneArtState extends State<_PhoneArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const light = Color(0xFF76C457);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 170,
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, _) {
            final t = _loop.value;
            // Two rings, half a beat apart, each growing and fading.
            Widget ring(double offset) {
              final p = (t * 2 + offset) % 1;
              return Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Transform.scale(
                    scale: .85 + .5 * p,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: light.withValues(alpha: .55 * (1 - p)),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final float = -6 * (1 - math.cos(2 * math.pi * t)) / 2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                ring(0),
                ring(.5),
                const Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [light, Color(0xFF2A7C13)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 58,
                  top: 34 + float,
                  child: Transform.rotate(
                    angle: -6 * math.pi / 180,
                    child: Container(
                      width: 54,
                      height: 96,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15171C),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x590A2806),
                            blurRadius: 28,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(6, 14, 6, 0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8CF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _line(.7, const Color(0xFFDCCF9E)),
                            const SizedBox(height: 4),
                            _line(.5, const Color(0xFFDCCF9E)),
                            const SizedBox(height: 4),
                            _line(.8, light),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -14,
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBE6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                        bottomLeft: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2A7C13).withValues(alpha: .25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      '4 8 2 •••',
                      style: AppText.heading(color: const Color(0xFF2A7C13))
                          .copyWith(fontSize: 14, letterSpacing: 2),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _line(double width, Color color) => FractionallySizedBox(
    widthFactor: width,
    child: Container(
      height: 5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    ),
  );
}
