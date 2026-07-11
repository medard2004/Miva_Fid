import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/onboarding_provider.dart';

class QrSuccessScreen extends ConsumerStatefulWidget {
  const QrSuccessScreen({super.key});

  @override
  ConsumerState<QrSuccessScreen> createState() => _QrSuccessScreenState();
}

class _QrSuccessScreenState extends ConsumerState<QrSuccessScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String _buildQrPayload() {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    return jsonEncode({'merchantId': uid, 'app': 'mivafid'});
  }

  Future<void> _generatePdf() async {
    final state = ref.read(onboardingNotifierProvider);
    final qrPayload = _buildQrPayload();
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(state.commerceName,
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(state.commerceType, style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 20),
            pw.Text('Scannez pour cumuler vos points !',
                style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 20),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: qrPayload,
              width: 200,
              height: 200,
            ),
            pw.SizedBox(height: 20),
            pw.Text('Compatible avec tous les téléphones — gratuit et instantané',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Divider(),
            if (state.address.isNotEmpty)
              pw.Text(state.address, style: const pw.TextStyle(fontSize: 12)),
            if (state.phone.isNotEmpty)
              pw.Text(state.phone, style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 12),
            pw.Text('Powered by Miva-Fid',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        ),
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'mivafid-comptoir.pdf',
    );
  }

  Future<void> _shareWhatsApp() async {
    final state = ref.read(onboardingNotifierProvider);
    final msg = Uri.encodeComponent(
        'Rejoignez mon programme de fidélité sur Miva-Fid ! '
        'Scannez mon QR code et cumulez des récompenses chez ${state.commerceName}.');
    final url = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final qrPayload = _buildQrPayload();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              colors: const [
                AppColors.primary,
                AppColors.merchant,
                AppColors.warning,
                AppColors.success,
                Colors.pinkAccent,
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: Sp.xxl),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.merchant],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                  )
                      .animate()
                      .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.1, 1.1),
                          curve: Curves.elasticOut,
                          duration: 600.ms)
                      .then()
                      .scale(end: const Offset(1.0, 1.0), duration: 150.ms),
                  const SizedBox(height: Sp.lg),
                  Text('Votre programme est actif !',
                      style: AppTextStyles.display().copyWith(fontSize: 26),
                      textAlign: TextAlign.center),
                  const SizedBox(height: Sp.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
                    child: Text(
                      'Votre QR code est généré.\nVotre feuille comptoir est prête à imprimer.',
                      style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: Sp.xl),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: Sp.md),
                    padding: const EdgeInsets.all(Sp.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: Rd.card20,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: qrPayload,
                          size: 200,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: Sp.sm),
                        Text(state.commerceName, style: AppTextStyles.h3()),
                        const SizedBox(height: Sp.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            AppBadge('QR Code'),
                            SizedBox(width: Sp.sm),
                            AppBadge('NFC', color: AppColors.success),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Sp.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                    child: Column(
                      children: [
                        AppButton.primary(
                          'Télécharger ma feuille comptoir',
                          icon: Icons.download_outlined,
                          onPressed: _generatePdf,
                        ),
                        const SizedBox(height: Sp.sm),
                        AppButton.success(
                          'Partager sur WhatsApp',
                          icon: Icons.share_outlined,
                          onPressed: _shareWhatsApp,
                        ),
                        const SizedBox(height: Sp.md),
                        TextButton(
                          onPressed: () => context.go('/merchant'),
                          child: Text(
                            'Accéder à mon espace →',
                            style: AppTextStyles.bodyMd().copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Sp.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
