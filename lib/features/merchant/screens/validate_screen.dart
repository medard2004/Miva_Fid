import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/core/api_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/toast_service.dart';
import '../../../models/loyalty_card_model.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/validate_provider.dart';
import '../widgets/client_card_sheet.dart';
import '../widgets/reward_redeem_sheet.dart';
import '../widgets/scan_frame_widget.dart';
import '../widgets/validation_success_overlay.dart';
import '../../client/providers/settings_provider.dart';
import '../../../core/constants/reward_qr.dart';

class ValidateScreen extends ConsumerStatefulWidget {
  const ValidateScreen({super.key});

  @override
  ConsumerState<ValidateScreen> createState() => _ValidateScreenState();
}

class _ValidateScreenState extends ConsumerState<ValidateScreen> {
  final MobileScannerController _scanCtrl = MobileScannerController();
  bool _processing = false;
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _scanCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  /// Type de programme (`stamps`/`points`/`spend`) et sa config, tels que
  /// renvoyés à la connexion marchand (`RestaurantAccount.loyaltyType/Config`)
  /// — source unique, jamais l'ancien provider Supabase déconnecté du backend.
  String get _mechanic => ref.read(merchantAuthProvider).restaurant?.loyaltyType ?? 'stamps';

  int get _goal {
    final config = ref.read(merchantAuthProvider).restaurant?.loyaltyConfig ?? const {};
    return (config['goal'] as num?)?.toInt() ?? 10;
  }

  int get _fcfaPerPoint {
    final config = ref.read(merchantAuthProvider).restaurant?.loyaltyConfig ?? const {};
    return (config['fcfa_per_point'] as num?)?.toInt() ?? 500;
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) {
      ToastService.showError('QR code invalide ou illisible.');
      return;
    }
    setState(() => _processing = true);
    try {
      if (raw.startsWith(rewardQrPrefix)) {
        await _lookupAndShowRewardSheet(raw.substring(rewardQrPrefix.length));
      } else {
        // Le QR affiché sur la carte du client encode directement son
        // `card_code` en texte brut (pas de JSON) — le serveur accepte ce
        // code, un `qr_token`, ou un uuid client indifféremment (voir
        // `lookupByCode`).
        await _lookupAndShowSheet(raw);
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _lookupAndShowSheet(String code) async {
    final LoyaltyCardModel? card;
    try {
      card = await ref.read(validateNotifierProvider.notifier).lookupByCode(code);
    } on NetworkException {
      if (mounted) ToastService.showError('Connexion impossible. Vérifiez votre réseau.');
      return;
    } catch (_) {
      if (mounted) ToastService.showError('Une erreur est survenue, réessayez.');
      return;
    }

    if (!mounted) return;
    if (card == null) {
      ToastService.showError('Aucune carte de fidélité trouvée pour ce commerce.');
      return;
    }
    final resolvedCard = card;

    await AppHaptics.medium();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClientCardSheet(
        card: resolvedCard,
        mechanic: _mechanic,
        goal: _goal,
        fcfaPerPoint: _fcfaPerPoint,
        onValidate: (amount) => _validateStamp(resolvedCard, amount),
      ),
    );
  }

  Future<void> _lookupAndShowRewardSheet(String token) async {
    final MerchantReward? reward;
    try {
      reward = await ref.read(validateNotifierProvider.notifier).lookupReward(token);
    } on NetworkException {
      if (mounted) ToastService.showError('Connexion impossible. Vérifiez votre réseau.');
      return;
    } catch (_) {
      if (mounted) ToastService.showError('Une erreur est survenue, réessayez.');
      return;
    }

    if (!mounted) return;
    if (reward == null) {
      ToastService.showError('Aucune récompense de votre commerce ne correspond à ce code.');
      return;
    }
    final resolvedReward = reward;

    await AppHaptics.medium();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => RewardRedeemSheet(
        reward: resolvedReward,
        onRedeem: () async {
          try {
            await ref
                .read(validateNotifierProvider.notifier)
                .redeemReward(resolvedReward.id);
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            ToastService.showSuccess('Récompense validée.');
          } on ValidationException catch (e) {
            ToastService.showError(e.message);
          } catch (_) {
            ToastService.showError('Échec de la validation. Réessayez.');
          }
        },
        onCancel: (reason) async {
          try {
            await ref
                .read(validateNotifierProvider.notifier)
                .cancelReward(resolvedReward.id, reason: reason);
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            ToastService.showSuccess('Récompense annulée.');
          } catch (_) {
            ToastService.showError('Échec de l\'annulation. Réessayez.');
          }
        },
      ),
    );
  }

