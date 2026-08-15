import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miva_fid/core/errors/app_error.dart';
import 'package:miva_fid/core/errors/error_messages.dart';
import 'package:miva_fid/core/errors/form_error_handler.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/features/client/widgets/shared/otp_input_row.dart';

/// Saisie du code reçu lors d'une réinitialisation de mot de passe.
///
/// C'est le seul usage de l'OTP dans l'application : l'API ne vérifie pas le
/// numéro à l'inscription ni à la connexion, qui reposent sur un mot de passe.
/// Le code est produit par `POST /auth/forgot-password` et validé par
/// `POST /auth/verify-otp`, qui renvoie le `reset_token` attendu par l'écran
/// suivant.
class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> with FormErrorHandler {
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onCompleted(String code) async {
    final t = AppLocalizations.of(context)!;

    final resetToken = await runGuarded(
      () => ref
          .read(authProvider.notifier)
          .verifyResetOtp(widget.phoneNumber, code),
      useOverlay: true,
      loadingMessage: t.otpVerifyLoading,
    );

    if (!mounted) return;

    // `runGuarded` renvoie null s'il était déjà occupé, le notifier renvoie
    // null si le code est refusé. Dans les deux cas il n'y a rien à router ;
    // l'erreur éventuelle attend dans `lastError`.
    if (resetToken == null) {
      handleError(
        ref.read(authProvider).lastError,
        context: ErrorContext.verifyOtp,
      );
      return;
    }

    context.push('/client/reset-password', extra: {
      'identifier': widget.phoneNumber,
      'reset_token': resetToken,
    });
  }

  /// Redemande un OTP au serveur — le bouton "Renvoyer" ne redémarrait
  /// auparavant que le décompte local sans jamais réémettre de code.
  Future<void> _resend() async {
    final t = AppLocalizations.of(context)!;

    final sent = await runGuarded(
      () => ref.read(authProvider.notifier).forgotPassword(widget.phoneNumber),
      useOverlay: true,
      loadingMessage: t.forgotPasswordSending,
    );

    if (!mounted || sent == null) return;

    if (sent) {
      showSuccessToast(ErrorMessages.forgotCodeSent);
      _startCountdown();
    } else {
      handleError(
        ref.read(authProvider).lastError,
        context: ErrorContext.forgotPassword,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(title: t.forgotPasswordTitle),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(t.otpTitle, style: AppTextStyles.displayXL()),
            const SizedBox(height: 8),
            Text(
              t.otpSentMessage(widget.phoneNumber.isEmpty
                  ? '+228 •• •• •• ••'
                  : widget.phoneNumber),
              style: AppTextStyles.bodyMedium(
                  color: AppColors.inkMuted(opacity: 0.65)),
            ),
            const SizedBox(height: 44),
            OtpInputRow(onCompleted: _onCompleted),
            const SizedBox(height: 32),
            Center(
              child: _secondsLeft > 0
                  ? Text(
                      t.otpResendCountdown(
                          _secondsLeft.toString().padLeft(2, '0')),
                      style: AppTextStyles.monoSmall(),
                    )
                  : TextButton(
                      onPressed: isBusy ? null : _resend,
                      child: Text(t.otpResendButton,
                          style: AppTextStyles.bodyMedium(
                              color: AppColors.primary)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
