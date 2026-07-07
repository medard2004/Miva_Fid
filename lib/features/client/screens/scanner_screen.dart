import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/client_provider.dart';
import '../../merchant/widgets/scan_frame_widget.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    setState(() => _processing = true);
    try {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final merchantId = payload['merchantId'] as String?;
      if (merchantId == null) return;

      await ref.read(clientNotifierProvider.notifier).scanMerchant(merchantId);
      await AppHaptics.medium();

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _ScanResultSheet(
          merchantId: merchantId,
          onViewCard: () {
            Navigator.pop(context);
            context.go('/client/cards');
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code non reconnu')),
        );
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          MobileScanner(
            controller: _ctrl,
            onDetect: _onQrDetected,
            fit: BoxFit.cover,
          ),
          CustomPaint(
            painter: _ScanOverlayPainter(frameSize: 260),
            size: Size.infinite,
          ),
          const Center(child: ScanFrameWidget(size: 260)),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Text(
              'Pointez vers le QR code du commerçant',
              style: AppTextStyles.caption().copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 48,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton.filled(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    Colors.white.withOpacity(0.15),
                  ),
                ),
                icon: const Icon(Icons.flashlight_on, color: Colors.white),
                onPressed: _ctrl.toggleTorch,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Sp.sm),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => context.go('/client'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  const _ScanOverlayPainter({required this.frameSize});
  final double frameSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy), width: frameSize, height: frameSize),
              const Radius.circular(8),
            ),
          ),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({required this.merchantId, required this.onViewCard});
  final String merchantId;
  final VoidCallback onViewCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Sp.md, Sp.md, Sp.md, MediaQuery.of(context).padding.bottom + Sp.md,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(height: Sp.lg),
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: AppColors.successTint, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 32),
          ),
          const SizedBox(height: Sp.md),
          Text('Programme rejoint !', style: AppTextStyles.h2()),
          const SizedBox(height: Sp.xs),
          Text('Vous pouvez maintenant cumuler des tampons.',
              style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: Sp.lg),
          AppButton.primary('Voir ma carte', onPressed: onViewCard),
          const SizedBox(height: Sp.sm),
          AppButton.ghost('Continuer le scan', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
