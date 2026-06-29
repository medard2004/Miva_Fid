import 'dart:convert';
import 'package:flutter/material.dart';
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
import '../providers/merchant_provider.dart';

class QrCodeScreen extends ConsumerWidget {
  const QrCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantAsync = ref.watch(merchantNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Mon QR Code', style: AppTextStyles.h3()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/merchant'),
        ),
      ),
      body: merchantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erreur')),
        data: (merchant) {
          if (merchant == null) return const SizedBox();
          final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
          final qrData = jsonEncode({'merchantId': uid, 'app': 'mivafid'});

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.md),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(Sp.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: Rd.card20,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.10),
                        blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: qrData,
                        size: 220,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: Sp.md),
                      Text(merchant.name, style: AppTextStyles.h3()),
                      const SizedBox(height: Sp.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppBadge('QR Code'),
                          const SizedBox(width: Sp.sm),
                          AppBadge('NFC', color: AppColors.success),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.lg),
                _QrActionButton(
                  Icons.picture_as_pdf_outlined,
                  'Télécharger feuille comptoir PDF',
                  onTap: () => _generatePdf(merchant.name, merchant.address ?? '', merchant.phone ?? '', qrData),
                ),
                _QrActionButton(
                  Icons.share_outlined,
                  'Partager sur WhatsApp',
                  color: AppColors.success,
                  onTap: () => _shareWhatsApp(merchant.name),
                ),
                _QrActionButton(
                  Icons.wifi_outlined,
                  'Commander un support NFC',
                  disabled: true,
                  badge: 'Bientôt',
                ),
                const SizedBox(height: Sp.lg),
                Container(
                  padding: const EdgeInsets.all(Sp.md),
                  decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: Rd.card),
                  child: Column(
                    children: [
                      _InstructionRow(Icons.print_outlined, 'Imprimez et placez sur votre comptoir'),
                      _InstructionRow(Icons.smartphone_outlined, 'Vos clients scannent en 5 secondes'),
                      _InstructionRow(Icons.bolt_outlined, 'Les tampons s\'accumulent automatiquement'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _generatePdf(String name, String address, String phone, String qrData) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(name, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Scannez pour cumuler vos points !', style: const pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 20),
          pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: qrData, width: 200, height: 200),
          pw.SizedBox(height: 20),
          if (address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 12)),
          if (phone.isNotEmpty) pw.Text(phone, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 12),
          pw.Text('Powered by Miva-Fid', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ],
      ),
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'mivafid-comptoir.pdf');
  }

  Future<void> _shareWhatsApp(String name) async {
    final msg = Uri.encodeComponent('Rejoignez mon programme de fidélité Miva-Fid chez $name !');
    final url = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}

class _QrActionButton extends StatelessWidget {
  const _QrActionButton(this.icon, this.label, {this.color, this.onTap, this.disabled = false, this.badge});
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final bool disabled;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Sp.sm),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: Rd.button,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: Sp.md),
          decoration: BoxDecoration(
            color: disabled ? const Color(0xFFF3F4F6) : (color?.withOpacity(0.1) ?? AppColors.primaryTint),
            borderRadius: Rd.button,
          ),
          child: Row(
            children: [
              Icon(icon, color: disabled ? AppColors.textSecondary : (color ?? AppColors.primary), size: 20),
              const SizedBox(width: Sp.sm),
              Text(label, style: AppTextStyles.bodyMd().copyWith(
                  color: disabled ? AppColors.textSecondary : (color ?? AppColors.primary))),
              const Spacer(),
              if (badge != null) AppBadge(badge!, color: AppColors.warning),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: Sp.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodyMd())),
        ],
      ),
    );
  }
}
