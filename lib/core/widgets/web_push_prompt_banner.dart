import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/client/providers/device_token_provider.dart';
import '../services/notification_service.dart';
import '../services/web_push_interop.dart';
import '../theme/app_colors.dart';
import '../utils/toast_service.dart';

/// Gère l'affichage d'un grand popup modal sur le Web / PWA lorsque
/// l'autorisation de notifications Push n'a pas encore été accordée.
///
/// L'utilisateur doit autoriser les notifications (ou est guidé pas à pas
/// pour les réactiver si le navigateur les a déjà bloquées).
class WebPushPromptBanner extends ConsumerStatefulWidget {
  const WebPushPromptBanner({super.key});

  @override
  ConsumerState<WebPushPromptBanner> createState() =>
      _WebPushPromptBannerState();
}

class _WebPushPromptBannerState extends ConsumerState<WebPushPromptBanner> {
  static bool _sessionDismissedForUnsupported = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && !_sessionDismissedForUnsupported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndPrompt();
      });
    }
  }

  Future<void> _checkAndPrompt() async {
    if (!mounted || _dialogOpen || _sessionDismissedForUnsupported) return;
    final state = await NotificationService().getWebPermissionState();
    if (!mounted) return;

    if (state == WebPushPermissionState.granted) {
      // S'assurer que le token est bien synchronisé avec le backend.
      ref.read(deviceTokenProvider).registerCurrentToken();
      return;
    }

    if (state == WebPushPermissionState.unsupported) {
      return;
    }

    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => _WebPushPermissionDialog(
        initialState: state,
        onCompleted: () {
          _sessionDismissedForUnsupported = true;
        },
      ),
    );
    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _WebPushPermissionDialog extends ConsumerStatefulWidget {
  final WebPushPermissionState initialState;
  final VoidCallback onCompleted;

  const _WebPushPermissionDialog({
    required this.initialState,
    required this.onCompleted,
  });

  @override
  ConsumerState<_WebPushPermissionDialog> createState() =>
      _WebPushPermissionDialogState();
}

class _WebPushPermissionDialogState
    extends ConsumerState<_WebPushPermissionDialog> {
  late WebPushPermissionState _state;
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  Future<void> _activate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final granted =
          await NotificationService().requestPermissionFromUserGesture();
      if (!mounted) return;

      if (granted) {
        final registered =
            await ref.read(deviceTokenProvider).registerCurrentToken();
        if (!mounted) return;
        if (registered) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ToastService.showSuccess('Notifications activées avec succès !');
          });
          return;
        } else {
          setState(() {
            _state = WebPushPermissionState.granted;
            _errorMessage =
                "Autorisation accordée, mais l'enregistrement du navigateur a échoué. Vérifiez votre connexion et réessayez.";
          });
        }
      } else {
        final updatedState =
            await NotificationService().getWebPermissionState();
        if (!mounted) return;
        setState(() {
          _state = updatedState == WebPushPermissionState.promptable
              ? WebPushPermissionState.denied
              : updatedState;
        });
      }
    } catch (e, st) {
      debugPrint('[web_push_prompt_banner] Erreur activation: $e\n$st');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            "Impossible d'activer les notifications sur ce navigateur. Réessayez.";
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recheckPermission() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final currentState = await NotificationService().getWebPermissionState();
      if (!mounted) return;
      if (currentState == WebPushPermissionState.granted) {
        final registered =
            await ref.read(deviceTokenProvider).registerCurrentToken();
        if (!mounted) return;
        if (registered) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ToastService.showSuccess('Notifications activées avec succès !');
          });
          return;
        }
        setState(() {
          _state = WebPushPermissionState.granted;
          _errorMessage =
              "Autorisation détectée, mais l'enregistrement push a échoué. Réessayez.";
        });
      } else if (currentState == WebPushPermissionState.promptable) {
        setState(() => _state = WebPushPermissionState.promptable);
      } else {
        setState(() {
          _state = currentState;
          _errorMessage =
              "Les notifications sont toujours bloquées dans les réglages du navigateur.";
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBlocked = _state == WebPushPermissionState.denied;
    final isIosPwa = _state == WebPushPermissionState.iosInstallRequired;

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône principale proéminente
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isBlocked
                          ? [
                              AppColors.warning,
                              AppColors.warningDark,
                            ]
                          : [
                              AppColors.primary,
                              const Color(0xFF7C3AED),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isBlocked ? AppColors.warning : AppColors.primary)
                            .withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    isBlocked
                        ? LucideIcons.shieldAlert
                        : (isIosPwa
                            ? LucideIcons.smartphone
                            : LucideIcons.bellRing),
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 22),

                // Titre
                Text(
                  isBlocked
                      ? 'Autorisez les notifications dans votre navigateur'
                      : (isIosPwa
                          ? "Installez l'application pour recevoir les alertes"
                          : 'Activez les notifications en direct'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Sous-titre
                Text(
                  isBlocked
                      ? 'Votre navigateur bloque actuellement les alertes. Suivez ces 3 étapes rapides pour ne rien manquer :'
                      : (isIosPwa
                          ? "Sur iPhone / iPad, Apple exige d'ajouter le site à l'écran d'accueil pour recevoir les notifications en temps réel."
                          : 'Recevez instantanément vos tampons, récompenses débloquées et offres exclusives de vos établissements préférés.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),

                // Contenu contextuel : Avantages ou Étapes de déblocage
                if (isBlocked)
                  _buildStepsCard([
                    (
                      '1',
                      "Touchez l'icône cadenas 🔒 ou réglages ⚙️ à gauche de la barre d'adresse"
                    ),
                    (
                      '2',
                      'Ouvrez Autorisations / Notifications et choisissez Autoriser'
                    ),
                    (
                      '3',
                      'Appuyez sur « Vérifier l’autorisation » ci-dessous'
                    ),
                  ])
                else if (isIosPwa)
                  _buildStepsCard([
                    ('1', 'Touchez le bouton Partager (icône ⬆️) en bas ou en haut de Safari'),
                    ('2', 'Sélectionnez « Sur l’écran d’accueil » puis Ajouter'),
                    ('3', "Ouvrez Miva-Fid depuis votre écran d'accueil et acceptez les alertes"),
                  ])
                else
                  Column(
                    children: [
                      _buildBenefitRow(
                        LucideIcons.sparkles,
                        'Tampons, points & cashback en direct',
                        'Soyez alerté dès que votre carte est créditée en caisse.',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitRow(
                        LucideIcons.gift,
                        'Récompenses & cadeaux',
                        'Ne ratez plus aucun cadeau débloqué ou offre anniversaire.',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitRow(
                        LucideIcons.megaphone,
                        'Offres de vos établissements',
                        'Recevez les promotions privées directement sur votre écran.',
                      ),
                    ],
                  ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerTint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Bouton principal plein format
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _busy
                        ? null
                        : (isBlocked || isIosPwa
                            ? _recheckPermission
                            : _activate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isBlocked ? AppColors.warningDark : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isBlocked || isIosPwa
                                ? LucideIcons.refreshCw
                                : LucideIcons.bellRing,
                            size: 19,
                          ),
                    label: Text(
                      _busy
                          ? 'Activation en cours...'
                          : (isBlocked || isIosPwa
                              ? 'Vérifier l’autorisation'
                              : 'Autoriser les notifications'),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Fallback discret uniquement si le navigateur bloque ou iOS non-PWA
                if (isBlocked || isIosPwa) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            widget.onCompleted();
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                    child: Text(
                      'Continuer sans notifications',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard(List<(String, String)> steps) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.warningDark,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    steps[i].$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[i].$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
