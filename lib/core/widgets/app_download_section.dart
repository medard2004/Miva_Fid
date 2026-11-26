import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/pwa_install_service.dart';
import '../theme/app_colors.dart';
import '../utils/qr_link_helper.dart';
import '../utils/toast_service.dart';

enum AppDownloadTarget { client, merchant }

/// Section d'appel à l'action (CTA) mettant en avant le téléchargement /
/// l'installation des applications Client et Marchand selon la plateforme
/// (Android, iOS Safari, Desktop avec QR code, ou invite PWA native).
class AppDownloadSection extends StatelessWidget {
  final AppDownloadTarget primaryTarget;
  final bool showBoth;

  const AppDownloadSection({
    super.key,
    required this.primaryTarget,
    this.showBoth = true,
  });

  static const String _merchantWebUrl = String.fromEnvironment(
    'MERCHANT_WEB_APP_URL',
    defaultValue: 'https://miva-fid-app.vercel.app',
  );
  static const String _clientStoreUrl = String.fromEnvironment(
    'CLIENT_STORE_URL',
    defaultValue: '',
  );
  static const String _merchantStoreUrl = String.fromEnvironment(
    'MERCHANT_STORE_URL',
    defaultValue: '',
  );

  String _urlFor(AppDownloadTarget target) {
    if (target == AppDownloadTarget.client) {
      return _clientStoreUrl.isNotEmpty
          ? _clientStoreUrl
          : QrLinkHelper.webAppBaseUrl;
    }
    return _merchantStoreUrl.isNotEmpty ? _merchantStoreUrl : _merchantWebUrl;
  }

  Future<void> _handleDownload(
    BuildContext context,
    AppDownloadTarget target,
  ) async {
    final targetUrl = _urlFor(target);
    final isCurrentApp = target == primaryTarget;

    // 1. Sur Web : si l'utilisateur clique pour l'app en cours et que la PWA
    //    propose déjà l'invite native, on la déclenche immédiatement.
    if (kIsWeb && isCurrentApp && PwaInstallService.canPromptInstall()) {
      final accepted = await PwaInstallService.promptInstall();
      if (accepted) {
        ToastService.showSuccess('Installation de l\'application démarrée !');
        return;
      }
    }

    // 2. Détection de la plateforme pour adapter l'expérience :
    if (kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        if (!context.mounted) return;
        _showIosGuide(context, target, targetUrl, isCurrentApp);
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        if (!isCurrentApp || _clientStoreUrl.isNotEmpty || _merchantStoreUrl.isNotEmpty) {
          await _openExternal(targetUrl);
          return;
        }
        if (!context.mounted) return;
        _showAndroidGuide(context, target, targetUrl);
        return;
      }

      // Desktop (Windows / macOS / Linux) : afficher QR code scannable + lien
      if (!context.mounted) return;
      _showDesktopQrModal(context, target, targetUrl);
      return;
    }

    // Sur mobile natif, ouvrir le lien store/web correspondant.
    await _openExternal(targetUrl);
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ToastService.showError('Impossible d\'ouvrir le lien de téléchargement.');
    }
  }

  void _showIosGuide(
    BuildContext context,
    AppDownloadTarget target,
    String url,
    bool isCurrentApp,
  ) {
    final label = target == AppDownloadTarget.client ? 'Client' : 'Marchand';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Installer l\'app $label sur iPhone',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (!isCurrentApp) ...[
              const Text(
                'Ouvrez d\'abord la page dédiée dans Safari, puis suivez les étapes :',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openExternal(url);
                  },
                  icon: const Icon(LucideIcons.externalLink, size: 16),
                  label: Text('Ouvrir l\'app $label'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text('1. Appuyez sur le bouton Partager en bas de Safari.'),
            const SizedBox(height: 6),
            const Text('2. Faites défiler et choisissez « Sur l\'écran d\'accueil ».'),
            const SizedBox(height: 6),
            const Text('3. Appuyez sur « Ajouter » en haut à droite.'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAndroidGuide(
    BuildContext context,
    AppDownloadTarget target,
    String url,
  ) {
    final label = target == AppDownloadTarget.client ? 'Client' : 'Marchand';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Installer l\'app $label sur Android',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text('1. Appuyez sur le menu ⋮ en haut à droite de Chrome.'),
            const SizedBox(height: 6),
            const Text('2. Sélectionnez « Installer l\'application » ou « Ajouter à l\'écran d\'accueil ».'),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                Navigator.pop(ctx);
                ToastService.showSuccess('Lien copié dans le presse-papiers');
              },
              icon: const Icon(LucideIcons.copy, size: 16),
              label: const Text('Copier le lien'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDesktopQrModal(
    BuildContext context,
    AppDownloadTarget target,
    String url,
  ) {
    final label = target == AppDownloadTarget.client ? 'Client' : 'Marchand';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Télécharger l\'app $label',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scannez ce QR code avec votre téléphone pour installer ou ouvrir l\'application :',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: QrImageView(
                  data: url,
                  size: 180,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ToastService.showSuccess('Lien copié !');
                    },
                    icon: const Icon(LucideIcons.copy, size: 15),
                    label: const Text('Copier le lien'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openExternal(url);
                    },
                    icon: const Icon(LucideIcons.externalLink, size: 15),
                    label: const Text('Ouvrir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && PwaInstallService.isInstalled() && !showBoth) {
      return const SizedBox.shrink();
    }

    final secondaryTarget = primaryTarget == AppDownloadTarget.client
        ? AppDownloadTarget.merchant
        : AppDownloadTarget.client;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.smartphone, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Installer les applications Miva Fid',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DownloadTileButton(
            label: primaryTarget == AppDownloadTarget.client
                ? 'Télécharger l\'app Client'
                : 'Télécharger l\'app Marchand',
            subtitle: primaryTarget == AppDownloadTarget.client
                ? 'Cartes de fidélité, récompenses & Google Wallet'
                : 'Scanner clients, campagnes push & statistiques',
            isDarkBadge: primaryTarget == AppDownloadTarget.client,
            isPrimary: true,
            onTap: () => _handleDownload(context, primaryTarget),
          ),
          if (showBoth) ...[
            const SizedBox(height: 8),
            _DownloadTileButton(
              label: secondaryTarget == AppDownloadTarget.client
                  ? 'Télécharger l\'app Client'
                  : 'Télécharger l\'app Marchand',
              subtitle: secondaryTarget == AppDownloadTarget.client
                  ? 'Vous êtes client ? Accédez à vos cartes'
                  : 'Vous êtes commerçant ? Gérez votre boutique',
              isDarkBadge: secondaryTarget == AppDownloadTarget.client,
              isPrimary: false,
              onTap: () => _handleDownload(context, secondaryTarget),
            ),
          ],
        ],
      ),
    );
  }
}

class _DownloadTileButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isDarkBadge;
  final bool isPrimary;
  final VoidCallback onTap;

  const _DownloadTileButton({
    required this.label,
    required this.subtitle,
    required this.isDarkBadge,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? null
                : Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDarkBadge ? const Color(0xFF0F0E1A) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: Icon(
                  LucideIcons.download,
                  size: 16,
                  color: isDarkBadge ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isPrimary ? Colors.white : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: isPrimary ? Colors.white : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
