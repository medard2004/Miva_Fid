import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../models/loyalty_card_model.dart';
import '../../../models/user_model.dart';
import '../providers/merchant_provider.dart';
import '../providers/validate_provider.dart';
import '../widgets/client_card_sheet.dart';
import '../widgets/validation_success_overlay.dart';

class ValidateScreen extends ConsumerStatefulWidget {
  const ValidateScreen({super.key});

  @override
  ConsumerState<ValidateScreen> createState() => _ValidateScreenState();
}

class _ValidateScreenState extends ConsumerState<ValidateScreen> {
  int _selectedMethod = 0; // 0: Scanner QR, 1: Téléphone
  final MobileScannerController _scanCtrl = MobileScannerController();
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _processing = false;
  bool _isCameraActive = false;

  @override
  void dispose() {
    _scanCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    setState(() => _processing = true);
    try {
      String? clientId;
      try {
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        clientId = payload['clientId'] as String? ?? payload['merchantId'] as String?;
      } catch (_) {
        clientId = raw;
      }

      if (clientId == null) return;
      var card = await ref.read(validateNotifierProvider.notifier).lookupClient(clientId);
      card ??= await ref.read(validateNotifierProvider.notifier).lookupByCode(clientId);

      if (!mounted) return;
      if (card == null) {
        // Fallback for simulation/testing
        _openCardSheetWithMock('Client QR');
        return;
      }

      final merchant = await ref.read(merchantNotifierProvider.future);
      await AppHaptics.medium();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ClientCardSheet(
          card: card!,
          stampsRequired: merchant?.stampsRequired ?? 10,
          onValidate: () => _validateStamp(card!.id, card.stampsCount),
        ),
      );
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _validateStamp(String cardId, int currentStamps) async {
    final newCount = (currentStamps + 1);
    try {
      await ref.read(validateNotifierProvider.notifier).addStamp(cardId);
    } catch (_) {
      // Fallback
    }

    await AppHaptics.medium();
    if (!mounted) return;
    final merchant = await ref.read(merchantNotifierProvider.future);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValidationSuccessOverlay(
        clientName: 'Client',
        stampCount: newCount,
        stampsRequired: merchant?.stampsRequired ?? 10,
        onDone: () => Navigator.pop(context),
        onAnother: () => Navigator.pop(context),
      ),
    );
  }

  void _openCardSheetWithMock(String clientName, [String? phone]) {
    final mockCard = LoyaltyCardModel(
      id: 'mock-card-1',
      clientId: 'mock-client-1',
      merchantId: 'mock-merchant-1',
      stampsCount: 7,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      client: UserModel(
        id: 'mock-client-1',
        name: clientName,
        phone: phone ?? '+228 90 12 34 56',
        role: 'client',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClientCardSheet(
        card: mockCard,
        stampsRequired: 10,
        onValidate: () => _validateStamp(mockCard.id, mockCard.stampsCount),
      ),
    );
  }

  void _lookupByPhone() {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    _openCardSheetWithMock('Client', phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Subtitle
              Text(
                'Valider un tampon',
                style: AppTextStyles.h1().copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _selectedMethod == 0
                    ? 'Choisissez votre méthode'
                    : 'Scannez ou saisissez le numéro',
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: Sp.md),

              // Segmented Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _MethodTab(
                      label: 'Scanner QR',
                      icon: LucideIcons.qrCode,
                      isSelected: _selectedMethod == 0,
                      onTap: () => setState(() => _selectedMethod = 0),
                    ),
                    _MethodTab(
                      label: 'Numéro de téléphone',
                      icon: LucideIcons.phone,
                      isSelected: _selectedMethod == 1,
                      onTap: () => setState(() => _selectedMethod = 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),

              // Method View Card
              if (_selectedMethod == 0)
                _buildScannerCard()
              else
                _buildPhoneCard(),

              const SizedBox(height: Sp.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          // Dashed Frame Area
          Container(
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFFFAFAFE),
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: const Color(0xFFD1D5DB),
                strokeWidth: 1.5,
                dashWidth: 6,
                dashSpace: 4,
                radius: 20,
              ),
              child: _isCameraActive
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: MobileScanner(
                        controller: _scanCtrl,
                        onDetect: _onQrDetected,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isCameraActive = true;
                              });
                            },
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
          const SizedBox(height: Sp.lg),

          // Camera Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isCameraActive = !_isCameraActive;
                });
              },
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
    );
  }

  Widget _buildPhoneCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NUMÉRO DU CLIENT',
            style: AppTextStyles.caption().copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: Sp.sm),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: AppTextStyles.bodyMd().copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: '+228 90 00 00 00',
                hintStyle: TextStyle(
                  color: AppColors.gray400,
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _lookupByPhone(),
            ),
          ),
          const SizedBox(height: Sp.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _lookupByPhone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.merchant,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Rechercher le client',
                style: AppTextStyles.labelBold().copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTab extends StatelessWidget {
  const _MethodTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
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
