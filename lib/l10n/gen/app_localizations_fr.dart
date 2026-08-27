// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navWallet => 'Wallet';

  @override
  String get navRewards => 'Récompenses';

  @override
  String get navReferral => 'Parrainage';

  @override
  String get navProfile => 'Profil';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonDone => 'Terminé';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsPreferences => 'Préférences';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Gérer les alertes par établissement';

  @override
  String get settingsSignOut => 'Se déconnecter';

  @override
  String get settingsSignOutConfirmTitle => 'Déconnexion';

  @override
  String get settingsSignOutConfirmMessage =>
      'Êtes-vous sûr de vouloir vous déconnecter de votre compte Carte ?';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileEditProfile => 'Modifier le profil';

  @override
  String profileMemberSince(String date) {
    return 'Membre depuis $date';
  }

  @override
  String get profileCards => 'Cartes';

  @override
  String get profileOffers => 'Offres';

  @override
  String get profileReferrals => 'Filleuls';

  @override
  String get profileNotConnectedTitle => 'Vous n\'êtes pas connecté';

  @override
  String get profileNotConnectedMessage =>
      'Connectez-vous pour accéder à votre profil.';

  @override
  String get profileSignIn => 'Se connecter';

  @override
  String get profileSettings => 'Paramètres';

  @override
  String get profileSettingsSubtitle => 'Apparence, langue, notifications';

  @override
  String get profileReferralCode => 'Votre code invitation';

  @override
  String get profileReferralCodeCopied =>
      'Code parrainage copié dans le presse-papier !';

  @override
  String get profileBirthdayBannerTitle => 'Joyeux mois d\'anniversaire !';

  @override
  String get profileBirthdayBannerMessage =>
      'Des attentions exclusives vous attendent dans vos restaurants.';

  @override
  String get editProfileTitle => 'Modifier le profil';

  @override
  String get editProfileFullName => 'Nom complet';

  @override
  String get editProfileFullNameHint => 'Kokou John';

  @override
  String get editProfileFullNameError => 'Veuillez saisir votre nom complet';

  @override
  String get editProfilePhone => 'Numéro de téléphone';

  @override
  String get editProfileBirthDate => 'Date de naissance';

  @override
  String get editProfileEmail => 'Email';

  @override
  String get editProfileEmailHint => 'votre@email.com';

  @override
  String get editProfileSaveSuccess => 'Profil mis à jour avec succès !';

  @override
  String get referralTitle => 'Parrainage';

  @override
  String get referralSubtitle =>
      'Recommandez vos restaurants favoris et cumulez des points.';

  @override
  String get referralEmptyTitle => 'Aucune carte à parrainer';

  @override
  String get referralEmptyMessage =>
      'Rejoignez au moins un établissement pour pouvoir le recommander à vos proches.';

  @override
  String get referralPointsLabel => 'Points de parrainage';

  @override
  String referralPointsEarned(int count) {
    return '$count points cumulés';
  }

  @override
  String referralSharesToNext(int count) {
    return 'Encore $count partages';
  }

  @override
  String get referralChoosePartner => 'Choisir le partenaire';

  @override
  String get referralRecipientHint => 'Téléphone ou nom';

  @override
  String get referralSendButton => 'Envoyer l\'invitation';

  @override
  String referralSendButtonWithCount(int count) {
    return 'Envoyer l\'invitation ($count)';
  }

  @override
  String get referralDuplicateRecipient =>
      'Ce destinataire est déjà dans votre liste d\'envoi.';

  @override
  String get referralNoRecipient =>
      'Veuillez ajouter au moins un destinataire avant d\'envoyer.';

  @override
  String referralSentSuccess(int count) {
    return '$count invitation(s) envoyée(s) !';
  }

  @override
  String get referralHistoryTitle => 'Historique des partages';

  @override
  String get referralHistoryEmpty => 'Aucun partage effectué pour le moment.';

  @override
  String get referralMessageLabel => 'Votre message';

  @override
  String get referralRecipientsLabel => 'Destinataires';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Tout marquer lu';

  @override
  String get notificationsEmptyTitle => 'Aucune notification';

  @override
  String get notificationsEmptyMessage =>
      'Vous serez prévenu ici de vos tampons, récompenses et statuts VIP.';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonHistory => 'Historique';

  @override
  String get commonCountdownPrefix => 'J-';

  @override
  String get cardStampsLabel => 'TAMPONS';

  @override
  String get cardPointsLabel => 'SOLDE';

  @override
  String get cardPointsSuffix => 'PTS';

  @override
  String get cardSpendLabel => 'OBJECTIF ACHAT';

  @override
  String get cardCashbackLabel => 'CASHBACK';

  @override
  String get cardCashbackSuffix => 'FCFA';

  @override
  String get cardVipMaxTier => 'Palier maximum atteint';

  @override
  String cardVipNextTier(int count) {
    return 'Platinum dans $count visites';
  }

  @override
  String get rewardsTitle => 'Récompenses';

  @override
  String get rewardsEmptyActiveTitle => 'Aucun privilège disponible';

  @override
  String get rewardsEmptyActiveMessage =>
      'Revenez bientôt pour de nouvelles offres.';

  @override
  String get rewardsToUnlock => 'À débloquer';

  @override
  String get rewardsAllUnlockedTitle => 'Tout est débloqué';

  @override
  String get rewardsAllUnlockedMessage =>
      'Aucune récompense verrouillée pour le moment.';

  @override
  String get rewardsHistoryEmptyTitle => 'Aucun historique';

  @override
  String get rewardsHistoryEmptyMessage =>
      'Vos récompenses utilisées apparaîtront ici.';

  @override
  String get rewardsRedeemConfirmTitle => 'Utiliser cette récompense ?';

  @override
  String rewardsRedeemConfirmMessage(String title) {
    return '« $title » sera marquée comme utilisée et retirée de vos privilèges actifs. Présentez cet écran à l\'enseigne avant de confirmer.';
  }

  @override
  String get rewardsRedeemSuccess => 'Récompense marquée comme utilisée';

  @override
  String get rewardsUseButton => 'Utiliser';

  @override
  String get rewardsShowQrInstruction =>
      'Présentez ce code au marchand pour l\'utiliser. Valable une seule fois.';

  @override
  String get walletGreetingMorning => 'BONJOUR';

  @override
  String get walletGreetingAfternoon => 'BON APRÈS-MIDI';

  @override
  String get walletGreetingEvening => 'BONSOIR';

  @override
  String get walletFallbackName => 'vous';

  @override
  String get walletSearchSemanticLabel => 'Rechercher une carte';

  @override
  String get walletSearchHint => 'Rechercher une carte ou une enseigne';

  @override
  String get walletSearchNoResultsTitle => 'Aucune carte trouvée';

  @override
  String get walletSearchNoResultsMessage =>
      'Essayez un autre nom ou une autre enseigne.';

  @override
  String get walletEmptyTitle => 'Aucune carte pour l\'instant';

  @override
  String get walletEmptyMessage =>
      'Scannez votre premier QR pour commencer votre collection.';

  @override
  String get walletScanButton => 'Scanner un QR code';

  @override
  String get cardDetailNotFound => 'Carte introuvable';

  @override
  String get cardDetailTitle => 'Votre carte';

  @override
  String get cardDetailExportTooltip => 'Exporter / Partager';

  @override
  String get cardDetailDefaultOfferRestaurant => 'Offre';

  @override
  String get cardDetailDefaultOfferTitle => 'Récompense à venir';

  @override
  String get cardDetailDefaultOfferMessage =>
      'Continuez à cumuler pour débloquer votre prochain privilège.';

  @override
  String get cardDetailExportSheetTitle => 'Exportation';

  @override
  String get cardDetailSaveTitle => 'Enregistrer la carte';

  @override
  String get cardDetailSaveSubtitle =>
      'Conserver dans votre Portefeuille d\'application';

  @override
  String get cardDetailDownloadTitle => 'Télécharger la carte';

  @override
  String get cardDetailDownloadSubtitle =>
      'Enregistrer un visuel HD dans votre galerie (Pass format)';

  @override
  String get cardDetailShareTitle => 'Partager la carte';

  @override
  String get cardDetailShareSubtitle =>
      'Générer et envoyer une version propre à un proche';

  @override
  String get cardDetailFullScreen => 'Plein écran';

  @override
  String get cardDetailIdCopied => 'Identifiant copié';

  @override
  String get cardDetailQrInstructions =>
      'Présentez ce QR Code lors de votre passage en caisse';

  @override
  String cardDetailVisitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count VISITES',
      one: '$count VISITE',
    );
    return '$_temp0';
  }

  @override
  String get rewardStatusReady => 'PRÊT';

  @override
  String get rewardStatusLocked => 'VERROUILLÉ';

  @override
  String get rewardStatusUsed => 'UTILISÉ';

  @override
  String get rewardStatusExpired => 'EXPIRÉ';

  @override
  String get rewardExpirationDate => 'Date d\'expiration';

  @override
  String get rewardUsedDate => 'Utilisé le';

  @override
  String get rewardQrInstructions2 =>
      'Présentez ce QR Code pour utiliser votre récompense';

  @override
  String get historyStampEntry => '+1 tampon · Passage en caisse';

  @override
  String historyPointsEntry(int points) {
    return '+$points points · Passage en caisse';
  }

  @override
  String historyCashbackEntry(int amount) {
    return '+$amount FCFA · Passage en caisse';
  }

  @override
  String get historyVisitEntry => 'Visite comptabilisée';

  @override
  String get historySignupEntry => 'Inscription à la carte';

  @override
  String historyCashbackRedeemEntry(int amount) {
    return '-$amount FCFA · Cashback utilisé';
  }

  @override
  String get cardDetailHistoryEmpty => 'Aucune opération pour l\'instant.';

  @override
  String get exportFailedRetry => 'Échec de l\'export : réessayez.';

  @override
  String exportShareSubject(String name) {
    return 'Ma carte $name — Carte';
  }

  @override
  String exportShareText(String name) {
    return 'Découvre $name sur Carte !';
  }

  @override
  String exportDownloadReady(String id) {
    return 'Image HD de la carte $id prête — choisissez « Enregistrer l\'image ».';
  }

  @override
  String exportShareSuccess(String name) {
    return 'Visuel de la carte $name partagé.';
  }

  @override
  String exportSaveReady(String name) {
    return 'Carte « $name » prête à être enregistrée.';
  }

  @override
  String get exportFailedGeneric =>
      'Échec de l\'export : une erreur est survenue.';

  @override
  String get commonPhoneLabel => 'Numéro de téléphone';

  @override
  String get commonOptional => 'Optionnel';

  @override
  String get authLoginTitle => 'Connexion';

  @override
  String get authContinueGoogle => 'Continuer avec Google';

  @override
  String get authContinueApple => 'Continuer avec Apple';

  @override
  String get authNoAccountPrefix => 'Pas encore membre ? ';

  @override
  String get authSignUpLink => 'S\'inscrire';

  @override
  String get authSignupTitle => 'Créer un compte';

  @override
  String get authBirthDateError =>
      'Veuillez sélectionner votre date de naissance';

  @override
  String get authPhoneRequiredError =>
      'Veuillez saisir votre numéro de téléphone';

  @override
  String get authSignupButton => 'S\'inscrire';

  @override
  String get authSignupGoogle => 'S\'inscrire avec Google';

  @override
  String get authSignupApple => 'S\'inscrire avec Apple';

  @override
  String get authHasAccountPrefix => 'Déjà membre ? ';

  @override
  String get authAcceptPrefix => 'En continuant, vous acceptez les ';

  @override
  String get authTermsLink => 'CGU';

  @override
  String get authAcceptAnd => ' et la ';

  @override
  String get authPrivacyLink => 'politique de confidentialité';

  @override
  String get legalTermsTitle => 'Conditions Générales d\'Utilisation';

  @override
  String get legalPrivacyTitle => 'Politique de confidentialité';

  @override
  String get authTermsRequiredError =>
      'Veuillez accepter les CGU et la politique de confidentialité pour continuer.';

  @override
  String get otpContextLogin => 'Connexion';

  @override
  String get otpContextSignup => 'Inscription';

  @override
  String get otpContextSocial => 'Vérification';

  @override
  String get otpTitle => 'Vérification';

  @override
  String otpSentMessage(String phone) {
    return 'Un code à 6 chiffres a été envoyé au\n$phone';
  }

  @override
  String otpResendCountdown(String seconds) {
    return 'Renvoyer le code dans 00:$seconds';
  }

  @override
  String get otpResendButton => 'Renvoyer le code';

  @override
  String completeProfileWelcomeNamed(String name) {
    return 'Bienvenue, $name !\nVotre compte a été créé.';
  }

  @override
  String get completeProfileWelcomeAnon =>
      'Bienvenue !\nVotre compte a été créé.';

  @override
  String get completeProfileTitle => 'Complétez votre profil';

  @override
  String get completeProfileSubmit => 'Accéder à l\'application';

  @override
  String get completeProfileSkip => 'Passer cette étape';

  @override
  String get completeSocialProfileTitle => 'Compléter le profil';

  @override
  String get onboardingSlide1Title =>
      'Toutes vos cartes,\nun seul portefeuille';

  @override
  String get onboardingSlide1Subtitle =>
      'Rassemblez vos cartes de fidélité préférées dans une expérience unique, rapide et sans friction.';

  @override
  String get onboardingSlide2Title => 'Des privilèges\nà chaque visite';

  @override
  String get onboardingSlide2Subtitle =>
      'Cumulez tampons et points automatiquement, et débloquez des avantages exclusifs chez vos enseignes favorites.';

  @override
  String get onboardingSlide3Title => 'Partagez,\ngagnez ensemble';

  @override
  String get onboardingSlide3Subtitle =>
      'Invitez vos proches avec votre code personnel et cumulez des points de parrainage.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingStart => 'Commencer l\'expérience';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String get commonValidate => 'Valider';

  @override
  String get qrManualEntryLabel => 'Saisir le code manuellement';

  @override
  String get qrScanTitle => 'SCANNER UN QR';

  @override
  String get qrToggleFlash => 'Activer ou désactiver le flash';

  @override
  String get qrPlaceInFrame => 'Placez le QR du restaurant dans le cadre.';

  @override
  String get qrManualEntryHint =>
      'Le code unique à 8 caractères figure sous le QR affiché par l\'établissement.';

  @override
  String get qrManualEntryPlaceholder => 'Ex. 8XKQ2P9Z';

  @override
  String get qrCameraUnavailableTitle => 'Caméra indisponible';

  @override
  String get qrCameraUnavailableMessage =>
      'Autorisez l\'accès à la caméra dans les réglages, ou saisissez le code manuellement.';

  @override
  String get joinOfferDetail =>
      'Cumulez 10 tampons pour un menu entier offert.';

  @override
  String get joinUnrecognizedTitle => 'Code non reconnu';

  @override
  String joinUnrecognizedMessage(String code) {
    return '« $code » ne correspond à aucun établissement partenaire de Carte pour le moment.';
  }

  @override
  String get joinRetryScan => 'Réessayer un scan';

  @override
  String get joinBackToWallet => 'Retour au portefeuille';

  @override
  String get joinEyebrow => 'Rejoindre';

  @override
  String get joinWelcomeOfferEyebrow => 'Offre de bienvenue';

  @override
  String get joinButton => 'Rejoindre le programme';

  @override
  String get joinCardCreatedTitle => 'Carte créée !';

  @override
  String get joinCardAlreadyMemberTitle => 'Déjà membre !';

  @override
  String get joinCardAlreadyMemberMessage =>
      'Vous êtes déjà membre de ce programme de fidélité.';

  @override
  String get phonePickerTitle => 'Sélectionnez un indicatif';

  @override
  String get phonePickerSearchHint => 'Rechercher un pays ou un indicatif...';

  @override
  String phoneDigitsError(int count, String country) {
    return 'Le numéro doit contenir $count chiffres pour $country.';
  }

  @override
  String get countryPickerTitle => 'Sélectionnez un pays';

  @override
  String get countryPickerSearchHint => 'Rechercher un pays...';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authForgotPasswordLink => 'Mot de passe oublié ?';

  @override
  String get authLoadingLogin => 'Connexion en cours...';

  @override
  String get authLoadingGoogle => 'Connexion via Google...';

  @override
  String get authLoadingApple => 'Connexion via Apple...';

  @override
  String get authLoadingSignup => 'Création du compte...';

  @override
  String get authLoadingSignOut => 'Déconnexion en cours...';

  @override
  String get createPasswordTitle => 'Créez votre mot de passe';

  @override
  String get createPasswordSubtitle =>
      'Dernière étape pour sécuriser votre compte.';

  @override
  String get createPasswordConfirmLabel => 'Confirmez le mot de passe';

  @override
  String get createPasswordRuleMinLength => 'Au moins 8 caractères';

  @override
  String get createPasswordRuleUppercase => 'Une majuscule';

  @override
  String get createPasswordRuleDigit => 'Un chiffre';

  @override
  String get createPasswordButton => 'Créer mon compte';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get forgotPasswordSubtitle =>
      'Indiquez votre numéro : nous vous enverrons un code de vérification.';

  @override
  String get forgotPasswordButton => 'Envoyer le code';

  @override
  String get resetPasswordTitle => 'Nouveau mot de passe';

  @override
  String get resetPasswordSubtitle =>
      'Choisissez un nouveau mot de passe pour votre compte.';

  @override
  String get resetPasswordButton => 'Réinitialiser';

  @override
  String get resetPasswordLoading => 'Réinitialisation...';

  @override
  String get otpVerifyLoading => 'Vérification du code...';

  @override
  String get splashLoading => 'Chargement...';

  @override
  String get forgotPasswordUseEmail => 'Utiliser mon adresse e-mail';

  @override
  String get forgotPasswordUsePhone => 'Utiliser mon numéro de téléphone';

  @override
  String get forgotPasswordEmailLabel => 'Adresse e-mail';

  @override
  String get forgotPasswordEmailHint => 'vous@exemple.com';

  @override
  String get forgotPasswordSubtitleEmail =>
      'Indiquez votre adresse e-mail : nous vous enverrons un code de vérification.';

  @override
  String get forgotPasswordSending => 'Envoi du code...';

  @override
  String get errNoInternet =>
      'Vous semblez hors ligne. Vérifiez votre connexion, puis réessayez.';

  @override
  String get errServerUnreachable =>
      'Nous n\'arrivons pas à joindre nos serveurs. Réessayez dans quelques instants.';

  @override
  String get errServerError =>
      'Le service est momentanément indisponible. Réessayez dans quelques instants.';

  @override
  String get errUnexpected => 'Une erreur est survenue. Réessayez.';

  @override
  String get errTooManyAttempts =>
      'Trop de tentatives. Patientez quelques instants avant de réessayer.';

  @override
  String get errSessionExpired =>
      'Votre session a expiré. Reconnectez-vous pour continuer.';

  @override
  String get errMissingRequiredFields =>
      'Veuillez renseigner tous les champs obligatoires.';

  @override
  String get errLoginInvalidCredentials =>
      'Numéro de téléphone ou mot de passe incorrect.';

  @override
  String get errMerchantLoginInvalidCredentials =>
      'Adresse e-mail ou mot de passe incorrect.';

  @override
  String get errLoginAccountNotFound => 'Ce compte n\'existe pas encore.';

  @override
  String get errLoginAccountDeactivated =>
      'Ce compte a été désactivé. Contactez votre administrateur.';

  @override
  String get errTeamActionFailed =>
      'Impossible d\'effectuer cette action. Réessayez.';

  @override
  String get errLoginFailed =>
      'Impossible de vous connecter pour le moment. Réessayez.';

  @override
  String get errAccountUsesGoogle =>
      'Ce compte utilise une connexion Google. Connectez-vous avec Google pour accéder à votre compte.';

  @override
  String get errAccountUsesApple =>
      'Ce compte utilise une connexion Apple. Connectez-vous avec Apple pour accéder à votre compte.';

  @override
  String get errLoginSuccess => 'Vous êtes connecté.';

  @override
  String get errSocialCancelled => 'Connexion annulée.';

  @override
  String get errSocialFailedGoogle =>
      'Impossible de vous connecter avec Google. Réessayez.';

  @override
  String get errSocialFailedApple =>
      'Impossible de vous connecter avec Apple. Réessayez.';

  @override
  String get errSocialAccountNotFound =>
      'Aucun compte n\'est associé à ce profil. Créez d\'abord un compte.';

  @override
  String get errSocialEmailUsesPassword =>
      'Un compte existe déjà avec cet e-mail et utilise un mot de passe. Connectez-vous avec votre mot de passe.';

  @override
  String get errSignupPhoneTaken =>
      'Ce numéro de téléphone est déjà associé à un compte.';

  @override
  String get errSignupEmailTaken => 'Cette adresse e-mail est déjà utilisée.';

  @override
  String get errSignupFailed =>
      'Impossible de créer votre compte pour le moment. Réessayez.';

  @override
  String get errSignupSuccess => 'Votre compte a bien été créé.';

  @override
  String get errForgotAccountNotFound =>
      'Aucun compte n\'est associé à ce numéro de téléphone.';

  @override
  String get errMerchantForgotAccountNotFound =>
      'Aucun compte n\'est associé à cette adresse e-mail.';

  @override
  String get errForgotCodeSent =>
      'Un code de réinitialisation vient d\'être envoyé.';

  @override
  String get errForgotSendFailed =>
      'Impossible d\'envoyer le code. Réessayez dans quelques instants.';

  @override
  String get errOtpInvalid =>
      'Ce code est incorrect. Vérifiez-le et réessayez.';

  @override
  String get errOtpExpired =>
      'Ce code a expiré. Demandez-en un nouveau pour continuer.';

  @override
  String get errResetSessionExpired =>
      'Votre demande a expiré. Recommencez la réinitialisation.';

  @override
  String get errResetFailed =>
      'Impossible de réinitialiser votre mot de passe. Réessayez.';

  @override
  String get errResetSuccess => 'Votre mot de passe a bien été modifié.';

  @override
  String get errProfileSaveFailed =>
      'Impossible d\'enregistrer les modifications. Réessayez.';

  @override
  String get errProfileSaveSuccess =>
      'Les informations ont bien été enregistrées.';

  @override
  String get errProfileCompleteFailed =>
      'Impossible d\'enregistrer votre profil. Réessayez.';

  @override
  String get errAvatarUpdateFailed =>
      'Impossible de mettre à jour la photo de profil. Réessayez.';

  @override
  String get errAvatarUpdateSuccess => 'Photo de profil mise à jour.';

  @override
  String get errAvatarRemoveSuccess => 'Photo de profil supprimée.';

  @override
  String get errAvatarInvalid =>
      'Cette image ne peut pas être utilisée. Essayez-en une autre.';

  @override
  String get errPasswordCurrentIncorrect =>
      'Le mot de passe actuel est incorrect.';

  @override
  String get errPasswordChangeSuccess =>
      'Votre mot de passe a bien été modifié.';

  @override
  String get errPasswordChangeFailed =>
      'Impossible de modifier votre mot de passe. Réessayez.';

  @override
  String get errFieldRequired => 'Veuillez renseigner ce champ.';

  @override
  String get errPhoneInvalid => 'Le numéro de téléphone n\'est pas valide.';

  @override
  String get errPhoneTaken =>
      'Ce numéro de téléphone est déjà associé à un compte.';

  @override
  String get errPhoneRisky =>
      'Ce numéro ne peut pas être utilisé. Essayez-en un autre.';

  @override
  String get errEmailInvalid => 'L\'adresse e-mail n\'est pas valide.';

  @override
  String get errEmailTaken => 'Cette adresse e-mail est déjà utilisée.';

  @override
  String get errPasswordTooShort =>
      'Le mot de passe doit contenir au moins 8 caractères.';

  @override
  String get errPasswordMismatch =>
      'Les deux mots de passe ne correspondent pas.';

  @override
  String get errPasswordNeedsUppercase =>
      'Le mot de passe doit contenir au moins une majuscule.';

  @override
  String get errPasswordNeedsDigit =>
      'Le mot de passe doit contenir au moins un chiffre.';

  @override
  String get errPasswordMustDiffer =>
      'Le nouveau mot de passe doit être différent de l\'actuel.';

  @override
  String get errPasswordIncorrect => 'Mot de passe incorrect.';

  @override
  String get errNameInvalid => 'Ce nom n\'est pas valide.';

  @override
  String get errBirthdateInvalid =>
      'Cette date de naissance n\'est pas valide.';

  @override
  String get errBirthdateRequired =>
      'Veuillez indiquer votre date de naissance.';

  @override
  String get errReferralCodeInvalid => 'Ce code de parrainage n\'existe pas.';

  @override
  String get errOtpFieldInvalid => 'Ce code n\'est pas valide.';

  @override
  String get errFieldInvalid => 'Cette information n\'est pas valide.';

  @override
  String get changePasswordTitle => 'Modifier le mot de passe';

  @override
  String get changePasswordVerifySubtitle =>
      'Confirmez votre mot de passe actuel pour continuer.';

  @override
  String get changePasswordCurrentLabel => 'Mot de passe actuel';

  @override
  String get changePasswordVerifying => 'Vérification...';

  @override
  String get changePasswordContinue => 'Continuer';

  @override
  String get changePasswordNewTitle => 'Nouveau mot de passe';

  @override
  String get changePasswordNewSubtitle =>
      'Choisissez un mot de passe différent de l\'actuel.';

  @override
  String get changePasswordNewLabel => 'Nouveau mot de passe';

  @override
  String get changePasswordSaving => 'Modification...';

  @override
  String get changePasswordSubmit => 'Enregistrer';

  @override
  String get editProfileCity => 'Ville';

  @override
  String get editProfileCityHint => 'Lomé';

  @override
  String get editProfileCountry => 'Pays';

  @override
  String get editProfileCountryHint => 'Togo';

  @override
  String get editProfileSaving => 'Enregistrement...';

  @override
  String get editProfilePhotoChange => 'Changer la photo';

  @override
  String get editProfilePhotoRemove => 'Supprimer la photo';

  @override
  String get editProfileSecurity => 'Sécurité';

  @override
  String get editProfileNotSet => 'Non renseigné';

  @override
  String get editProfilePhotoLabel => 'Photo de profil';

  @override
  String get editProfileAuthMethod => 'Méthode de connexion';

  @override
  String editProfileConnectedVia(String provider) {
    return 'Connecté via $provider';
  }

  @override
  String get merchantNavClients => 'Clients';

  @override
  String get merchantNavStats => 'Stats';

  @override
  String get merchantNavValidate => 'Valider';

  @override
  String get merchantNavSms => 'SMS';

  @override
  String get merchantNavSettings => 'Réglages';

  @override
  String get merchantMoreBusinessProfile => 'Profil du commerce';

  @override
  String get merchantMoreCompleteProfile => 'Compléter mon profil';

  @override
  String get merchantMoreLogoBusiness => 'Logo du commerce';

  @override
  String get merchantMoreSocials => 'Réseaux sociaux';

  @override
  String get merchantMoreGoogleReviewLink => 'Lien d\'avis Google';

  @override
  String get merchantMoreSectionAccount => 'COMPTE';

  @override
  String get merchantMoreHours => 'Horaires d\'ouverture';

  @override
  String get merchantMoreToComplete => 'À compléter';

  @override
  String get merchantMoreSubscription => 'Abonnement';

  @override
  String get merchantMoreProTag => 'Pro';

  @override
  String get merchantMoreLanguageTheme => 'Langue & thème';

  @override
  String get merchantMoreTeam => 'Équipe';

  @override
  String get merchantMoreSectionLoyaltyCard => 'MA CARTE DE FIDÉLITÉ';

  @override
  String get merchantMoreCustomizeCard => 'Personnaliser la carte';

  @override
  String get merchantMoreGoalReward => 'Objectif & récompense';

  @override
  String get merchantMoreLoyaltyProgram => 'Programme de fidélité';

  @override
  String get merchantMoreMyQrCode => 'Mon QR code';

  @override
  String get merchantMoreMyShowcase => 'Ma vitrine';

  @override
  String get merchantMoreSectionSupport => 'ASSISTANCE';

  @override
  String get merchantMoreLegalPrivacy => 'Confidentialité';

  @override
  String get merchantMoreLegalTerms => 'Conditions d\'utilisation';

  @override
  String get merchantMoreWhatsappSupport => 'Support WhatsApp';

  @override
  String get merchantSignOutConfirmTitle => 'Se déconnecter ?';

  @override
  String get merchantSignOutConfirmMessage =>
      'Vous devrez vous reconnecter pour accéder à votre espace commerçant.';

  @override
  String get merchantSignOutConfirm => 'Se déconnecter';

  @override
  String get changePasswordConfirmLabel => 'Confirmer le nouveau mot de passe';

  @override
  String get merchantAccountTitle => 'Compte & Profil';

  @override
  String get merchantAccountProfile => 'Profil';

  @override
  String get merchantSubscriptionCategoryTitle => 'Abonnement & Équipe';

  @override
  String get merchantSubscriptionMyPlan => 'Mon Abonnement';

  @override
  String get merchantSubscriptionTeamMembers => 'Membres de l\'équipe';

  @override
  String get merchantNotifUpdateError =>
      'Impossible de mettre à jour cette préférence. Réessayez.';

  @override
  String get merchantNotifNewClientTitle => 'Nouveau client';

  @override
  String get merchantNotifNewClientSubtitle => 'Notif. à chaque inscription';

  @override
  String get merchantNotifRewardTitle => 'Récompense gagnée';

  @override
  String get merchantNotifRewardSubtitle => 'Quand un palier est atteint';

  @override
  String get merchantNotifLowSmsTitle => 'Quota SMS faible';

  @override
  String get merchantNotifLowSmsSubtitle => 'Sous 20 SMS restants';

  @override
  String get merchantNotifWeeklyReportTitle => 'Rapport hebdomadaire';

  @override
  String get merchantNotifWeeklyReportSubtitle => 'Tous les lundis matin';

  @override
  String get merchantNotifPromotionsTitle => 'Promotions Miva-Fid';

  @override
  String get merchantNotifPromotionsSubtitle => 'Offres et nouveautés';

  @override
  String get merchantTeamInviteTitle => 'Inviter un membre';

  @override
  String get merchantTeamNameLabel => 'Nom';

  @override
  String get merchantTeamPhoneOptionalLabel => 'Téléphone (optionnel)';

  @override
  String get merchantTeamPasswordLabel => 'Mot de passe';

  @override
  String get merchantTeamRoleOperator => 'Opérateur';

  @override
  String get merchantTeamRoleAdmin => 'Administrateur';

  @override
  String get merchantTeamInviteButton => 'Inviter';

  @override
  String get merchantTeamInviteError => 'Impossible d\'inviter ce membre.';

  @override
  String get merchantTeamEmptyState =>
      'Aucun membre d\'équipe. Invitez votre premier opérateur.';

  @override
  String get merchantTeamToggleStatusError =>
      'Impossible de modifier le statut de ce membre.';

  @override
  String get merchantTierSilver => 'Argent';

  @override
  String get merchantTierGold => 'Or';

  @override
  String get merchantTierPlatinum => 'Platine';

  @override
  String get merchantDashboardTitle => 'Statistiques';

  @override
  String get merchantDashboardSubtitle =>
      'Aperçu de votre activité — juin 2026';

  @override
  String get merchantDashboardStampsLabel => 'Tampons';

  @override
  String get merchantDashboardThisMonthLabel => 'ce mois';

  @override
  String get merchantDashboardRewardsLabel => 'Récomp.';

  @override
  String get merchantDashboardUsedLabel => 'utilisées';

  @override
  String get merchantDashboardMonthActivityTitle => 'Activité du mois';

  @override
  String get merchantDashboardValidationsPerWeekSubtitle =>
      'Validations par semaine';

  @override
  String merchantDashboardWeekLabel(String number) {
    return 'Sem $number';
  }

  @override
  String get merchantDashboardVipDistributionTitle => 'Répartition VIP';

  @override
  String get merchantDashboardClientsByTierSubtitle => 'Vos clients par niveau';

  @override
  String get merchantClientsTitle => 'Mes clients';

  @override
  String merchantClientsActiveCount(String count) {
    return '$count clients actifs';
  }

  @override
  String get merchantClientsAddSoonToast =>
      'Ajout manuel d\'un client bientôt disponible.';

  @override
  String get merchantClientsExportToast =>
      'Exportation de la liste clients au format CSV lancée !';

  @override
  String get merchantClientsExportButton => 'Exporter la liste';

  @override
  String get merchantClientsSearchHint => 'Rechercher un client...';

  @override
  String get merchantClientsFilterAll => 'Tous';

  @override
  String get merchantClientsFilterInactive30d => '+30j';

  @override
  String merchantClientsPaginationInfo(String from, String to, String total) {
    return '$from-$to sur $total';
  }

  @override
  String get merchantClientsPrevious => '< Préc.';

  @override
  String get merchantClientsNext => 'Suiv. >';

  @override
  String get merchantClientDetailRemoveTitle => 'Retirer du programme ?';

  @override
  String merchantClientDetailRemoveMessage(String name) {
    return 'Êtes-vous sûr de vouloir retirer $name de votre programme de fidélité ? Ses tampons seront réinitialisés.';
  }

  @override
  String get merchantClientDetailRemoveConfirm => 'Retirer';

  @override
  String get merchantClientDetailRemoveToast => 'Client retiré du programme.';

  @override
  String get merchantClientDetailSubtitle => 'Fiche client';

  @override
  String get merchantClientDetailProgress => 'Progression';

  @override
  String get merchantClientDetailSendSms => 'Envoyer un SMS';

  @override
  String get merchantClientDetailCall => 'Appeler';

  @override
  String get merchantClientDetailRewardsLabel => 'Récompenses';

  @override
  String get merchantClientDetailLastLabel => 'Dernière';

  @override
  String get merchantClientDetailHistoryTitle => 'Historique';

  @override
  String get merchantClientDetailHistoryStampValidated => 'Tampon validé';

  @override
  String get merchantClientDetailHistoryRewardUsed => 'Récompense utilisée';

  @override
  String get merchantClientDetailHistoryEnrolled => 'Inscription au programme';

  @override
  String get merchantClientDetailRemoveButton => 'Retirer du programme';

  @override
  String get merchantValidateQrInvalid => 'QR code invalide ou illisible.';

  @override
  String get merchantValidateNetworkError =>
      'Connexion impossible. Vérifiez votre réseau.';

  @override
  String get merchantValidateNoCardFound =>
      'Aucune carte de fidélité trouvée pour ce commerce.';

  @override
  String get merchantValidateNoRewardFound =>
      'Aucune récompense de votre commerce ne correspond à ce code.';

  @override
  String get merchantValidateRewardSuccess =>
      'Récompense validée avec succès !';

  @override
  String get merchantValidateRewardError => 'Erreur lors de la validation.';

  @override
  String get merchantValidateFailedRetry =>
      'Échec de la validation. Réessayez.';

  @override
  String get merchantValidateDefaultClientName => 'Client';

  @override
  String get merchantValidateTitle => 'Valider une visite';

  @override
  String get merchantValidateSubtitle => 'Scannez ou saisissez l\'identifiant';

  @override
  String get merchantValidateTabScanner => 'Scanner';

  @override
  String get merchantValidateTabPhone => 'Identifiant';

  @override
  String get merchantValidateScanInstruction =>
      'Pointez la caméra vers le QR du client';

  @override
  String get merchantValidateDisableCamera => 'Désactiver la caméra';

  @override
  String get merchantValidateEnableCamera => 'Activer la caméra';

  @override
  String get merchantValidateManualSearchTitle => 'Recherche par identifiant';

  @override
  String get merchantValidateManualSearchSubtitle =>
      'Entrez l\'identifiant du client pour valider sa visite.';

  @override
  String get merchantValidateManualSearchHint => 'Identifiant du client';

  @override
  String get merchantValidateSearchButton => 'Rechercher le client';

  @override
  String get merchantSmsCampaignSubtitle => 'Campagnes & messages';

  @override
  String get merchantSmsCampaignSentLabel => 'Envoyées';

  @override
  String get merchantSmsCampaignOpenRateLabel => 'Ouverture';

  @override
  String get merchantSmsCampaignReachedLabel => 'Atteints';

  @override
  String merchantSmsCampaignCount(String count) {
    return '$count campagnes';
  }

  @override
  String get merchantSmsCampaignDetailSentBadge => 'Envoyée';

  @override
  String get merchantSmsCampaignDetailRecipients => 'Destinataires';

  @override
  String get merchantSmsCampaignDetailSent => 'Envoyés';

  @override
  String get merchantSmsCampaignDetailOpened => 'Ouverts';

  @override
  String get merchantSmsCampaignDetailOpenRate => 'Taux d\'ouverture';

  @override
  String get merchantSmsCampaignDetailMessageTitle => 'Message envoyé';

  @override
  String get merchantSmsCampaignDetailDuplicateToast =>
      'Campagne dupliquée dans un nouveau brouillon !';

  @override
  String get merchantSmsCampaignDetailDuplicateButton =>
      'Dupliquer cette campagne';

  @override
  String get merchantSmsConversationSentToast => 'SMS envoyé avec succès !';

  @override
  String get merchantSmsConversationLabel => 'Conversation SMS';

  @override
  String get merchantSmsConversationInputHint => 'Écrire un message...';

  @override
  String get merchantProfileLogoSuccess => 'Logo mis à jour avec succès';

  @override
  String get merchantProfileLogoError => 'Impossible de mettre à jour le logo.';

  @override
  String get merchantProfileSaveSuccess => 'Modifications enregistrées !';

  @override
  String get merchantProfileLogoHint => 'PNG ou JPG, carré, max 2 Mo.';

  @override
  String get merchantProfileLoadingEllipsis => 'Chargement...';

  @override
  String get merchantProfileChangeLink => 'Changer';

  @override
  String get merchantProfileSectionInfo => 'INFORMATIONS';

  @override
  String get merchantProfileBusinessNameLabel => 'NOM DU COMMERCE';

  @override
  String get merchantProfileCategoryLabel => 'CATÉGORIE';

  @override
  String get merchantProfileDescriptionLabel => 'DESCRIPTION';

  @override
  String merchantProfileCharCount(String count) {
    return '$count/200 caractères';
  }

  @override
  String get merchantProfileSectionContact => 'CONTACT';

  @override
  String get merchantProfileEmailLabel => 'EMAIL';

  @override
  String get merchantProfilePhoneLabel => 'TÉLÉPHONE';

  @override
  String get merchantProfileWhatsappLabel => 'WHATSAPP';

  @override
  String get merchantProfileSectionAddress => 'ADRESSE';

  @override
  String get merchantProfileCityLabel => 'VILLE';

  @override
  String get merchantProfileAddressLabel => 'ADRESSE / QUARTIER';

  @override
  String get merchantProfileSaveButton => 'Enregistrer les modifications';

  @override
  String get merchantVitrineLogoUploadError =>
      'Impossible d\'envoyer le logo. Réessayez.';

  @override
  String get merchantVitrineLogoRemoveError =>
      'Impossible de supprimer le logo. Réessayez.';

  @override
  String get merchantVitrineSaveSuccess => 'Vitrine mise à jour avec succès';

  @override
  String merchantVitrineSaveError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get merchantVitrinePreviewTitle => 'Aperçu public';

  @override
  String get merchantVitrineTitle => 'Ma Vitrine';

  @override
  String get merchantVitrineSubtitle => 'Page publique de votre commerce';

  @override
  String get merchantVitrinePreviewButton => 'Aperçu';

  @override
  String get merchantVitrineCoverPhotoSection => 'Photo de couverture';

  @override
  String get merchantVitrineInfoSection => 'Informations';

  @override
  String get merchantVitrineDescriptionHint => 'Description...';

  @override
  String get merchantVitrineContactAddressSection => 'Contact & adresse';

  @override
  String get merchantVitrineHoursSection => 'Horaires';

  @override
  String get merchantVitrineDayMonday => 'Lundi';

  @override
  String get merchantVitrineDayTuesday => 'Mardi';

  @override
  String get merchantVitrineDayWednesday => 'Mercredi';

  @override
  String get merchantVitrineDayThursday => 'Jeudi';

  @override
  String get merchantVitrineDayFriday => 'Vendredi';

  @override
  String get merchantVitrineDaySaturday => 'Samedi';

  @override
  String get merchantVitrineDaySunday => 'Dimanche';

  @override
  String get merchantVitrineClosedLabel => 'Fermé';

  @override
  String get merchantVitrinePublishButton => 'Publier les modifications';

  @override
  String get merchantVitrineAddPhotoLabel => 'Ajouter une photo';

  @override
  String get merchantSubscriptionPlanStarterName => 'Démarrage';

  @override
  String get merchantSubscriptionPlanBusinessName => 'Business';

  @override
  String get merchantSubscriptionNextInvoiceLabel => 'Prochaine facture';

  @override
  String get merchantSubscriptionCurrentBadge => 'ACTUEL';

  @override
  String get merchantSubscriptionChooseButton => 'Choisir';

  @override
  String merchantSubscriptionPlanChangedSuccess(String plan) {
    return 'Abonnement modifié : plan $plan sélectionné';
  }

  @override
  String merchantSubscriptionPlanChangeError(String error) {
    return 'Erreur lors du changement de plan : $error';
  }

  @override
  String get merchantQrCodeLoadError => 'Erreur';

  @override
  String get merchantQrCodeSubtitle =>
      'Affichez-le pour que les clients scannent';

  @override
  String get merchantQrCodeScanToEarnLabel => 'Scannez pour gagner un tampon';

  @override
  String get merchantQrCodePngSavedToast =>
      'Image enregistrée dans la galerie !';

  @override
  String get merchantQrCodeShareButton => 'Partager';

  @override
  String get merchantQrCodeUniqueCodeSection => 'CODE UNIQUE';

  @override
  String get merchantQrCodeCodeCopiedToast =>
      'Code copié dans le presse-papiers !';

  @override
  String get merchantQrCodeThisWeekLabel => 'Cette semaine';

  @override
  String get merchantQrCodeThisMonthLabel => 'Ce mois';

  @override
  String get merchantQrCodeNewLabel => 'Nouveaux';

  @override
  String get merchantQrCodeTipLabel => 'Astuce';

  @override
  String get merchantQrCodeTipMessage =>
      'Placez le QR à la caisse ou sur les tables pour maximiser les scans.';

  @override
  String get merchantQrCodePdfScanMessage =>
      'Scannez pour cumuler vos points !';

  @override
  String get merchantQrCodePdfPoweredBy => 'Powered by Miva-Fid';

  @override
  String merchantQrCodeWhatsappShareMessage(String name) {
    return 'Rejoignez mon programme de fidélité Miva-Fid chez $name !';
  }

  @override
  String get merchantProgrammeTitle => 'Fidélisation';

  @override
  String get merchantProgrammeCardPreviewLabel => 'Aperçu de la carte';

  @override
  String get merchantProgrammeConfigTitle => 'Configuration';

  @override
  String get merchantProgrammeConfigSubtitle =>
      'Gérez les détails de votre programme de fidélité';

  @override
  String get merchantProgrammeAppearanceTitle => 'Apparence de la carte';

  @override
  String get merchantProgrammeAppearanceSubtitle =>
      'Personnalisez les couleurs et le style';

  @override
  String get merchantProgrammeTiersTitle => 'Paliers de fidélité';

  @override
  String get merchantProgrammeTiersSubtitle =>
      'Objectifs, niveaux et récompenses de votre programme';

  @override
  String get merchantProgrammeRulesTitle => 'Règles d\'accumulation';

  @override
  String get merchantProgrammeRulesSubtitle =>
      'Configuration du ratio (ex: 1 point = 500 FCFA)';

  @override
  String get merchantProgrammeLoopTitle => 'Programme en boucle';

  @override
  String get merchantProgrammeLoopEnabledSubtitle =>
      'Dernier palier atteint : nouveau cycle automatique.';

  @override
  String get merchantProgrammeLoopDisabledSubtitle =>
      'Dernier palier atteint : carte terminée définitivement.';

  @override
  String get merchantProgrammeTiersLoadingTitle => 'Paliers';

  @override
  String get merchantProgrammeGoalUnitPoints => 'points / FCFA';

  @override
  String get merchantProgrammeGoalUnitCashback => 'FCFA de cashback cumulés';

  @override
  String get merchantProgrammeGoalUnitStamps => 'tampons';

  @override
  String get merchantProgrammeTiersSaveSuccess =>
      'Paliers mis à jour avec succès';

  @override
  String merchantProgrammeTiersSaveError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get merchantProgrammeAddTierButton => 'Ajouter un palier';

  @override
  String merchantProgrammeRulesNotApplicable(String mode) {
    return 'Votre programme est configuré en mode \"$mode\".\n\nAucune règle de conversion FCFA -> Points n\'est requise.';
  }

  @override
  String get merchantProgrammeRulesSaveSuccess =>
      'Règle de conversion mise à jour avec succès';

  @override
  String merchantProgrammeRulesSaveError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get merchantProgrammeRulesConversionLabel =>
      'Conversion FCFA -> Points';

  @override
  String get merchantProgrammeRulesConversionSubtitle =>
      'Définissez combien le client doit dépenser pour gagner 1 point.';

  @override
  String get merchantProgrammeRulesInputLabel =>
      '1 point tous les combien de FCFA ? *';

  @override
  String get merchantProgrammeRulesInputHint => 'Ex: 500';

  @override
  String get merchantProgrammeRulesValidatorError =>
      'Veuillez entrer un nombre supérieur à 0';

  @override
  String get merchantProgrammeDesignLogoRemovedToast => 'Logo supprimé';

  @override
  String get merchantProgrammeDesignSaveSuccess =>
      'Design mis à jour avec succès';

  @override
  String merchantProgrammeDesignSaveError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get merchantProgrammeDesignLoadingTitle => 'Apparence';

  @override
  String get merchantProgrammeDesignChooseIconTitle => 'Choisir une icône';

  @override
  String get merchantProgrammeDesignChooseEmojiTitle => 'Choisir un emoji';

  @override
  String get merchantProgrammeDesignLogoHint =>
      'Ce logo apparaîtra sur votre carte de fidélité et sur vos profils.';

  @override
  String get merchantProgrammeDesignLogoPresent => 'Logo présent';

  @override
  String get merchantProgrammeDesignNoLogo => 'Aucun logo';

  @override
  String get merchantProgrammeDesignSquareFormatHint =>
      'Format carré recommandé';

  @override
  String get merchantProgrammeDesignAddButton => 'Ajouter';

  @override
  String get merchantProgrammeDesignRemoveTooltip => 'Supprimer';

  @override
  String get merchantProgrammeDesignPrimaryColorLabel => 'Couleur principale';

  @override
  String get merchantProgrammeDesignColorHint =>
      'Choisissez la couleur dominante de votre carte de fidélité.';

  @override
  String get merchantProgrammeDesignPatternLabel => 'Motif de fond';

  @override
  String get merchantProgrammeDesignPatternNone => 'Aucun';

  @override
  String get merchantProgrammeDesignPatternLines => 'Traits';

  @override
  String get merchantProgrammeDesignPatternWaves => 'Vagues';

  @override
  String get merchantProgrammeDesignPatternDots => 'Points';

  @override
  String get merchantProgrammeDesignStampStyleLabel => 'Style des tampons';

  @override
  String get merchantProgrammeDesignStampTypeIcon => 'Icône';

  @override
  String get merchantProgrammeDesignStampTypeEmoji => 'Emoji';

  @override
  String get merchantProgrammeDesignIconSelectedLabel => 'Icône sélectionnée';

  @override
  String get merchantProgrammeDesignEmojiSelectedLabel => 'Emoji sélectionné';

  @override
  String get merchantProgrammeDesignSaveButton => 'Enregistrer le design';

  @override
  String get merchantPlanUpgradeTitle => 'Passez à Pro';

  @override
  String get merchantPlanUpgradeSubtitle =>
      'Campagnes SMS illimitées, analytics avancés et support prioritaire.';

  @override
  String get merchantPlanUpgradeButton => 'Découvrir Pro';

  @override
  String get merchantPlanUpgradeToast => 'Offre Pro bientôt disponible';

  @override
  String get merchantValidateRewardUnlockedTitle => 'Récompense débloquée !';

  @override
  String merchantValidateCashbackCreditedTitle(String amount, String name) {
    return '$amount FCFA crédités à $name !';
  }

  @override
  String merchantValidateStampGrantedTitle(String name) {
    return 'Tampon accordé à $name !';
  }

  @override
  String merchantValidatePointsGrantedTitle(String points, String name) {
    return '$points point(s) accordé(s) à $name !';
  }

  @override
  String get merchantValidateRewardUnlockedSubtitle =>
      'Le client peut réclamer sa récompense dès maintenant.';

  @override
  String get merchantValidateCashbackCreditedSubtitle =>
      'Cashback crédité sur le solde du client.';

  @override
  String merchantValidateStampProgressSubtitle(String current, String goal) {
    return '$current sur $goal tampons';
  }

  @override
  String merchantValidatePointsProgressSubtitle(String current, String goal) {
    return '$current sur $goal points';
  }

  @override
  String get merchantValidateNextStepButton => 'Étape suivante';

  @override
  String get merchantValidateRewardStatusUsed => 'Déjà utilisée';

  @override
  String get merchantValidateRewardStatusCanceled => 'Annulée';

  @override
  String get merchantValidateRewardStatusExpired => 'Expirée';

  @override
  String get merchantValidateRewardStatusAvailable => 'Disponible';

  @override
  String get merchantValidateRewardSheetTitle => 'Récompense';

  @override
  String merchantValidateRewardClientLabel(String name) {
    return 'Client : $name';
  }

  @override
  String get merchantValidateRewardConfirmButton => 'Valider l\'utilisation';

  @override
  String get merchantValidateRewardCancelButton => 'Annuler cette récompense';

  @override
  String get merchantValidateCardInactive => 'Carte inactive';

  @override
  String get merchantValidateConfirmAndCredit => 'Confirmer et créditer';

  @override
  String get merchantValidateCreditCashback => 'Créditer le cashback';

  @override
  String get merchantValidateValidateStamp => 'Valider le tampon';

  @override
  String get merchantValidateCreditCashbackButton => 'Créditer du cashback';

  @override
  String get merchantValidateRedeemCashbackButton => 'Utiliser du cashback';

  @override
  String get merchantValidateNoCashbackBalance =>
      'Aucun solde cashback à utiliser pour ce client.';

  @override
  String merchantValidateBelowCashbackThreshold(
      String threshold, String balance) {
    return 'Seuil non atteint : $threshold requis pour utiliser le cashback (solde actuel : $balance).';
  }

  @override
  String get merchantValidatePurchaseAmountLabel => 'Montant de l\'achat';

  @override
  String merchantValidateCashbackCreditedHelper(String percent) {
    return '$percent% crédités en cashback';
  }

  @override
  String get merchantValidateEnterAmountCashbackHint =>
      'Saisissez le montant pour voir le cashback crédité.';

  @override
  String merchantValidateCashbackCreditedResult(String amount) {
    return '= $amount de cashback crédités';
  }

  @override
  String get merchantValidateCashbackToUseLabel => 'Cashback à utiliser';

  @override
  String merchantValidateAvailableBalance(String amount) {
    return 'Solde disponible : $amount';
  }

  @override
  String merchantValidateAmountToPay(String amount) {
    return '= $amount à payer';
  }

  @override
  String get merchantValidateExceedsBalance => 'Dépasse le solde disponible.';

  @override
  String get merchantValidateExceedsPurchase =>
      'Ne peut pas dépasser le montant de l\'achat.';

  @override
  String get merchantValidateViewSummaryButton => 'Voir le résumé';

  @override
  String get merchantValidateSummaryPurchase => 'Achat';

  @override
  String get merchantValidateSummaryCashbackUsed => 'Cashback utilisé';

  @override
  String get merchantValidateSummaryToPay => 'À payer';

  @override
  String get merchantValidateSummaryCashbackGenerated => 'Cashback généré';

  @override
  String get merchantValidateSummaryNewBalance => 'Nouveau solde';

  @override
  String get merchantValidateConfirmUsageButton => 'Confirmer l\'utilisation';

  @override
  String get merchantValidateInactiveBadge => 'Inactive';

  @override
  String merchantValidatePointsRatioHelper(String amount) {
    return '1 point tous les $amount FCFA d\'achat';
  }

  @override
  String get merchantValidateEnterAmountPointsHint =>
      'Saisissez le montant pour voir les points crédités.';

  @override
  String merchantValidatePointsCreditedResult(String points) {
    return '= $points point(s) crédité(s)';
  }

  @override
  String get merchantValidateCashbackLabel => 'CASHBACK';

  @override
  String get merchantValidateAvailableBalanceLabel => 'solde disponible';

  @override
  String get merchantValidatePurchasesLabel => 'ACHATS';

  @override
  String get merchantValidatePointsLabel => 'POINTS';

  @override
  String merchantValidateSpendGoalLabel(String goal) {
    return 'sur $goal pts (achats)';
  }

  @override
  String merchantValidatePointsGoalLabel(String goal) {
    return 'sur $goal points';
  }

  @override
  String get merchantTierEditorTitle => 'Vos paliers';

  @override
  String merchantTierEditorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paliers',
      one: '$count palier',
    );
    return '$_temp0';
  }

  @override
  String get merchantTierEditorMultiTierHint =>
      'Chaque palier attribue un niveau nommé par vous et débloque sa propre récompense, sans jamais redescendre une fois atteint.';

  @override
  String get merchantTierEditorEmptyState =>
      'Aucun palier configuré — le cashback fonctionne normalement sans palier.';

  @override
  String merchantTierEditorDefaultTierName(String number) {
    return 'Palier $number';
  }

  @override
  String get merchantTierEditorConfigurePrompt => 'Configurer ce palier';

  @override
  String get merchantTierEditorDeleteTooltip => 'Supprimer ce palier';

  @override
  String merchantTierEditorGoalLabel(String unit) {
    return 'Objectif ($unit) *';
  }

  @override
  String get merchantTierEditorGoalRequired => 'L\'objectif est obligatoire';

  @override
  String merchantTierEditorMustExceedPrevious(String value) {
    return 'Doit être supérieur au palier précédent ($value)';
  }

  @override
  String get merchantTierEditorLevelNameLabel => 'Nom du niveau *';

  @override
  String get merchantTierEditorLevelNameHint => 'Ex : Découverte, Habitué, VIP';

  @override
  String get merchantTierEditorLevelNameRequired =>
      'Le nom du niveau est obligatoire';

  @override
  String get merchantTierEditorRewardLabel => 'Récompense offerte *';

  @override
  String get merchantTierEditorRewardHint =>
      'Ex : 1 café offert, 10% de réduction';

  @override
  String get merchantTierEditorRewardRequired =>
      'La description de la récompense est obligatoire';

  @override
  String get merchantTierEditorSurpriseRewardLabel => 'Récompense surprise 🎁';

  @override
  String get merchantTierEditorSurpriseRewardHint =>
      'Cacher ce palier au client jusqu\'à ce qu\'il le débloque.';

  @override
  String get merchantTierEditorValidityLabel => 'Validité (jours, optionnel)';

  @override
  String get merchantTierEditorValidityHint =>
      'Ex: 30 — vide = pas d\'expiration';

  @override
  String get merchantTierEditorValidityError =>
      'Veuillez entrer un nombre de jours supérieur à 0';
}
