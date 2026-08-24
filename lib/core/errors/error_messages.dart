import '../../l10n/gen/app_localizations.dart';

/// Catalogue unique des messages présentés à l'utilisateur.
///
/// Toute formulation visible pour les parcours liés au compte vit ici : c'est
/// ce qui garantit l'harmonisation. Aucun écran ne doit écrire un message en
/// dur ; il pioche dans ce catalogue.
///
/// Règles de rédaction respectées ici :
///   * pas de terme technique, de code d'erreur ni de nom de champ API ;
///   * on dit ce qui s'est passé, et quoi faire quand l'utilisateur peut agir ;
///   * vouvoiement, phrase complète, ponctuation finale.
///
/// **Localisation.** Les textes vivent dans `app_fr.arb` / `app_en.arb` sous
/// le préfixe `err*`. L'accès reste statique — ces messages sont produits
/// depuis des providers et des services qui n'ont pas de `BuildContext` — donc
/// la table est injectée une fois par [bind], appelé depuis `app.dart` à
/// chaque changement de langue. C'est le même procédé que
/// `AppColors.setBrightness` pour le mode sombre.
///
/// Tant que [bind] n'a pas été appelé, les constantes françaises servent de
/// repli : un message dans la mauvaise langue reste préférable à un texte
/// vide ou à une exception au moment d'afficher une erreur.
class ErrorMessages {
  ErrorMessages._();

  static AppLocalizations? _t;

  /// Associe la table de traductions de la langue courante.
  static void bind(AppLocalizations localizations) => _t = localizations;

  // ── Erreurs générales (Toast) ──
  static String get noInternet => _t?.errNoInternet ?? 'Vous semblez hors ligne. Vérifiez votre connexion, puis réessayez.';

  static String get serverUnreachable => _t?.errServerUnreachable ?? 'Nous n\'arrivons pas à joindre nos serveurs. Réessayez dans quelques instants.';

  static String get serverError => _t?.errServerError ?? 'Le service est momentanément indisponible. Réessayez dans quelques instants.';

  static String get unexpected => _t?.errUnexpected ?? 'Une erreur est survenue. Réessayez.';

  static String get tooManyAttempts => _t?.errTooManyAttempts ?? 'Trop de tentatives. Patientez quelques instants avant de réessayer.';

  static String get sessionExpired => _t?.errSessionExpired ?? 'Votre session a expiré. Reconnectez-vous pour continuer.';

  static String get missingRequiredFields => _t?.errMissingRequiredFields ?? 'Veuillez renseigner tous les champs obligatoires.';

  // ── Connexion ──
  static String get loginInvalidCredentials => _t?.errLoginInvalidCredentials ?? 'Numéro de téléphone ou mot de passe incorrect.';

  static String get loginAccountNotFound => _t?.errLoginAccountNotFound ?? 'Ce compte n\'existe pas encore.';

  static String get loginAccountDeactivated => _t?.errLoginAccountDeactivated ?? 'Ce compte a été désactivé. Contactez votre administrateur.';

  static String get loginFailed => _t?.errLoginFailed ?? 'Impossible de vous connecter pour le moment. Réessayez.';

  static String get accountUsesGoogle => _t?.errAccountUsesGoogle ?? 'Ce compte utilise une connexion Google. Connectez-vous avec Google pour accéder à votre compte.';

  static String get accountUsesApple => _t?.errAccountUsesApple ?? 'Ce compte utilise une connexion Apple. Connectez-vous avec Apple pour accéder à votre compte.';

  static String get loginSuccess => _t?.errLoginSuccess ?? 'Vous êtes connecté.';

  // ── Connexion sociale ──
  static String get socialCancelled => _t?.errSocialCancelled ?? 'Connexion annulée.';

  static String get socialFailedGoogle => _t?.errSocialFailedGoogle ?? 'Impossible de vous connecter avec Google. Réessayez.';

  static String get socialFailedApple => _t?.errSocialFailedApple ?? 'Impossible de vous connecter avec Apple. Réessayez.';

  static String get socialAccountNotFound => _t?.errSocialAccountNotFound ?? 'Aucun compte n\'est associé à ce profil. Créez d\'abord un compte.';

  static String get socialEmailUsesPassword => _t?.errSocialEmailUsesPassword ?? 'Un compte existe déjà avec cet e-mail et utilise un mot de passe. Connectez-vous avec votre mot de passe.';

  // ── Inscription ──
  static String get signupPhoneTaken => _t?.errSignupPhoneTaken ?? 'Ce numéro de téléphone est déjà associé à un compte.';

  static String get signupEmailTaken => _t?.errSignupEmailTaken ?? 'Cette adresse e-mail est déjà utilisée.';

  static String get signupFailed => _t?.errSignupFailed ?? 'Impossible de créer votre compte pour le moment. Réessayez.';

  static String get signupSuccess => _t?.errSignupSuccess ?? 'Votre compte a bien été créé.';

  // ── Mot de passe oublié / réinitialisation ──
  static String get forgotAccountNotFound => _t?.errForgotAccountNotFound ?? 'Aucun compte n\'est associé à ce numéro de téléphone.';

