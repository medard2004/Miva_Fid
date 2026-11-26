import 'package:url_launcher/url_launcher.dart';

import 'toast_service.dart';

/// Utilitaires centralisés de validation, normalisation et aperçu des liens
/// et identifiants de réseaux sociaux (utilisés dans l'onboarding marchand,
/// les paramètres des réseaux sociaux et la fiche vitrine client).
class SocialLinksHelper {
  SocialLinksHelper._();

  static final RegExp _handlePattern = RegExp(r'^[a-zA-Z0-9._-]+$');

  /// Nettoie et normalise la saisie utilisateur (accepte `@pseudo`, `pseudo`
  /// ou une URL complète collée).
  static String normalize(String platform, String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    switch (platform.toLowerCase()) {
      case 'whatsapp':
        var val = trimmed;
        if (val.contains('wa.me/')) {
          val = val.split('wa.me/').last.split('?').first.split('/').first;
        } else if (val.contains('phone=')) {
          val = val.split('phone=').last.split('&').first;
        }
        final hasPlus = val.startsWith('+');
        final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isEmpty) return trimmed;
        return hasPlus ? '+$digits' : digits;

      case 'instagram':
        return _extractSlug(
          trimmed,
          hosts: const ['instagram.com/', 'instagr.am/'],
          stripAt: true,
        );

      case 'tiktok':
        return _extractSlug(
          trimmed,
          hosts: const ['tiktok.com/@', 'tiktok.com/'],
          stripAt: true,
        );

      case 'x':
      case 'twitter':
        return _extractSlug(
          trimmed,
          hosts: const ['x.com/', 'twitter.com/'],
          stripAt: true,
        );

      case 'facebook':
        var val = trimmed;
        for (final host in const ['facebook.com/', 'fb.com/', 'fb.me/']) {
          if (val.toLowerCase().contains(host)) {
            final idx = val.toLowerCase().indexOf(host) + host.length;
            val = val.substring(idx);
            break;
          }
        }
        if (val.startsWith('profile.php?id=')) {
          return val.split('&').first.trim();
        }
        val = val.split('?').first;
        while (val.endsWith('/')) {
          val = val.substring(0, val.length - 1);
        }
        if (val.startsWith('@')) {
          val = val.substring(1);
        }
        return val.trim();

      case 'website':
        var val = trimmed;
        if (!val.startsWith('http://') && !val.startsWith('https://')) {
          val = 'https://$val';
        }
        return val;

      default:
        return trimmed;
    }
  }

  static String _extractSlug(
    String input, {
    required List<String> hosts,
    required bool stripAt,
  }) {
    var val = input.trim();
    final lower = val.toLowerCase();
    for (final host in hosts) {
      if (lower.contains(host)) {
        final idx = lower.indexOf(host) + host.length;
        val = val.substring(idx);
        break;
      }
    }
    val = val.split('?').first.split('#').first;
    // Garder uniquement le premier segment (ex: handle/reels -> handle)
    if (val.contains('/')) {
      val = val.split('/').firstWhere((s) => s.isNotEmpty, orElse: () => '');
    }
    if (stripAt && val.startsWith('@')) {
      val = val.substring(1);
    }
    return val.trim();
  }

  /// Valide la saisie et retourne `null` si vide (facultatif) ou valide,
  /// sinon un message d'erreur clair en français.
  static String? validate(String platform, String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final normalized = normalize(platform, trimmed);

    switch (platform.toLowerCase()) {
      case 'whatsapp':
        if (RegExp(r'[a-zA-Z]').hasMatch(trimmed) &&
            !trimmed.toLowerCase().contains('wa.me') &&
            !trimmed.toLowerCase().contains('whatsapp.com')) {
          return 'Entrez un numéro WhatsApp valide (ex: +228 90 00 00 00).';
        }
        final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 8 || digits.length > 15) {
          return 'Le numéro WhatsApp doit contenir entre 8 et 15 chiffres.';
        }
        return null;

      case 'instagram':
      case 'tiktok':
      case 'x':
      case 'twitter':
        if (normalized.isEmpty) {
          return 'Identifiant ou lien invalide.';
        }
        if (normalized.contains(' ')) {
          return 'Supprimez les espaces : utilisez votre pseudo exact (@nom) ou collez le lien.';
        }
        if (!_handlePattern.hasMatch(normalized)) {
          return 'Caractères autorisés : lettres, chiffres, points, tirets et _.';
        }
        return null;

      case 'facebook':
        if (normalized.isEmpty) {
          return 'Lien ou identifiant Facebook invalide.';
        }
        if (normalized.startsWith('profile.php?id=')) {
          final idPart = normalized.substring('profile.php?id='.length);
          if (!RegExp(r'^\d+$').hasMatch(idPart)) {
            return 'Identifiant de profil Facebook invalide.';
          }
          return null;
        }
        if (normalized.contains(' ')) {
          return 'Pas d\'espaces : collez le lien facebook.com/... ou tapez l\'identifiant de page.';
        }
        if (!RegExp(r'^[a-zA-Z0-9._/-]+$').hasMatch(normalized)) {
          return 'Identifiant ou lien Facebook invalide.';
        }
        return null;

      case 'website':
        if (normalized.contains(' ')) {
          return 'L\'adresse du site web ne doit pas contenir d\'espaces.';
        }
        final uri = Uri.tryParse(normalized);
        if (uri == null ||
            !uri.hasScheme ||
            uri.host.isEmpty ||
            !uri.host.contains('.')) {
          return 'Entrez une adresse valide (ex: https://moncommerce.com).';
        }
        final tld = uri.host.split('.').last;
        if (tld.length < 2) {
          return 'Nom de domaine invalide (ex: moncommerce.com).';
        }
        return null;

      default:
        return null;
    }
  }

  /// Construit l'URL externe complète prête à être ouverte.
  static String buildUrl(String platform, String raw) {
    final normalized = normalize(platform, raw);
    if (normalized.isEmpty) return '';

    switch (platform.toLowerCase()) {
      case 'whatsapp':
        final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');
        return digits.isEmpty ? '' : 'https://wa.me/$digits';
      case 'instagram':
        return 'https://instagram.com/$normalized';
      case 'facebook':
        return 'https://facebook.com/$normalized';
      case 'tiktok':
        return 'https://tiktok.com/@$normalized';
      case 'x':
      case 'twitter':
        return 'https://x.com/$normalized';
      case 'website':
        return normalized;
      default:
        return normalized;
    }
  }

  /// Texte court lisible pour l'aperçu du lien (sans `https://`).
  static String previewLabel(String platform, String raw) {
    final url = buildUrl(platform, raw);
    if (url.isEmpty) return '';
    return url.replaceFirst(RegExp(r'^https?://'), '');
  }

  /// Ouvre le lien dans le navigateur pour permettre au marchand de tester.
  static Future<void> launchTest(String platform, String raw) async {
    final error = validate(platform, raw);
    if (error != null) {
      ToastService.showError(error);
      return;
    }
    final url = buildUrl(platform, raw);
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ToastService.showError('Lien invalide.');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        ToastService.showError("Impossible d'ouvrir ce lien.");
      }
    } catch (_) {
      ToastService.showError("Impossible d'ouvrir ce lien.");
    }
  }
}
