import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/gen/app_localizations.dart';

import '../providers/merchant_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../../client/providers/settings_provider.dart';

class QrCodeScreen extends ConsumerWidget {
  const QrCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ces ecrans peignent via les tokens statiques d'AppColors,
    // invisibles pour le systeme de dependances de Flutter : observer
    // la luminosite effective est leur seul declencheur de rebuild sur
    // une bascule clair/sombre.
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final merchantAsync = ref.watch(merchantNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          t.merchantMoreMyQrCode,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              context.go('/merchant/validate');
            }
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: merchantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(t.merchantQrCodeLoadError)),
        data: (merchant) {
          // Le QR encode le `qr_token` Laravel réel (celui que
          // `joinByQrToken` vérifie côté client) — jamais un identifiant
          // Supabase, obsolète depuis la migration de l'auth marchand.
          final restaurant = ref.watch(merchantAuthProvider).restaurant;
          final qrData = restaurant?.qrToken ?? '';
          final shortCode = restaurant?.shortCode ?? '';
          final merchantName = merchant?.name ?? 'Votre Commerce';
          final merchantAddress = merchant?.address ?? '';
          final merchantPhone = merchant?.phone ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.merchantQrCodeSubtitle,
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
                    color: AppColors.surface,
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
                            child: qrData.isEmpty
                                ? const SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : QrImageView(
                                    data: qrData,
                                    size: 200,
                                    eyeStyle: QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: AppColors.textPrimary,
                                    ),
                                    dataModuleStyle: QrDataModuleStyle(
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
                              LucideIcons.scanLine,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sp.md),
                      Text(
                        merchantName,
                        style: AppTextStyles.labelBold().copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.merchantQrCodeScanToEarnLabel,
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
                      icon: LucideIcons.fileDown,
                      label: 'PNG',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.merchantQrCodePngSavedToast)),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: LucideIcons.printer,
                      label: 'A4',
                      onTap: () => _generatePdf(t, merchantName, merchantAddress, merchantPhone, qrData),
                    ),
                    _buildActionButton(
                      icon: LucideIcons.share,
                      label: t.merchantQrCodeShareButton,
                      onTap: () => _shareWhatsApp(t, merchantName),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.md),

                // CODE UNIQUE Section Card — alternative à taper à la main
                // quand le client ne peut pas scanner le QR.
                _buildSectionContainer(
                  title: t.merchantQrCodeUniqueCodeSection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            shortCode.isEmpty ? '—' : shortCode,
                            style: AppTextStyles.mono().copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.copy, color: AppColors.textSecondary, size: 20),
                          onPressed: shortCode.isEmpty
                              ? null
                              : () {
                                  Clipboard.setData(ClipboardData(text: shortCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.merchantQrCodeCodeCopiedToast)),
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
                  title: t.merchantDashboardTitle,
                  child: Row(
                    children: [
                      _buildStatBox(value: '43', label: t.merchantQrCodeThisWeekLabel),
                      const SizedBox(width: Sp.xs),
                      _buildStatBox(value: '183', label: t.merchantQrCodeThisMonthLabel),
                      const SizedBox(width: Sp.xs),
                      _buildStatBox(value: '12', label: t.merchantQrCodeNewLabel),
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
                                t.merchantQrCodeTipLabel,
                                style: AppTextStyles.caption().copyWith(
                                  color: AppColors.merchant,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: Sp.xs),
                              Text(
                                t.merchantQrCodeTipMessage,
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
          color: AppColors.surface,
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
        color: AppColors.surface,
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

  Future<void> _generatePdf(AppLocalizations t, String name, String address, String phone, String qrData) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(name, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text(t.merchantQrCodePdfScanMessage, style: const pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 20),
          pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: qrData, width: 200, height: 200),
          pw.SizedBox(height: 20),
          if (address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 12)),
          if (phone.isNotEmpty) pw.Text(phone, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 12),
          pw.Text(t.merchantQrCodePdfPoweredBy, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ],
      ),
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'mivafid-comptoir.pdf');
  }

  Future<void> _shareWhatsApp(AppLocalizations t, String name) async {
    final msg = Uri.encodeComponent(t.merchantQrCodeWhatsappShareMessage(name));
    final url = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}
