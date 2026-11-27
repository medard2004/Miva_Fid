import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/pwa_install_service.dart';
import '../storage/web_local_storage.dart';
import '../theme/app_colors.dart';
import '../utils/toast_service.dart';

/// Bandeau d'installation PWA affiché en haut de l'écran (style Fidelix / web apps modernes).
///
/// Comportement :
/// 1. S'affiche uniquement sur le Web (kIsWeb).
/// 2. Vérifie si l'application est DÉJÀ installée (standalone / PWA installée) via [PwaInstallService.isInstalled()].
///    Si oui -> ne s'affiche jamais.
/// 3. Permet à l'utilisateur de fermer le bandeau (sauvegardé temporairement dans le stockage local pour 24h ou la session).
/// 4. Sur Android/Desktop avec support `beforeinstallprompt` -> déclenche l'installation native d'un clic.
/// 5. Sur iOS (Safari) -> ouvre un modal guidé pas-à-pas ("Partager" -> "Sur l'écran d'accueil").
class PwaTopInstallBanner extends StatefulWidget {
  const PwaTopInstallBanner({super.key});

  @override
  State<PwaTopInstallBanner> createState() => _PwaTopInstallBannerState();
}

class _PwaTopInstallBannerState extends State<PwaTopInstallBanner> {
  static const String _dismissStorageKey = 'miva_pwa_banner_dismissed_at';
  bool _isVisible = false;
  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  void _checkEligibility() {
    if (!kIsWeb) return;

    // Si déjà installée (mode standalone / PWA active), on n'affiche rien
    if (PwaInstallService.isInstalled()) {
      return;
    }

    // Vérifier si l'utilisateur l'a masqué récemment (dans les dernières 24h)
    try {
      final dismissedAtStr = webStorageGet(_dismissStorageKey);
      if (dismissedAtStr != null) {
        final dismissedAt = DateTime.tryParse(dismissedAtStr);
        if (dismissedAt != null &&
            DateTime.now().difference(dismissedAt) < const Duration(hours: 24)) {
          return;
        }
      }
    } catch (_) {}

    setState(() {
      _isVisible = true;
    });
  }

  void _dismiss() {
    try {
      webStorageSet(_dismissStorageKey, DateTime.now().toIso8601String());
    } catch (_) {}
    setState(() {
      _isVisible = false;
    });
  }

  Future<void> _handleInstall() async {
    if (_isInstalling) return;

    // 1. Détection iOS : guide pas à pas
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _showIosGuide(context);
      return;
    }

    // 2. Si on a le prompt natif Chrome/Edge/Android
    setState(() => _isInstalling = true);
    try {
      final accepted = await PwaInstallService.promptInstall();
      if (accepted) {
        ToastService.showSuccess('Installation de l\'application démarrée !');
        setState(() {
          _isVisible = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('[PwaTopInstallBanner] Erreur install: $e');
    } finally {
      if (mounted) setState(() => _isInstalling = false);
    }

    // Si le prompt natif n'est pas dispo (ex: navigateur sans prompt ou desktop particulier),
    // on ouvre le guide adapté
    if (mounted) {
      _showGeneralGuide(context);
    }
  }

  void _showIosGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'icons/Icon-192.png',
                      errorBuilder: (_, __, ___) => const Icon(
                        LucideIcons.smartphone,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Installer Miva Fid sur iPhone / iPad',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Accès direct en plein écran & notifications',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInstructionStep(
                number: '1',
                title: 'Appuyez sur le bouton Partager',
                subtitle: 'L\'icône de carré avec une flèche vers le haut [⬆️] en bas de Safari.',
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                number: '2',
                title: 'Sélectionnez « Sur l\'écran d\'accueil »',
                subtitle: 'Faites défiler les options de la liste vers le bas.',
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                number: '3',
                title: 'Appuyez sur « Ajouter »',
                subtitle: 'En haut à droite de votre écran.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'J\'ai compris',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGeneralGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ajouter à l\'écran d\'accueil',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pour installer l\'application sur votre appareil :\n'
                '1. Ouvrez le menu de votre navigateur (les 3 points ⋮ en haut ou en bas).\n'
                '2. Cliquez sur « Installer l\'application » ou « Ajouter à l\'écran d\'accueil ».\n'
                '3. Confirmez pour retrouver Miva Fid parmi vos applications.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Compris'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Gradient moderne et élégant
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Logo / Icône PWA
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'icons/Icon-192.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    LucideIcons.sparkles,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Textes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Installer Miva Fid',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4F46E5),
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        child: const Text(
                          'PWA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Accédez à vos cartes et alertes plus rapidement',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFE0E7FF),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Bouton Installer
            ElevatedButton(
              onPressed: _isInstalling ? null : _handleInstall,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(
                    color: Color(0xFF818CF8),
                    width: 0.8,
                  ),
                ),
              ),
              child: _isInstalling
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Installer',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),

            const SizedBox(width: 6),

            // Bouton Fermer (X)
            IconButton(
              onPressed: _dismiss,
              icon: const Icon(LucideIcons.x, color: Color(0xFFC7D2FE), size: 18),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Fermer',
            ),
          ],
        ),
      ),
    );
  }
}
