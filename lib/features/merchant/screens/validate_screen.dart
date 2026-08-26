import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/core/api_exceptions.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/toast_service.dart';
import '../../../models/loyalty_card_model.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/validate_provider.dart';
import '../widgets/client_card_sheet.dart';
import '../widgets/reward_redeem_sheet.dart';
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
  bool _isCameraActive = false;
  int _selectedTab = 0; // 0: Scanner, 1: Téléphone
  final _phoneOrCodeCtrl = TextEditingController();

  @override
  void dispose() {
    _scanCtrl.dispose();
    _phoneOrCodeCtrl.dispose();
    super.dispose();
  }

  String get _mechanic =>
      ref.read(merchantAuthProvider).restaurant?.loyaltyType ?? 'stamps';

  int get _goal {
    final config =
        ref.read(merchantAuthProvider).restaurant?.loyaltyConfig ?? const {};
    return (config['goal'] as num?)?.toInt() ?? 10;
  }

  int get _fcfaPerPoint {
    final config =
        ref.read(merchantAuthProvider).restaurant?.loyaltyConfig ?? const {};
    return (config['fcfa_per_point'] as num?)?.toInt() ?? 100;
  }

  double get _cashbackPercentage {
    final config =
        ref.read(merchantAuthProvider).restaurant?.loyaltyConfig ?? const {};
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
      card =
          await ref.read(validateNotifierProvider.notifier).lookupByCode(code);
    } on NetworkException {
      if (mounted) {
        ToastService.showError('Connexion impossible. Vérifiez votre réseau.');
      }
      return;
    } catch (_) {
      if (mounted) {
        ToastService.showError('Une erreur est survenue, réessayez.');
      }
      return;
    }

    if (!mounted) return;
    if (card == null) {
      ToastService.showError(
          'Aucune carte de fidélité trouvée pour ce commerce.');
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
      reward = await ref
          .read(validateNotifierProvider.notifier)
          .lookupReward(token);
    } on NetworkException {
      if (mounted) {
        ToastService.showError('Connexion impossible. Vérifiez votre réseau.');
      }
      return;
    } catch (_) {
      if (mounted) {
        ToastService.showError('Une erreur est survenue, réessayez.');
      }
      return;
    }

    if (!mounted) return;
    if (reward == null) {
      ToastService.showError(
          'Aucune récompense de votre commerce ne correspond à ce code.');
      return;
    }
    final resolvedReward = reward;

    await AppHaptics.medium();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RewardRedeemSheet(
        reward: resolvedReward,
        onRedeem: () => _confirmRewardRedeem(resolvedReward.id),
        onCancel: (_) async {},
      ),
    );
  }

  Future<void> _confirmRewardRedeem(String rewardId) async {
    final sheetNavigator = Navigator.of(context);
    try {
      await ref
          .read(validateNotifierProvider.notifier)
          .redeemReward(rewardId);
      if (!mounted) return;
      sheetNavigator.pop();
      await AppHaptics.heavy();
      if (mounted) {
        ToastService.showSuccess('Récompense validée avec succès !');
      }
    } catch (_) {
      if (mounted) {
        sheetNavigator.pop();
        ToastService.showError('Erreur lors de la validation.');
      }
    }
  }

  Future<void> _validateStamp(LoyaltyCardModel card, [double? amount]) async {
    final sheetNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    try {
      final outcome = await ref
          .read(validateNotifierProvider.notifier)
          .addStamp(card.id, amountFcfa: amount);
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
      final outcome = await ref
          .read(validateNotifierProvider.notifier)
          .redeemCashback(
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

  Future<void> _searchClientByPhoneOrCode() async {
    final query = _phoneOrCodeCtrl.text.trim();
    if (query.isEmpty) return;
    await _lookupAndShowSheet(query);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP APP BAR ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.qrCode,
                      color: Color(0xFF5B50EC),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Valider un tampon',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Scannez ou saisissez le numéro',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/merchant/more/notifications'),
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            LucideIcons.bell,
                            size: 18,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── SEGMENTED TAB SWITCHER ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: _selectedTab == 0
                                ? Border.all(color: const Color(0xFFE5E7EB))
                                : null,
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.qrCode,
                                size: 16,
                                color: _selectedTab == 0
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Scanner',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedTab == 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _selectedTab == 0
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: _selectedTab == 1
                                ? Border.all(color: const Color(0xFFE5E7EB))
                                : null,
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.phone,
                                size: 16,
                                color: _selectedTab == 1
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Téléphone',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedTab == 1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _selectedTab == 1
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── TAB VIEW CONTENT ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _selectedTab == 0
                    ? _buildScannerContent()
                    : _buildManualPhoneContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDF0F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Dark Viewfinder Area
          Container(
            width: double.infinity,
            height: 310,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Camera when active
                  if (_isCameraActive)
                    Positioned.fill(
                      child: MobileScanner(
                        controller: _scanCtrl,
                        onDetect: _onQrDetected,
                      ),
                    ),

                  // Overlay brackets and guidelines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScannerOverlayPainter(
                        bracketColor: const Color(0xFF6366F1),
                        dashedBorderColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      ),
                    ),
                  ),

                  // Central instruction text (only when inactive or as overlay)
                  if (!_isCameraActive)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(height: 60),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Pointez la caméra vers le QR du client',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Button: Activer la caméra
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _isCameraActive = !_isCameraActive);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B50EC),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                _isCameraActive ? LucideIcons.cameraOff : LucideIcons.zap,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                _isCameraActive ? 'Désactiver la caméra' : 'Activer la caméra',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualPhoneContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDF0F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recherche manuelle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Entrez le numéro de téléphone ou le code client pour valider un tampon.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _phoneOrCodeCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Ex : +228 90 12 34 56 ou CODE',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                prefixIcon: Icon(LucideIcons.phone, color: Color(0xFF64748B), size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              onSubmitted: (_) => _searchClientByPhoneOrCode(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _searchClientByPhoneOrCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B50EC),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(LucideIcons.search, size: 16, color: Colors.white),
              label: const Text(
                'Rechercher le client',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({
    required this.bracketColor,
    required this.dashedBorderColor,
  });

  final Color bracketColor;
  final Color dashedBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bracketPaint = Paint()
      ..color = bracketColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double inset = 24.0;
    const double length = 26.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - (inset * 2),
      size.height - (inset * 2),
    );

    // 4 Corner Brackets
    // Top-Left
    canvas.drawLine(Offset(rect.left, rect.top + length), Offset(rect.left, rect.top), bracketPaint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + length, rect.top), bracketPaint);

    // Top-Right
    canvas.drawLine(Offset(rect.right - length, rect.top), Offset(rect.right, rect.top), bracketPaint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + length), bracketPaint);

    // Bottom-Left
    canvas.drawLine(Offset(rect.left, rect.bottom - length), Offset(rect.left, rect.bottom), bracketPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + length, rect.bottom), bracketPaint);

    // Bottom-Right
    canvas.drawLine(Offset(rect.right - length, rect.bottom), Offset(rect.right, rect.bottom), bracketPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - length), bracketPaint);

    // Center Focus Brackets
    final center = Offset(size.width / 2, size.height / 2 - 10);
    const centerSize = 22.0;
    final centerRect = Rect.fromCenter(center: center, width: centerSize * 2, height: centerSize * 2);
    const centerLength = 10.0;

    final centerPaint = Paint()
      ..color = bracketColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Center TL
    canvas.drawLine(Offset(centerRect.left, centerRect.top + centerLength), Offset(centerRect.left, centerRect.top), centerPaint);
    canvas.drawLine(Offset(centerRect.left, centerRect.top), Offset(centerRect.left + centerLength, centerRect.top), centerPaint);
    // Center TR
    canvas.drawLine(Offset(centerRect.right - centerLength, centerRect.top), Offset(centerRect.right, centerRect.top), centerPaint);
    canvas.drawLine(Offset(centerRect.right, centerRect.top), Offset(centerRect.right, centerRect.top + centerLength), centerPaint);
    // Center BL
    canvas.drawLine(Offset(centerRect.left, centerRect.bottom - centerLength), Offset(centerRect.left, centerRect.bottom), centerPaint);
    canvas.drawLine(Offset(centerRect.left, centerRect.bottom), Offset(centerRect.left + centerLength, centerRect.bottom), centerPaint);
    // Center BR
    canvas.drawLine(Offset(centerRect.right - centerLength, centerRect.bottom), Offset(centerRect.right, centerRect.bottom), centerPaint);
    canvas.drawLine(Offset(centerRect.right, centerRect.bottom), Offset(centerRect.right, centerRect.bottom - centerLength), centerPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) => false;
}
