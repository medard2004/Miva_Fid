import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/gen/app_localizations.dart';

import '../providers/dashboard_stats_provider.dart';
import '../providers/merchant_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../../client/providers/settings_provider.dart';

class QrCodeScreen extends ConsumerStatefulWidget {
  const QrCodeScreen({super.key});

  @override
  ConsumerState<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends ConsumerState<QrCodeScreen> {
  final _qrCardKey = GlobalKey();
  bool _exporting = false;

  Future<void> _exportPng() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final boundary = _qrCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image =
          await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/mivafid-qr-${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)],
          text: 'Scannez pour rejoindre mon programme de fidélité Miva-Fid !');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'exporter l'image.")),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
                // Title and Subtitle
                Text(
                  t.merchantMoreMyQrCode,
                  style: AppTextStyles.h1().copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.merchantQrCodeSubtitle,
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: Sp.md),

                // QR Code Card
                RepaintBoundary(
                  key: _qrCardKey,
                  child: Container(
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
                ),
                const SizedBox(height: Sp.md),

                // Download/Print/Share Row
                Row(
                  children: [
                    _buildActionButton(
                      icon: LucideIcons.fileDown,
                      label: 'PNG',
                      onTap: _exportPng,
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

                // Statistiques Section Card — vraies données du dashboard
                // (`GET /merchant/stats`), plus de compteurs fictifs.
                _buildSectionContainer(
                  title: t.merchantDashboardTitle,
                  child: statsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: Sp.sm),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (_, __) => Text(
                      'Statistiques indisponibles.',
                      style: AppTextStyles.caption()
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    data: (stats) => Row(
                      children: [
                        _buildStatBox(
                            value: '${stats.totalClients}', label: 'Clients'),
                        const SizedBox(width: Sp.xs),
                        _buildStatBox(
                            value: '${stats.stampsToday}',
                            label: 'Tampons auj.'),
                        const SizedBox(width: Sp.xs),
                        _buildStatBox(
                            value: '${stats.activeRewards}',
                            label: 'Récompenses'),
                      ],
                    ),
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
      pageFormat: PdfPageFormat.a4,
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
