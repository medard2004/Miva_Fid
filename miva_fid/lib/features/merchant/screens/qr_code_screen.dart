import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      body: merchantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erreur')),
        data: (merchant) {
          if (merchant == null) return const SizedBox();
          final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
          final qrData = jsonEncode({'merchantId': uid, 'app': 'mivafid'});
          final slug = merchant.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final directLink = 'miva.fid/r/$slug';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Subtitle
                Text(
                  'Mon QR Code',
                  style: AppTextStyles.h1().copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Affichez-le pour que les clients scannent',
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: Sp.md),

                // QR Code Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Sp.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: Rd.card20,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.merchant, width: 3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: QrImageView(
                              data: qrData,
                              size: 200,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.textPrimary,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.merchant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sp.md),
                      Text(
                        merchant.name,
                        style: AppTextStyles.labelBold().copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scannez pour gagner un tampon',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.md),

                // Download/Print/Share Row
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.file_download_outlined,
                      label: 'PNG',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image enregistrée dans la galerie !')),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.print_outlined,
                      label: 'A4',
                      onTap: () => _generatePdf(merchant.name, merchant.address ?? '', merchant.phone ?? '', qrData),
                    ),
                    _buildActionButton(
                      icon: Icons.share_outlined,
                      label: 'Partager',
                      onTap: () => _shareWhatsApp(merchant.name),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.md),

                // LIEN DIRECT Section Card
                _buildSectionContainer(
                  title: 'LIEN DIRECT',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            directLink,
                            style: AppTextStyles.mono().copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: directLink));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lien copié dans le presse-papiers !')),
                            );
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Sp.md),

                // Statistiques Section Card
                _buildSectionContainer(
                  title: 'Statistiques',
                  child: Row(
                    children: [
                      _buildStatBox(value: '43', label: 'Cette semaine'),
                      const SizedBox(width: Sp.xs),
                      _buildStatBox(value: '183', label: 'Ce mois'),
                      const SizedBox(width: Sp.xs),
                      _buildStatBox(value: '12', label: 'Nouveaux'),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.md),

                // Astuce Banner
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.merchantTint.withValues(alpha: 0.2),
                    borderRadius: Rd.card,
                  ),
                  child: ClipRRect(
                    borderRadius: Rd.card,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 4,
                            color: AppColors.merchant,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(Sp.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Astuce',
                                style: AppTextStyles.caption().copyWith(
                                  color: AppColors.merchant,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: Sp.xs),
                              Text(
                                'Placez le QR à la caisse ou sur les tables pour maximiser les scans.',
                                style: AppTextStyles.bodyMd().copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Sp.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: Rd.card,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: Rd.card,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.merchant, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.labelBold().copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption().copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: Sp.sm),
          child,
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Sp.sm),
        decoration: BoxDecoration(
          color: AppColors.merchantTint.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.labelBold().copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption().copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
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
