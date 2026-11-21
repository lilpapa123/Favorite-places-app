import 'dart:async';

import 'package:favorite_places/providers/auth_provider.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_text_field.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      _showMessage('Enter your number with the country code, e.g. +90 555 123 45 67');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    await ref.read(firebaseAuthProvider).verifyPhoneNumber(
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
        _showMessage('Code sent to $number');
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
      _showMessage('Enter the 6-digit code from the SMS');
      return;
    }
    FocusScope.of(context).unfocus();
    await _link(PhoneAuthProvider.credential(verificationId: id, smsCode: code));
  }

  /// Links the phone to the account (or replaces an earlier number).
  Future<void> _link(PhoneAuthCredential credential) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      _showMessage('Sign in first to add a phone number.');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number verified')),
      );
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
        return 'That phone number doesn\'t look right. Include the country code.';
      case 'invalid-verification-code':
        return 'That code isn\'t right. Check the SMS and try again.';
      case 'session-expired':
      case 'code-expired':
        return 'The code expired. Tap "Send a new code".';
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return 'This number is already used by another account.';
      case 'provider-already-linked':
        return 'This account already has a phone number.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a while and try again.';
      case 'quota-exceeded':
        return 'SMS limit reached for today. Try again later.';
      case 'operation-not-allowed':
        return 'Phone sign-in is not enabled in the Firebase console '
            '(Authentication > Sign-in method > Phone).';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      default:
        return error.message ?? 'Verification failed (${error.code}).';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            PageHeader(
              title: 'Phone number',
              subtitle: _codeSent
                  ? 'Enter the code we sent by SMS.'
                  : 'We\'ll text you a code to verify it.',
              trailing: CircleIconButton(
                icon: const AppIcon('close'),
                semanticLabel: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Phone number',
                    controller: _phone,
                    hintText: '+90 555 123 45 67',
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _codeSent ? null : _sendCode(),
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: AppSpace.lg),
                    Text('6-digit code', style: AppText.labelMedium()),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _code,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      textAlign: TextAlign.center,
                      style: AppText.heading().copyWith(letterSpacing: 12),
                      cursorColor: AppColors.accent,
                      decoration: const InputDecoration(hintText: '••••••'),
                      onChanged: (value) {
                        if (value.length == 6) {
                          _verify();
                        }
                      },
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _busy || _secondsLeft > 0
                            ? null
                            : () => _sendCode(resend: true),
                        child: Text(
                          _secondsLeft > 0
                              ? 'Send a new code in ${_secondsLeft}s'
                              : 'Send a new code',
                          style: AppText.label(
                            color: _secondsLeft > 0
                                ? AppColors.faint
                                : AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.xxl),
                  PillButton(
                    label: _busy
                        ? 'Please wait...'
                        : (_codeSent ? 'Verify' : 'Send code'),
                    large: true,
                    expanded: true,
                    onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    'Standard SMS rates may apply. Your number is only used '
                    'to secure your account.',
                    textAlign: TextAlign.center,
                    style: AppText.meta(color: AppColors.faint)
                        .copyWith(fontSize: 12),
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
