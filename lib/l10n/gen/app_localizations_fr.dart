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
      'Le code figure sous le QR affiché par l\'établissement.';

  @override
  String get qrManualEntryPlaceholder => 'Ex. JARDIN-2024';

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
  String get phonePickerTitle => 'Sélectionnez un indicatif';

  @override
  String get phonePickerSearchHint => 'Rechercher un pays ou un indicatif...';

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
  String get errLoginAccountNotFound => 'Ce compte n\'existe pas encore.';

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
}
