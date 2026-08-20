import 'package:flutter/material.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';

/// Document légal affiché par [LegalScreen].
enum LegalDocument { terms, privacy }

class _LegalSection {
  final String heading;
  final String body;
  const _LegalSection(this.heading, this.body);
}

/// Écran statique CGU / politique de confidentialité, atteint depuis le
/// footer des écrans d'authentification client ou des paramètres. Le
/// contenu est un texte générique pour un programme de fidélité — à faire
/// relire par un juriste avant mise en production.
class LegalScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final title = document == LegalDocument.terms
        ? t.legalTermsTitle
        : t.legalPrivacyTitle;
    final sections = isEnglish
        ? (document == LegalDocument.terms ? _termsEn : _privacyEn)
        : (document == LegalDocument.terms ? _termsFr : _privacyFr);
    final updatedAt = isEnglish ? 'Last updated: August 15, 2026' : 'Dernière mise à jour : 15 août 2026';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(title: title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          Text(
            updatedAt,
            style: AppTextStyles.bodySmall(color: AppColors.inkMuted(opacity: 0.55)),
          ),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            Text(section.heading, style: AppTextStyles.titleMedium()),
            const SizedBox(height: 8),
            Text(
              section.body,
              style: AppTextStyles.bodyMedium(color: AppColors.inkMuted(opacity: 0.85)),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

const _termsFr = [
  _LegalSection(
    '1. Objet',
    "Les présentes Conditions Générales d'Utilisation régissent l'accès et "
        "l'usage de l'application Miva Fid, qui permet aux clients de "
        "commerçants partenaires de cumuler des points, tampons ou cashback, "
        "de suivre leurs récompenses et de parrainer d'autres membres.",
  ),
  _LegalSection(
    '2. Création de compte',
    "L'inscription se fait par numéro de téléphone et mot de passe, ou via "
        "Google / Apple. Vous êtes responsable de l'exactitude des "
        "informations fournies (nom, date de naissance, téléphone, email) "
        "et de la confidentialité de vos identifiants.",
  ),
  _LegalSection(
    '3. Programme de fidélité',
    "Les points, tampons et récompenses sont attribués par chaque "
        "commerçant partenaire selon les règles de son propre programme. "
        "Miva Fid ne garantit ni la valeur ni la disponibilité continue "
        "d'une récompense, qui reste à la discrétion du commerçant.",
  ),
  _LegalSection(
    '4. Parrainage',
    "Le programme de parrainage peut donner droit à des avantages sous "
        "réserve que le filleul complète son inscription. Tout usage "
        "frauduleux (faux comptes, parrainages automatisés) entraîne "
        "l'annulation des avantages et peut justifier la suspension du "
        "compte.",
  ),
  _LegalSection(
    '5. Usage autorisé',
    "Vous vous engagez à ne pas détourner l'application (fraude, "
        "usurpation d'identité, scan de QR code n'appartenant pas à un "
        "commerçant partenaire) ni à porter atteinte à son fonctionnement.",
  ),
  _LegalSection(
    '6. Résiliation',
    "Vous pouvez supprimer votre compte à tout moment depuis les "
        "paramètres. Miva Fid peut suspendre ou résilier un compte en cas "
        "de violation des présentes CGU.",
  ),
  _LegalSection(
    '7. Modification',
    "Ces CGU peuvent être mises à jour ; toute modification substantielle "
        "vous sera notifiée dans l'application.",
  ),
];

const _privacyFr = [
  _LegalSection(
    '1. Données collectées',
    "Nous collectons les données que vous fournissez à l'inscription et "
        "dans votre profil : nom, numéro de téléphone, date de naissance, "
        "email (facultatif), ville, pays, quartier, photo de profil, ainsi "
        "que les données liées à l'usage de l'application (points, "
        "récompenses, historique de scan, parrainages).",
  ),
  _LegalSection(
    '2. Finalité',
    "Ces données servent à créer et sécuriser votre compte, faire "
        "fonctionner le programme de fidélité avec les commerçants "
        "partenaires, calculer vos récompenses et parrainages, et vous "
        "envoyer des notifications liées à votre activité.",
  ),
  _LegalSection(
    '3. Partage avec les commerçants',
    "Le commerçant partenaire auprès duquel vous cumulez des points a "
        "accès aux données nécessaires au fonctionnement du programme "
        "(nom, activité de fidélité). Il ne reçoit pas votre mot de passe "
        "ni vos identifiants d'authentification.",
  ),
  _LegalSection(
    '4. Authentification tierce',
    "Si vous vous connectez via Google ou Apple, nous recevons uniquement "
        "les informations nécessaires à la création du compte (nom, email) "
        "transmises par ces services, conformément à leurs propres "
        "politiques de confidentialité.",
  ),
  _LegalSection(
    '5. Conservation',
    "Vos données sont conservées tant que votre compte est actif. En cas "
        "de suppression de compte, elles sont supprimées ou anonymisées "
        "dans un délai raisonnable, sauf obligation légale de "
        "conservation.",
  ),
  _LegalSection(
    '6. Vos droits',
    "Vous pouvez accéder, corriger ou supprimer vos données depuis votre "
        "profil, ou en contactant le support. Vous pouvez également "
        "demander la portabilité de vos données.",
  ),
  _LegalSection(
    '7. Sécurité',
    "Nous mettons en œuvre des mesures techniques raisonnables pour "
        "protéger vos données contre l'accès non autorisé, la perte ou "
        "l'altération.",
  ),
];

const _termsEn = [
  _LegalSection(
    '1. Purpose',
    "These Terms of Use govern access to and use of the Miva Fid app, "
        "which lets customers of partner merchants earn points, stamps or "
        "cashback, track their rewards, and refer other members.",
  ),
  _LegalSection(
    '2. Creating an account',
    "You can sign up with a phone number and password, or via Google / "
        "Apple. You are responsible for the accuracy of the information "
        "you provide (name, date of birth, phone number, email) and for "
        "keeping your credentials confidential.",
  ),
  _LegalSection(
    '3. Loyalty program',
    "Points, stamps and rewards are granted by each partner merchant "
        "under the rules of their own program. Miva Fid does not "
        "guarantee the value or continued availability of any reward, "
        "which remains at the merchant's discretion.",
  ),
  _LegalSection(
    '4. Referrals',
    "The referral program may grant benefits once a referred friend "
        "completes signup. Any fraudulent use (fake accounts, automated "
        "referrals) will void the benefits and may lead to account "
        "suspension.",
  ),
  _LegalSection(
    '5. Acceptable use',
    "You agree not to misuse the app (fraud, identity theft, scanning a "
        "QR code that does not belong to a partner merchant) or interfere "
        "with its operation.",
  ),
  _LegalSection(
    '6. Termination',
    "You may delete your account at any time from settings. Miva Fid may "
        "suspend or terminate an account that violates these Terms.",
  ),
  _LegalSection(
    '7. Changes',
    "These Terms may be updated from time to time; you will be notified "
        "in the app of any material change.",
  ),
];

const _privacyEn = [
  _LegalSection(
    '1. Data we collect',
    "We collect the data you provide at signup and in your profile: "
        "name, phone number, date of birth, email (optional), city, "
        "country, neighborhood, profile photo, as well as data related to "
        "your use of the app (points, rewards, scan history, referrals).",
  ),
  _LegalSection(
    '2. Purpose',
    "This data is used to create and secure your account, operate the "
        "loyalty program with partner merchants, calculate your rewards "
        "and referrals, and send you notifications about your activity.",
  ),
  _LegalSection(
    '3. Sharing with merchants',
    "The partner merchant you earn points with has access to the data "
        "needed to run the loyalty program (name, loyalty activity). They "
        "never receive your password or authentication credentials.",
  ),
  _LegalSection(
    '4. Third-party sign-in',
    "If you sign in with Google or Apple, we only receive the "
        "information needed to create your account (name, email) as "
        "provided by those services, subject to their own privacy "
        "policies.",
  ),
  _LegalSection(
    '5. Retention',
    "Your data is kept as long as your account is active. If you delete "
        "your account, it is deleted or anonymized within a reasonable "
        "time, unless we are legally required to retain it.",
  ),
  _LegalSection(
    '6. Your rights',
    "You can access, correct or delete your data from your profile, or "
        "by contacting support. You may also request a copy of your "
        "data.",
  ),
  _LegalSection(
    '7. Security',
    "We use reasonable technical measures to protect your data against "
        "unauthorized access, loss or alteration.",
  ),
];