  Future<void> _validateStamp(LoyaltyCardModel card, double? amountFcfa) async {
    // La feuille (`showModalBottomSheet`) vit sur le navigator de la branche
    // marchande (coquille à onglets) : la fermer exige ce navigator-là, pas
    // le root — sinon `pop()` agit sur la mauvaise pile de navigation. Le
    // futur écran de succès, lui, doit passer par le root pour couvrir tout
    // l'écran, barre d'onglets comprise.
    final sheetNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    try {
      final outcome = await ref
          .read(validateNotifierProvider.notifier)
          .addStamp(card.id, amountFcfa: amountFcfa);

      if (!mounted) return;
      sheetNavigator.pop();
      await AppHaptics.medium();
      if (!mounted) return;

      rootNavigator.push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ValidationSuccessOverlay(
          clientName: card.client?.name ?? 'Client',
          mechanic: _mechanic,
          stampCount: outcome.stampsCurrent,
          goal: _goal,
          pointsEarned: outcome.pointsEarned,
          rewardUnlocked: outcome.rewardUnlocked,
        ),
      ));
    } on ValidationException catch (e) {
      if (!mounted) return;
      sheetNavigator.pop();
      ToastService.showError(e.message);
    } on ServerException catch (e) {
      if (!mounted) return;
      sheetNavigator.pop();
      // 409 = double validation (verrou anti-doublon côté serveur).
      ToastService.showError(
        e.statusCode == 409 ? e.message : 'Échec de la validation. Réessayez.',
      );
    } on NetworkException {
      if (!mounted) return;
      sheetNavigator.pop();
      ToastService.showError('Connexion impossible. Vérifiez votre réseau.');
    } catch (_) {
      if (!mounted) return;
      sheetNavigator.pop();
      ToastService.showError('Échec de la validation. Réessayez.');
    }
  }

  Future<void> _lookupByCode() async {
    // `card_code` : 8 caractères alphanumériques (`Str::upper(Str::random(8))`
    // côté backend) — pas de format plus court à valider en amont, le
    // serveur renvoie 404 si le code ne correspond à aucune carte.
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    await _lookupAndShowSheet(code);
  }

  @override
  Widget build(BuildContext context) {
    // Ces ecrans peignent via les tokens statiques d'AppColors,
    // invisibles pour le systeme de dependances de Flutter : observer
    // la luminosite effective est leur seul declencheur de rebuild sur
    // une bascule clair/sombre.
    ref.watch(appBrightnessProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Valider un achat', style: AppTextStyles.h3()),
          bottom: TabBar(
            indicator: const BoxDecoration(
              color: AppColors.merchant,
              borderRadius: Rd.pill,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Scanner QR'),
              Tab(text: 'Code manuel'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_ScannerTab(controller: _scanCtrl, onDetect: _onQrDetected),
                     _ManualTab(controller: _codeCtrl, onSubmit: _lookupByCode)],
        ),
      ),
    );
  }
}

class _ScannerTab extends StatelessWidget {
  const _ScannerTab({required this.controller, required this.onDetect});
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sp.md),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: Rd.card,
                  child: MobileScanner(controller: controller, onDetect: onDetect),
                ),
                const ScanFrameWidget(),
              ],
            ),
          ),
          const SizedBox(height: Sp.md),
          Text('Pointez vers le QR code du client',
              style: AppTextStyles.bodyMd(), textAlign: TextAlign.center),
          const SizedBox(height: Sp.sm),
          IconButton.filled(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.12))),
            icon: const Icon(LucideIcons.flashlight, color: Colors.white),
            onPressed: controller.toggleTorch,
          ),
          const SizedBox(height: Sp.md),
        ],
      ),
    );
  }
}

class _ManualTab extends StatelessWidget {
  const _ManualTab({required this.controller, required this.onSubmit});
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        children: [
          const SizedBox(height: Sp.xl),
          Text('Code carte du client (8 caractères)',
              style: AppTextStyles.labelBold()),
          const SizedBox(height: Sp.md),
          TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            style: AppTextStyles.monoLg(),
            decoration: const InputDecoration(
              counterText: '',
              hintText: 'Ex : QDA9D363',
              border: OutlineInputBorder(borderRadius: Rd.input),
            ),
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: Sp.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.merchant,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(borderRadius: Rd.button),
              ),
              child: Text('Rechercher le client', style: AppTextStyles.labelBold().copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
