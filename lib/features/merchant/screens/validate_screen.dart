import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/core/api_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/toast_service.dart';
import '../../../core/widgets/app_dialog.dart';
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
    return (config['fcfa_per_point'] as num?)?.toInt() ?? 100;
  }

  double get _cashbackPercentage {
    final config = ref.read(merchantAuthProvider).restaurant?.loyaltyConfig ?? const {};
    return (config['cashback_percentage'] as num?)?.toDouble() ?? 0;
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
        cashbackPercentage: _cashbackPercentage,
        onValidate: (amount) => _validateStamp(resolvedCard, amount),
        onRedeemCashback: (purchaseAmount, redeemAmount) => _redeemCashback(
          resolvedCard,
          purchaseAmount: purchaseAmount,
          redeemAmount: redeemAmount,
        ),
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
          cashbackEarned: outcome.cashbackEarned,
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

  Future<void> _redeemCashback(
    LoyaltyCardModel card, {
    required double purchaseAmount,
    required double redeemAmount,
  }) async {
    final sheetNavigator = Navigator.of(context);
    try {
      final outcome = await ref.read(validateNotifierProvider.notifier).redeemCashback(
            card.id,
            amountFcfa: purchaseAmount,
            redeemAmountFcfa: redeemAmount,
          );
      if (!mounted) return;
      sheetNavigator.pop();
      await AppHaptics.medium();
      if (!mounted) return;
      ToastService.showSuccess(outcome.message);
    } on ValidationException catch (e) {
      if (!mounted) return;
      sheetNavigator.pop();
      ToastService.showError(e.message);
    } on ServerException catch (e) {
      if (!mounted) return;
      sheetNavigator.pop();
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

  Future<void> _signOut() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Se déconnecter ?',
      message: 'Vous devrez vous reconnecter pour accéder à votre espace marchand.',
      confirmLabel: 'Se déconnecter',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(merchantAuthProvider.notifier).signOut();
    if (context.mounted) context.go('/auth/merchant/auth');
  }

  @override
  Widget build(BuildContext context) {
    // Ces ecrans peignent via les tokens statiques d'AppColors,
    // invisibles pour le systeme de dependances de Flutter : observer
    // la luminosite effective est leur seul declencheur de rebuild sur
    // une bascule clair/sombre.
    ref.watch(appBrightnessProvider);
    // Un opérateur n'a pas accès au dashboard (`MerchantShell` le confine à
    // cet écran) : sans ce menu, il n'aurait aucun moyen de changer son mot
    // de passe ou de se déconnecter.
    final isAdmin = ref.watch(isAdminProvider);
    final staffName = ref.watch(merchantAuthProvider).restaurant?.staffName;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Valider un achat', style: AppTextStyles.h3()),
          actions: !isAdmin
              ? [
                  PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.userCircle),
                    onSelected: (value) {
                      switch (value) {
                        case 'change-password':
                          context.push('/merchant/more/change-password');
                          break;
                        case 'sign-out':
                          _signOut();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (staffName != null && staffName.isNotEmpty)
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Text(
                            staffName,
                            style: AppTextStyles.labelBold(),
                          ),
                        ),
                      const PopupMenuItem<String>(
                        value: 'change-password',
                        child: Text('Changer mon mot de passe'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'sign-out',
                        child: Text('Se déconnecter'),
                      ),
                    ],
                  ),
                ]
              : null,
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

class _ScannerTab extends StatefulWidget {
  const _ScannerTab({required this.controller, required this.onDetect});
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;

  @override
  State<_ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<_ScannerTab> {
  bool _isCameraActive = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sp.md),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Scanner area — camera always rendered, overlay hides it
                Container(
                  width: double.infinity,
                  height: 300, // Fixed height to prevent stretching
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFFAFAFE),
                  ),
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: _isCameraActive
                          ? AppColors.merchant.withValues(alpha: 0.4)
                          : const Color(0xFFD1D5DB),
                      strokeWidth: 1.5,
                      dashWidth: 6,
                      dashSpace: 4,
                      radius: 20,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Camera — always built and running
                          Positioned.fill(
                            child: MobileScanner(
                              controller: widget.controller,
                              onDetect: widget.onDetect,
                            ),
                          ),
                          // Overlay cover — hides camera until activated
                          if (!_isCameraActive)
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () => setState(() => _isCameraActive = true),
                                child: Container(
                                  color: const Color(0xFFFAFAFE),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () => setState(() => _isCameraActive = true),
                                          borderRadius: BorderRadius.circular(16),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Icon(
                                              LucideIcons.scan,
                                              size: 64,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: Sp.sm),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20),
                                          child: Text(
                                            'Placez le QR code du client dans le cadre',
                                            style: AppTextStyles.bodyMd().copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 13.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Scan frame overlay — visible when camera active
                          if (_isCameraActive)
                            const Positioned.fill(
                              child: Center(child: ScanFrameWidget(size: 240)), // Ensure square aspect ratio and perfect centering
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                  const SizedBox(height: Sp.lg),
                  // Toggle button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isCameraActive = !_isCameraActive),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.merchant,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        _isCameraActive ? LucideIcons.cameraOff : LucideIcons.camera,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        _isCameraActive ? 'Désactiver la caméra' : 'Activer la caméra',
                        style: AppTextStyles.labelBold().copyWith(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Sp.md),
        ],
      ),
    );
  }
}

/// Dashed border painter for the scanner frame.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        final extractPath = metric.extractPath(
          distance,
          nextDistance > metric.length ? metric.length : nextDistance,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.radius != radius;
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
