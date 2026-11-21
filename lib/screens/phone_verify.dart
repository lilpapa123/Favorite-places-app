import 'dart:async';

import 'package:favorite_places/l10n/l10n.dart';
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
      _showMessage(context.l10n.enterNumberWithCode);
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
    await _link(PhoneAuthProvider.credential(verificationId: id, smsCode: code));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.phoneVerified)),
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
              title: context.l10n.phoneNumber,
              subtitle: _codeSent
                  ? context.l10n.enterCodeWeSent
                  : context.l10n.wellTextYouCode,
              trailing: CircleIconButton(
                icon: const AppIcon('close'),
                semanticLabel: context.l10n.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: context.l10n.phoneNumber,
                    controller: _phone,
                    hintText: '+90 555 123 45 67',
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _codeSent ? null : _sendCode(),
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: AppSpace.lg),
                    Text(context.l10n.sixDigitCode, style: AppText.labelMedium()),
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
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: _busy || _secondsLeft > 0
                            ? null
                            : () => _sendCode(resend: true),
                        child: Text(
                          _secondsLeft > 0
                              ? context.l10n.sendNewCodeIn(_secondsLeft)
                              : context.l10n.sendNewCode,
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
                        ? context.l10n.pleaseWait
                        : (_codeSent ? context.l10n.verify : context.l10n.sendCode),
                    large: true,
                    expanded: true,
                    onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    context.l10n.smsRatesNote,
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