  static String get forgotCodeSent => _t?.errForgotCodeSent ?? 'Un code de réinitialisation vient d\'être envoyé.';

  static String get forgotSendFailed => _t?.errForgotSendFailed ?? 'Impossible d\'envoyer le code. Réessayez dans quelques instants.';

  static String get otpInvalid => _t?.errOtpInvalid ?? 'Ce code est incorrect. Vérifiez-le et réessayez.';

  static String get otpExpired => _t?.errOtpExpired ?? 'Ce code a expiré. Demandez-en un nouveau pour continuer.';

  static String get resetSessionExpired => _t?.errResetSessionExpired ?? 'Votre demande a expiré. Recommencez la réinitialisation.';

  static String get resetFailed => _t?.errResetFailed ?? 'Impossible de réinitialiser votre mot de passe. Réessayez.';

  static String get resetSuccess => _t?.errResetSuccess ?? 'Votre mot de passe a bien été modifié.';

  // ── Profil (complétion et modification) ──
  static String get profileSaveFailed => _t?.errProfileSaveFailed ?? 'Impossible d\'enregistrer les modifications. Réessayez.';

  static String get profileSaveSuccess => _t?.errProfileSaveSuccess ?? 'Les informations ont bien été enregistrées.';

  static String get profileCompleteFailed => _t?.errProfileCompleteFailed ?? 'Impossible d\'enregistrer votre profil. Réessayez.';

  static String get avatarUpdateFailed => _t?.errAvatarUpdateFailed ?? 'Impossible de mettre à jour la photo de profil. Réessayez.';

  static String get avatarUpdateSuccess => _t?.errAvatarUpdateSuccess ?? 'Photo de profil mise à jour.';

  static String get avatarRemoveSuccess => _t?.errAvatarRemoveSuccess ?? 'Photo de profil supprimée.';

  static String get avatarInvalid => _t?.errAvatarInvalid ?? 'Cette image ne peut pas être utilisée. Essayez-en une autre.';

  static String get passwordCurrentIncorrect => _t?.errPasswordCurrentIncorrect ?? 'Le mot de passe actuel est incorrect.';

  static String get passwordChangeSuccess => _t?.errPasswordChangeSuccess ?? 'Votre mot de passe a bien été modifié.';

  static String get passwordChangeFailed => _t?.errPasswordChangeFailed ?? 'Impossible de modifier votre mot de passe. Réessayez.';

  // ── Équipe ──
  static String get teamActionFailed => _t?.errTeamActionFailed ?? 'Impossible d\'effectuer cette action. Réessayez.';

  // ── Erreurs de champ (affichées sous le champ) ──
  static String get fieldRequired => _t?.errFieldRequired ?? 'Veuillez renseigner ce champ.';

  static String get phoneInvalid => _t?.errPhoneInvalid ?? 'Le numéro de téléphone n\'est pas valide.';

  static String get phoneTaken => _t?.errPhoneTaken ?? 'Ce numéro de téléphone est déjà associé à un compte.';

  static String get phoneRisky => _t?.errPhoneRisky ?? 'Ce numéro ne peut pas être utilisé. Essayez-en un autre.';

  static String get emailInvalid => _t?.errEmailInvalid ?? 'L\'adresse e-mail n\'est pas valide.';

  static String get emailTaken => _t?.errEmailTaken ?? 'Cette adresse e-mail est déjà utilisée.';

  static String get passwordTooShort => _t?.errPasswordTooShort ?? 'Le mot de passe doit contenir au moins 8 caractères.';

  static String get passwordMismatch => _t?.errPasswordMismatch ?? 'Les deux mots de passe ne correspondent pas.';

  static String get passwordNeedsUppercase => _t?.errPasswordNeedsUppercase ?? 'Le mot de passe doit contenir au moins une majuscule.';

  static String get passwordNeedsDigit => _t?.errPasswordNeedsDigit ?? 'Le mot de passe doit contenir au moins un chiffre.';

  static String get passwordMustDiffer => _t?.errPasswordMustDiffer ?? 'Le nouveau mot de passe doit être différent de l\'actuel.';

  static String get passwordIncorrect => _t?.errPasswordIncorrect ?? 'Mot de passe incorrect.';

  static String get nameInvalid => _t?.errNameInvalid ?? 'Ce nom n\'est pas valide.';

  static String get commerceNameTaken => 'Ce nom de commerce est déjà utilisé.';

  static String get birthdateInvalid => _t?.errBirthdateInvalid ?? 'Cette date de naissance n\'est pas valide.';

  static String get birthdateRequired => _t?.errBirthdateRequired ?? 'Veuillez indiquer votre date de naissance.';

  static String get referralCodeInvalid => _t?.errReferralCodeInvalid ?? 'Ce code de parrainage n\'existe pas.';

  static String get otpFieldInvalid => _t?.errOtpFieldInvalid ?? 'Ce code n\'est pas valide.';

  static String get fieldInvalid => _t?.errFieldInvalid ?? 'Cette information n\'est pas valide.';
}
