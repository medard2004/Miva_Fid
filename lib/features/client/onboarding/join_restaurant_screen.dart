import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/api/core/api_exceptions.dart';
import 'package:miva_fid/core/errors/error_messages.dart';
import 'package:miva_fid/core/utils/toast_service.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/providers/wallet_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';

class JoinRestaurantScreen extends ConsumerStatefulWidget {
  /// Code scanné (ou saisi manuellement) sur l'écran précédent.
  final String? scannedCode;

  const JoinRestaurantScreen({super.key, this.scannedCode});

  @override
  ConsumerState<JoinRestaurantScreen> createState() =>
      _JoinRestaurantScreenState();
}

class _JoinRestaurantScreenState extends ConsumerState<JoinRestaurantScreen>
    with SingleTickerProviderStateMixin {
  bool _revealing = false;
  LoyaltyCard? _realCard;
  bool _isNewCard = true;
  String? _realError;

  @override
  void initState() {
    super.initState();
    // Un code scanné (QR réel) rejoint directement via le backend — pas de
    // pré-visualisation possible sans un second endpoint, donc pas d'étape
    // "Rejoindre" intermédiaire ici.
    final code = widget.scannedCode;
    if (code != null) {
      _joinReal(code);
    } else {
      // Cet écran n'a de sens qu'avec un code scanné : sans lui, il n'y a
      // rien à rejoindre. On renvoie vers le scan plutôt que d'afficher un
      // parcours de démonstration déconnecté du backend.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/client/onboarding/scan');
      });
    }
  }

  Future<void> _joinReal(String qrToken) async {
    try {
      final result =
          await ref.read(walletProvider.notifier).joinByQrToken(qrToken);
      if (!mounted) return;

      if (!result.isNew) {
        // Carte déjà existante — pas de doublon, pas de ré-adhésion : on
        // redirige immédiatement vers la fiche carte plutôt que de rejouer
        // l'animation de création, avec un message clair sur pourquoi.
        final t = AppLocalizations.of(context)!;
        ToastService.showInfo(t.joinCardAlreadyMemberMessage);
        context.pushReplacement('/client/card/${result.card.id}');
        return;
      }

      setState(() {
        _revealing = true;
        _realCard = result.card;
        _isNewCard = result.isNew;
      });
      // Même respiration que l'ancienne animation de révélation avant de
      // partir sur la fiche carte.
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) context.pushReplacement('/client/card/${result.card.id}');
    } catch (e) {
      if (!mounted) return;
      // Les messages 404 du contrôleur (`ServerException`) sont déjà rédigés
      // pour l'utilisateur ("Ce code n'est associé à aucun commerce.") — les
      // afficher tels quels plutôt que de les faire passer par le catalogue
      // générique d'erreurs, pensé pour l'auth.
      final message = e is ServerException
          ? e.message
          : ErrorMessages.serverUnreachable;
      setState(() => _realError = message);
      ToastService.showError(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final code = widget.scannedCode;

    if (code == null) {
      // Redirection déclenchée dans `initState` — écran de transition le
      // temps qu'elle s'exécute.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_realError != null) {
      return _UnrecognizedCodeScreen(code: code, message: _realError);
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: _revealing && _realCard != null
            ? _CardRevealScreen(key: const ValueKey('reveal'), card: _realCard!)
            : const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}

/// Écran affiché quand le code scanné/saisi ne correspond à aucun
/// établissement partenaire connu.
class _UnrecognizedCodeScreen extends StatelessWidget {
  final String code;

  /// Message précis renvoyé par le backend (ex. "programme pas encore
  /// activé"), affiché à la place du message générique si fourni.
  final String? message;

  const _UnrecognizedCodeScreen({required this.code, this.message});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: EmptyState(
            icon: LucideIcons.qrCode,
            title: t.joinUnrecognizedTitle,
            message: message ?? t.joinUnrecognizedMessage(code),
            action: Column(
              children: [
                AppButton(
                  label: t.joinRetryScan,
                  fullWidth: false,
                  onTap: () => context.go('/client/onboarding/scan'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/client/wallet'),
                  child: Text(t.joinBackToWallet,
                      style: AppTextStyles.label(
                          color: AppColors.inkMuted(opacity: 0.6))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Écran de confirmation — carte révélée avec animation spring douce
// ─────────────────────────────────────────────────────────────────────────────

class _CardRevealScreen extends StatefulWidget {
  final LoyaltyCard card;
  const _CardRevealScreen({super.key, required this.card});

  @override
  State<_CardRevealScreen> createState() => _CardRevealScreenState();
}

class _CardRevealScreenState extends State<_CardRevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();

    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    // Texte toujours blanc — même convention que le reste de l'app (pile
    // wallet, détail carte, aperçu marchand) : la carte doit rendre
    // exactement ce que le marchand a configuré/prévisualisé.
    const textColor = Colors.white;
    final subtextColor = textColor.withValues(alpha: 0.8);
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: ScaleTransition(
                scale: _scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GradientCardSurface(
                        color: widget.card.liningColor,
                        secondaryColor: widget.card.secondaryColor,
                        gradientType: widget.card.gradientType,
                        decorationPattern: widget.card.decorationPattern,
                        height: 200,
                        width: double.infinity,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.circleCheckBig,
                                  color: textColor, size: 34),
                              const SizedBox(height: 10),
                              Text(t.joinCardCreatedTitle,
                                  style: AppTextStyles.displayMedium(
                                      color: textColor)),
                              const SizedBox(height: 6),
                              Text(
                                widget.card.restaurantName,
                                style: AppTextStyles.bodyMedium(
                                    color: subtextColor),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
