import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/theme/app_colors.dart';
import 'package:miva_fid/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

enum MerchantLegalDocument { terms, privacy }

class _LegalSection {
  final String heading;
  final String body;
  const _LegalSection(this.heading, this.body);
}

class MerchantLegalScreen extends StatelessWidget {
  final MerchantLegalDocument document;

  const MerchantLegalScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final title = document == MerchantLegalDocument.terms
        ? t.legalTermsTitle
        : t.legalPrivacyTitle;
    final sections = isEnglish
        ? (document == MerchantLegalDocument.terms ? _termsEn : _privacyEn)
        : (document == MerchantLegalDocument.terms ? _termsFr : _privacyFr);
    final updatedAt = isEnglish ? 'Last updated: August 15, 2026' : 'Dernière mise à jour : 15 août 2026';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.h3().copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          Text(
            updatedAt,
            style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            Text(section.heading, style: AppTextStyles.h3().copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              section.body,
              style: AppTextStyles.body().copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

const List<_LegalSection> _termsFr = [
  _LegalSection(
    '1. Objet du service Marchand',
    'Miva Fid fournit aux commerçants une plateforme numérique de fidélisation client et de gestion des campagnes promotionnelles.',
  ),
  _LegalSection(
    '2. Gestion du compte et responsabilités',
    'Le commerçant est responsable de la confidentialité de ses identifiants de connexion et de l\'utilisation loyale du programme de fidélité proposé à ses clients.',
  ),
  _LegalSection(
    '3. Émissions et validations de points',
    'Toute transaction validée via le scanner QR ou saisie manuelle engage la responsabilité du commerçant vis-à-vis des avantages accordés.',
  ),
  _LegalSection(
    '4. Disponibilité du service',
    'Miva Fid s\'efforce d\'assurer une disponibilité maximale de la plateforme avec support du fonctionnement hors ligne en cas d\'interruption réseau temporaire.',
  ),
];

const List<_LegalSection> _termsEn = [
  _LegalSection(
    '1. Purpose of Merchant Service',
    'Miva Fid provides merchants with a digital customer loyalty and promotional campaign platform.',
  ),
  _LegalSection(
    '2. Account Management and Responsibilities',
    'The merchant is responsible for the confidentiality of login credentials and the fair use of the loyalty program offered to customers.',
  ),
  _LegalSection(
    '3. Points Issuance and Validation',
    'Any transaction validated via the QR scanner or manual entry engages the merchant\'s responsibility regarding awarded perks.',
  ),
  _LegalSection(
    '4. Service Availability',
    'Miva Fid strives to ensure maximum platform availability with offline operation support during temporary network interruptions.',
  ),
];

const List<_LegalSection> _privacyFr = [
  _LegalSection(
    '1. Données collectées',
    'Miva Fid collecte les informations professionnelles de l\'établissement nécessaires à la fourniture du service.',
  ),
  _LegalSection(
    '2. Utilisation des données',
    'Les données ne sont ni vendues ni cédées à des tiers et servent exclusivement à la gestion du programme de fidélité.',
  ),
  _LegalSection(
    '3. Sécurité et confidentialité',
    'Toutes les communications réseau sont chiffrées (HTTPS/TLS) et les jetons d\'accès sont protégés.',
  ),
];

const List<_LegalSection> _privacyEn = [
  _LegalSection(
    '1. Data Collected',
    'Miva Fid collects business information necessary to provide the service.',
  ),
  _LegalSection(
    '2. Use of Data',
    'Data is neither sold nor transferred to third parties and is used exclusively for loyalty program management.',
  ),
  _LegalSection(
    '3. Security and Confidentiality',
    'All network communications are encrypted (HTTPS/TLS) and access tokens are secured.',
  ),
];

