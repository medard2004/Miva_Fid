import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @navWallet.
  ///
  /// In fr, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// No description provided for @navRewards.
  ///
  /// In fr, this message translates to:
  /// **'Récompenses'**
  String get navRewards;

  /// No description provided for @navReferral.
  ///
  /// In fr, this message translates to:
  /// **'Parrainage'**
  String get navReferral;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @commonCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get commonCopy;

  /// No description provided for @commonEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get commonEdit;

  /// No description provided for @commonDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get commonDone;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get settingsPreferences;

  /// No description provided for @settingsAppearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get settingsLanguageFrench;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get settingsAccount;

  /// No description provided for @settingsNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les alertes par établissement'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get settingsSignOutConfirmTitle;

  /// No description provided for @settingsSignOutConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir vous déconnecter de votre compte Carte ?'**
  String get settingsSignOutConfirmMessage;

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileEditProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get profileEditProfile;

  /// No description provided for @profileMemberSince.
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis {date}'**
  String profileMemberSince(String date);

  /// No description provided for @profileCards.
  ///
  /// In fr, this message translates to:
  /// **'Cartes'**
  String get profileCards;

  /// No description provided for @profileOffers.
  ///
  /// In fr, this message translates to:
  /// **'Offres'**
  String get profileOffers;

  /// No description provided for @profileReferrals.
  ///
  /// In fr, this message translates to:
  /// **'Filleuls'**
  String get profileReferrals;

  /// No description provided for @profileNotConnectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'êtes pas connecté'**
  String get profileNotConnectedTitle;

  /// No description provided for @profileNotConnectedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour accéder à votre profil.'**
  String get profileNotConnectedMessage;

  /// No description provided for @profileSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get profileSignIn;

  /// No description provided for @profileSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get profileSettings;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Apparence, langue, notifications'**
  String get profileSettingsSubtitle;

  /// No description provided for @profileReferralCode.
  ///
  /// In fr, this message translates to:
  /// **'Votre code invitation'**
  String get profileReferralCode;

  /// No description provided for @profileReferralCodeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code parrainage copié dans le presse-papier !'**
  String get profileReferralCodeCopied;

  /// No description provided for @profileBirthdayBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Joyeux mois d\'anniversaire !'**
  String get profileBirthdayBannerTitle;

  /// No description provided for @profileBirthdayBannerMessage.
  ///
  /// In fr, this message translates to:
  /// **'Des attentions exclusives vous attendent dans vos restaurants.'**
  String get profileBirthdayBannerMessage;

  /// No description provided for @editProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfileTitle;

  /// No description provided for @editProfileFullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get editProfileFullName;

  /// No description provided for @editProfileFullNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Kokou John'**
  String get editProfileFullNameHint;

  /// No description provided for @editProfileFullNameError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre nom complet'**
  String get editProfileFullNameError;

  /// No description provided for @editProfilePhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get editProfilePhone;

  /// No description provided for @editProfileBirthDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get editProfileBirthDate;

  /// No description provided for @editProfileEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get editProfileEmail;

  /// No description provided for @editProfileEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'votre@email.com'**
  String get editProfileEmailHint;

  /// No description provided for @editProfileSaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès !'**
  String get editProfileSaveSuccess;

  /// No description provided for @referralTitle.
  ///
  /// In fr, this message translates to:
  /// **'Parrainage'**
  String get referralTitle;

  /// No description provided for @referralSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recommandez vos restaurants favoris et cumulez des points.'**
  String get referralSubtitle;

  /// No description provided for @referralEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte à parrainer'**
  String get referralEmptyTitle;

  /// No description provided for @referralEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez au moins un établissement pour pouvoir le recommander à vos proches.'**
  String get referralEmptyMessage;

  /// No description provided for @referralPointsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Points de parrainage'**
  String get referralPointsLabel;

  /// No description provided for @referralPointsEarned.
  ///
  /// In fr, this message translates to:
  /// **'{count} points cumulés'**
  String referralPointsEarned(int count);

  /// No description provided for @referralSharesToNext.
  ///
  /// In fr, this message translates to:
  /// **'Encore {count} partages'**
  String referralSharesToNext(int count);

  /// No description provided for @referralChoosePartner.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le partenaire'**
  String get referralChoosePartner;

  /// No description provided for @referralRecipientHint.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone ou nom'**
  String get referralRecipientHint;

  /// No description provided for @referralSendButton.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer l\'invitation'**
  String get referralSendButton;

  /// No description provided for @referralSendButtonWithCount.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer l\'invitation ({count})'**
  String referralSendButtonWithCount(int count);

  /// No description provided for @referralDuplicateRecipient.
  ///
  /// In fr, this message translates to:
  /// **'Ce destinataire est déjà dans votre liste d\'envoi.'**
  String get referralDuplicateRecipient;

  /// No description provided for @referralNoRecipient.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ajouter au moins un destinataire avant d\'envoyer.'**
  String get referralNoRecipient;

  /// No description provided for @referralSentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'{count} invitation(s) envoyée(s) !'**
  String referralSentSuccess(int count);

  /// No description provided for @referralHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique des partages'**
  String get referralHistoryTitle;

  /// No description provided for @referralHistoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun partage effectué pour le moment.'**
  String get referralHistoryEmpty;

  /// No description provided for @referralMessageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre message'**
  String get referralMessageLabel;

  /// No description provided for @referralRecipientsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Destinataires'**
  String get referralRecipientsLabel;

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer lu'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous serez prévenu ici de vos tampons, récompenses et statuts VIP.'**
  String get notificationsEmptyMessage;

  /// No description provided for @commonConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get commonConfirm;

  /// No description provided for @commonHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get commonHistory;

  /// No description provided for @commonCountdownPrefix.
  ///
  /// In fr, this message translates to:
  /// **'J-'**
  String get commonCountdownPrefix;

  /// No description provided for @cardStampsLabel.
  ///
  /// In fr, this message translates to:
  /// **'TAMPONS'**
  String get cardStampsLabel;

  /// No description provided for @cardPointsLabel.
  ///
  /// In fr, this message translates to:
  /// **'SOLDE'**
  String get cardPointsLabel;

  /// No description provided for @cardPointsSuffix.
  ///
  /// In fr, this message translates to:
  /// **'PTS'**
  String get cardPointsSuffix;

  /// No description provided for @cardSpendLabel.
  ///
  /// In fr, this message translates to:
  /// **'OBJECTIF ACHAT'**
  String get cardSpendLabel;

  /// No description provided for @cardCashbackLabel.
  ///
  /// In fr, this message translates to:
  /// **'CASHBACK'**
  String get cardCashbackLabel;

  /// No description provided for @cardCashbackSuffix.
  ///
  /// In fr, this message translates to:
  /// **'FCFA'**
  String get cardCashbackSuffix;

  /// No description provided for @cardVipMaxTier.
  ///
  /// In fr, this message translates to:
  /// **'Palier maximum atteint'**
  String get cardVipMaxTier;

  /// No description provided for @cardVipNextTier.
  ///
  /// In fr, this message translates to:
  /// **'Platinum dans {count} visites'**
  String cardVipNextTier(int count);

  /// No description provided for @rewardsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récompenses'**
  String get rewardsTitle;

  /// No description provided for @rewardsEmptyActiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun privilège disponible'**
  String get rewardsEmptyActiveTitle;

  /// No description provided for @rewardsEmptyActiveMessage.
  ///
  /// In fr, this message translates to:
  /// **'Revenez bientôt pour de nouvelles offres.'**
  String get rewardsEmptyActiveMessage;

  /// No description provided for @rewardsToUnlock.
  ///
  /// In fr, this message translates to:
  /// **'À débloquer'**
  String get rewardsToUnlock;

  /// No description provided for @rewardsAllUnlockedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout est débloqué'**
  String get rewardsAllUnlockedTitle;

  /// No description provided for @rewardsAllUnlockedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune récompense verrouillée pour le moment.'**
  String get rewardsAllUnlockedMessage;

  /// No description provided for @rewardsHistoryEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun historique'**
  String get rewardsHistoryEmptyTitle;

  /// No description provided for @rewardsHistoryEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vos récompenses utilisées apparaîtront ici.'**
  String get rewardsHistoryEmptyMessage;

  /// No description provided for @rewardsRedeemConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser cette récompense ?'**
  String get rewardsRedeemConfirmTitle;

  /// No description provided for @rewardsRedeemConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » sera marquée comme utilisée et retirée de vos privilèges actifs. Présentez cet écran à l\'enseigne avant de confirmer.'**
  String rewardsRedeemConfirmMessage(String title);

  /// No description provided for @rewardsRedeemSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Récompense marquée comme utilisée'**
  String get rewardsRedeemSuccess;

  /// No description provided for @rewardsUseButton.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser'**
  String get rewardsUseButton;

  /// No description provided for @rewardsShowQrInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Présentez ce code au marchand pour l\'utiliser. Valable une seule fois.'**
  String get rewardsShowQrInstruction;

  /// No description provided for @walletGreetingMorning.
  ///
  /// In fr, this message translates to:
  /// **'BONJOUR'**
  String get walletGreetingMorning;

  /// No description provided for @walletGreetingAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'BON APRÈS-MIDI'**
  String get walletGreetingAfternoon;

  /// No description provided for @walletGreetingEvening.
  ///
  /// In fr, this message translates to:
  /// **'BONSOIR'**
  String get walletGreetingEvening;

  /// No description provided for @walletFallbackName.
  ///
  /// In fr, this message translates to:
  /// **'vous'**
  String get walletFallbackName;

  /// No description provided for @walletSearchSemanticLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une carte'**
  String get walletSearchSemanticLabel;

  /// No description provided for @walletSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une carte ou une enseigne'**
  String get walletSearchHint;

  /// No description provided for @walletSearchNoResultsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte trouvée'**
  String get walletSearchNoResultsTitle;

  /// No description provided for @walletSearchNoResultsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Essayez un autre nom ou une autre enseigne.'**
  String get walletSearchNoResultsMessage;

  /// No description provided for @walletEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte pour l\'instant'**
  String get walletEmptyTitle;

  /// No description provided for @walletEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Scannez votre premier QR pour commencer votre collection.'**
  String get walletEmptyMessage;

  /// No description provided for @walletScanButton.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un QR code'**
  String get walletScanButton;

  /// No description provided for @cardDetailNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Carte introuvable'**
  String get cardDetailNotFound;

  /// No description provided for @cardDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre carte'**
  String get cardDetailTitle;

  /// No description provided for @cardDetailExportTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Exporter / Partager'**
  String get cardDetailExportTooltip;

  /// No description provided for @cardDetailDefaultOfferRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Offre'**
  String get cardDetailDefaultOfferRestaurant;

  /// No description provided for @cardDetailDefaultOfferTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récompense à venir'**
  String get cardDetailDefaultOfferTitle;

  /// No description provided for @cardDetailDefaultOfferMessage.
  ///
  /// In fr, this message translates to:
  /// **'Continuez à cumuler pour débloquer votre prochain privilège.'**
  String get cardDetailDefaultOfferMessage;

  /// No description provided for @cardDetailExportSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exportation'**
  String get cardDetailExportSheetTitle;

  /// No description provided for @cardDetailSaveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la carte'**
  String get cardDetailSaveTitle;

  /// No description provided for @cardDetailSaveSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Conserver dans votre Portefeuille d\'application'**
  String get cardDetailSaveSubtitle;

  /// No description provided for @cardDetailDownloadTitle.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger la carte'**
  String get cardDetailDownloadTitle;

  /// No description provided for @cardDetailDownloadSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un visuel HD dans votre galerie (Pass format)'**
  String get cardDetailDownloadSubtitle;

  /// No description provided for @cardDetailShareTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partager la carte'**
  String get cardDetailShareTitle;

  /// No description provided for @cardDetailShareSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Générer et envoyer une version propre à un proche'**
  String get cardDetailShareSubtitle;

  /// No description provided for @cardDetailFullScreen.
  ///
  /// In fr, this message translates to:
  /// **'Plein écran'**
  String get cardDetailFullScreen;

  /// No description provided for @cardDetailIdCopied.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant copié'**
  String get cardDetailIdCopied;

  /// No description provided for @cardDetailQrInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Présentez ce QR Code lors de votre passage en caisse'**
  String get cardDetailQrInstructions;

  /// No description provided for @cardDetailVisitsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one {{count} VISITE} other {{count} VISITES}}'**
  String cardDetailVisitsCount(int count);

  /// No description provided for @rewardStatusReady.
  ///
  /// In fr, this message translates to:
  /// **'PRÊT'**
  String get rewardStatusReady;

  /// No description provided for @rewardStatusLocked.
  ///
  /// In fr, this message translates to:
  /// **'VERROUILLÉ'**
  String get rewardStatusLocked;

  /// No description provided for @rewardStatusUsed.
  ///
  /// In fr, this message translates to:
  /// **'UTILISÉ'**
  String get rewardStatusUsed;

  /// No description provided for @rewardStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'EXPIRÉ'**
  String get rewardStatusExpired;

  /// No description provided for @rewardExpirationDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration'**
  String get rewardExpirationDate;

  /// No description provided for @rewardUsedDate.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé le'**
  String get rewardUsedDate;

  /// No description provided for @rewardQrInstructions2.
  ///
  /// In fr, this message translates to:
  /// **'Présentez ce QR Code pour utiliser votre récompense'**
  String get rewardQrInstructions2;

  /// No description provided for @historyStampEntry.
  ///
  /// In fr, this message translates to:
  /// **'+1 tampon · Passage en caisse'**
  String get historyStampEntry;

  /// No description provided for @historyPointsEntry.
  ///
  /// In fr, this message translates to:
  /// **'+{points} points · Passage en caisse'**
  String historyPointsEntry(int points);

  /// No description provided for @historyCashbackEntry.
  ///
  /// In fr, this message translates to:
  /// **'+{amount} FCFA · Passage en caisse'**
  String historyCashbackEntry(int amount);

  /// No description provided for @historyVisitEntry.
  ///
  /// In fr, this message translates to:
  /// **'Visite comptabilisée'**
  String get historyVisitEntry;

  /// No description provided for @historySignupEntry.
  ///
  /// In fr, this message translates to:
  /// **'Inscription à la carte'**
  String get historySignupEntry;

  /// No description provided for @historyCashbackRedeemEntry.
  ///
  /// In fr, this message translates to:
  /// **'-{amount} FCFA · Cashback utilisé'**
  String historyCashbackRedeemEntry(int amount);

  /// No description provided for @cardDetailHistoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération pour l\'instant.'**
  String get cardDetailHistoryEmpty;

  /// No description provided for @exportFailedRetry.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'export : réessayez.'**
  String get exportFailedRetry;

  /// No description provided for @exportShareSubject.
  ///
  /// In fr, this message translates to:
  /// **'Ma carte {name} — Carte'**
  String exportShareSubject(String name);

  /// No description provided for @exportShareText.
  ///
  /// In fr, this message translates to:
  /// **'Découvre {name} sur Carte !'**
  String exportShareText(String name);

  /// No description provided for @exportDownloadReady.
  ///
  /// In fr, this message translates to:
  /// **'Image HD de la carte {id} prête — choisissez « Enregistrer l\'image ».'**
  String exportDownloadReady(String id);

  /// No description provided for @exportShareSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Visuel de la carte {name} partagé.'**
  String exportShareSuccess(String name);

  /// No description provided for @exportSaveReady.
  ///
  /// In fr, this message translates to:
  /// **'Carte « {name} » prête à être enregistrée.'**
  String exportSaveReady(String name);

  /// No description provided for @exportFailedGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'export : une erreur est survenue.'**
  String get exportFailedGeneric;

  /// No description provided for @commonPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get commonPhoneLabel;

  /// No description provided for @commonOptional.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel'**
  String get commonOptional;

  /// No description provided for @authLoginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get authLoginTitle;

  /// No description provided for @authContinueGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get authContinueGoogle;

  /// No description provided for @authContinueApple.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get authContinueApple;

  /// No description provided for @authNoAccountPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore membre ? '**
  String get authNoAccountPrefix;

  /// No description provided for @authSignUpLink.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get authSignUpLink;

  /// No description provided for @authSignupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authSignupTitle;

  /// No description provided for @authBirthDateError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner votre date de naissance'**
  String get authBirthDateError;

  /// No description provided for @authPhoneRequiredError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre numéro de téléphone'**
  String get authPhoneRequiredError;

  /// No description provided for @authSignupButton.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get authSignupButton;

  /// No description provided for @authSignupGoogle.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire avec Google'**
  String get authSignupGoogle;

  /// No description provided for @authSignupApple.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire avec Apple'**
  String get authSignupApple;

  /// No description provided for @authHasAccountPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Déjà membre ? '**
  String get authHasAccountPrefix;

  /// No description provided for @authAcceptPrefix.
  ///
  /// In fr, this message translates to:
  /// **'En continuant, vous acceptez les '**
  String get authAcceptPrefix;

  /// No description provided for @authTermsLink.
  ///
  /// In fr, this message translates to:
  /// **'CGU'**
  String get authTermsLink;

  /// No description provided for @authAcceptAnd.
  ///
  /// In fr, this message translates to:
  /// **' et la '**
  String get authAcceptAnd;

  /// No description provided for @authPrivacyLink.
  ///
  /// In fr, this message translates to:
  /// **'politique de confidentialité'**
  String get authPrivacyLink;

  /// No description provided for @legalTermsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions Générales d\'Utilisation'**
  String get legalTermsTitle;

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get legalPrivacyTitle;

  /// No description provided for @authTermsRequiredError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez accepter les CGU et la politique de confidentialité pour continuer.'**
  String get authTermsRequiredError;

  /// No description provided for @otpContextLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get otpContextLogin;

  /// No description provided for @otpContextSignup.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get otpContextSignup;

  /// No description provided for @otpContextSocial.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get otpContextSocial;

  /// No description provided for @otpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get otpTitle;

  /// No description provided for @otpSentMessage.
  ///
  /// In fr, this message translates to:
  /// **'Un code à 6 chiffres a été envoyé au\n{phone}'**
  String otpSentMessage(String phone);

  /// No description provided for @otpResendCountdown.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code dans 00:{seconds}'**
  String otpResendCountdown(String seconds);

  /// No description provided for @otpResendButton.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get otpResendButton;

  /// No description provided for @completeProfileWelcomeNamed.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue, {name} !\nVotre compte a été créé.'**
  String completeProfileWelcomeNamed(String name);

  /// No description provided for @completeProfileWelcomeAnon.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue !\nVotre compte a été créé.'**
  String get completeProfileWelcomeAnon;

  /// No description provided for @completeProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Complétez votre profil'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Accéder à l\'application'**
  String get completeProfileSubmit;

  /// No description provided for @completeProfileSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer cette étape'**
  String get completeProfileSkip;

  /// No description provided for @completeSocialProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compléter le profil'**
  String get completeSocialProfileTitle;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In fr, this message translates to:
  /// **'Toutes vos cartes,\nun seul portefeuille'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rassemblez vos cartes de fidélité préférées dans une expérience unique, rapide et sans friction.'**
  String get onboardingSlide1Subtitle;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In fr, this message translates to:
  /// **'Des privilèges\nà chaque visite'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Cumulez tampons et points automatiquement, et débloquez des avantages exclusifs chez vos enseignes favorites.'**
  String get onboardingSlide2Subtitle;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In fr, this message translates to:
  /// **'Partagez,\ngagnez ensemble'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitez vos proches avec votre code personnel et cumulez des points de parrainage.'**
  String get onboardingSlide3Subtitle;

  /// No description provided for @onboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer l\'expérience'**
  String get onboardingStart;

  /// No description provided for @onboardingContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get onboardingContinue;

  /// No description provided for @commonValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get commonValidate;

  /// No description provided for @qrManualEntryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code manuellement'**
  String get qrManualEntryLabel;

  /// No description provided for @qrScanTitle.
  ///
  /// In fr, this message translates to:
  /// **'SCANNER UN QR'**
  String get qrScanTitle;

  /// No description provided for @qrToggleFlash.
  ///
  /// In fr, this message translates to:
  /// **'Activer ou désactiver le flash'**
  String get qrToggleFlash;

  /// No description provided for @qrPlaceInFrame.
  ///
  /// In fr, this message translates to:
  /// **'Placez le QR du restaurant dans le cadre.'**
  String get qrPlaceInFrame;

  /// No description provided for @qrManualEntryHint.
  ///
  /// In fr, this message translates to:
  /// **'Le code unique à 8 caractères figure sous le QR affiché par l\'établissement.'**
  String get qrManualEntryHint;

  /// No description provided for @qrManualEntryPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 8XKQ2P9Z'**
  String get qrManualEntryPlaceholder;

  /// No description provided for @qrCameraUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Caméra indisponible'**
  String get qrCameraUnavailableTitle;

  /// No description provided for @qrCameraUnavailableMessage.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez l\'accès à la caméra dans les réglages, ou saisissez le code manuellement.'**
  String get qrCameraUnavailableMessage;

  /// No description provided for @joinOfferDetail.
  ///
  /// In fr, this message translates to:
  /// **'Cumulez 10 tampons pour un menu entier offert.'**
  String get joinOfferDetail;

  /// No description provided for @joinUnrecognizedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code non reconnu'**
  String get joinUnrecognizedTitle;

  /// No description provided for @joinUnrecognizedMessage.
  ///
  /// In fr, this message translates to:
  /// **'« {code} » ne correspond à aucun établissement partenaire de Carte pour le moment.'**
  String joinUnrecognizedMessage(String code);

  /// No description provided for @joinRetryScan.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer un scan'**
  String get joinRetryScan;

  /// No description provided for @joinBackToWallet.
  ///
  /// In fr, this message translates to:
  /// **'Retour au portefeuille'**
  String get joinBackToWallet;

  /// No description provided for @joinEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get joinEyebrow;

  /// No description provided for @joinWelcomeOfferEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Offre de bienvenue'**
  String get joinWelcomeOfferEyebrow;

  /// No description provided for @joinButton.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre le programme'**
  String get joinButton;

  /// No description provided for @joinCardCreatedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Carte créée !'**
  String get joinCardCreatedTitle;

  /// No description provided for @joinCardAlreadyMemberTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déjà membre !'**
  String get joinCardAlreadyMemberTitle;

  /// No description provided for @joinCardAlreadyMemberMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes déjà membre de ce programme de fidélité.'**
  String get joinCardAlreadyMemberMessage;

  /// No description provided for @phonePickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un indicatif'**
  String get phonePickerTitle;

  /// No description provided for @phonePickerSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un pays ou un indicatif...'**
  String get phonePickerSearchHint;

  /// No description provided for @phoneDigitsError.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro doit contenir {count} chiffres pour {country}.'**
  String phoneDigitsError(int count, String country);

  /// No description provided for @countryPickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un pays'**
  String get countryPickerTitle;

  /// No description provided for @countryPickerSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un pays...'**
  String get countryPickerSearchHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPasswordLabel;

  /// No description provided for @authForgotPasswordLink.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get authForgotPasswordLink;

  /// No description provided for @authLoadingLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion en cours...'**
  String get authLoadingLogin;

  /// No description provided for @authLoadingGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion via Google...'**
  String get authLoadingGoogle;

  /// No description provided for @authLoadingApple.
  ///
  /// In fr, this message translates to:
  /// **'Connexion via Apple...'**
  String get authLoadingApple;

  /// No description provided for @authLoadingSignup.
  ///
  /// In fr, this message translates to:
  /// **'Création du compte...'**
  String get authLoadingSignup;

  /// No description provided for @authLoadingSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion en cours...'**
  String get authLoadingSignOut;

  /// No description provided for @createPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre mot de passe'**
  String get createPasswordTitle;

  /// No description provided for @createPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Dernière étape pour sécuriser votre compte.'**
  String get createPasswordSubtitle;

  /// No description provided for @createPasswordConfirmLabel.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez le mot de passe'**
  String get createPasswordConfirmLabel;

  /// No description provided for @createPasswordRuleMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 8 caractères'**
  String get createPasswordRuleMinLength;

  /// No description provided for @createPasswordRuleUppercase.
  ///
  /// In fr, this message translates to:
  /// **'Une majuscule'**
  String get createPasswordRuleUppercase;

  /// No description provided for @createPasswordRuleDigit.
  ///
  /// In fr, this message translates to:
  /// **'Un chiffre'**
  String get createPasswordRuleDigit;

  /// No description provided for @createPasswordButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get createPasswordButton;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez votre numéro : nous vous enverrons un code de vérification.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le code'**
  String get forgotPasswordButton;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un nouveau mot de passe pour votre compte.'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordButton.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get resetPasswordButton;

  /// No description provided for @resetPasswordLoading.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialisation...'**
  String get resetPasswordLoading;

  /// No description provided for @otpVerifyLoading.
  ///
  /// In fr, this message translates to:
  /// **'Vérification du code...'**
  String get otpVerifyLoading;

  /// No description provided for @splashLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get splashLoading;

  /// No description provided for @forgotPasswordUseEmail.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser mon adresse e-mail'**
  String get forgotPasswordUseEmail;

  /// No description provided for @forgotPasswordUsePhone.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser mon numéro de téléphone'**
  String get forgotPasswordUsePhone;

  /// No description provided for @forgotPasswordEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get forgotPasswordEmailLabel;

  /// No description provided for @forgotPasswordEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'vous@exemple.com'**
  String get forgotPasswordEmailHint;

  /// No description provided for @forgotPasswordSubtitleEmail.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez votre adresse e-mail : nous vous enverrons un code de vérification.'**
  String get forgotPasswordSubtitleEmail;

  /// No description provided for @forgotPasswordSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi du code...'**
  String get forgotPasswordSending;

  /// No description provided for @errNoInternet.
  ///
  /// In fr, this message translates to:
  /// **'Vous semblez hors ligne. Vérifiez votre connexion, puis réessayez.'**
  String get errNoInternet;

  /// No description provided for @errServerUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Nous n\'arrivons pas à joindre nos serveurs. Réessayez dans quelques instants.'**
  String get errServerUnreachable;

  /// No description provided for @errServerError.
  ///
  /// In fr, this message translates to:
  /// **'Le service est momentanément indisponible. Réessayez dans quelques instants.'**
  String get errServerError;

  /// No description provided for @errUnexpected.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get errUnexpected;

  /// No description provided for @errTooManyAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patientez quelques instants avant de réessayer.'**
  String get errTooManyAttempts;

  /// No description provided for @errSessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré. Reconnectez-vous pour continuer.'**
  String get errSessionExpired;

  /// No description provided for @errMissingRequiredFields.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner tous les champs obligatoires.'**
  String get errMissingRequiredFields;

  /// No description provided for @errLoginInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone ou mot de passe incorrect.'**
  String get errLoginInvalidCredentials;

  /// No description provided for @errMerchantLoginInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail ou mot de passe incorrect.'**
  String get errMerchantLoginInvalidCredentials;

  /// No description provided for @errLoginAccountNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte n\'existe pas encore.'**
  String get errLoginAccountNotFound;

  /// No description provided for @errLoginAccountDeactivated.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte a été désactivé. Contactez votre administrateur.'**
  String get errLoginAccountDeactivated;

  /// No description provided for @errTeamActionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'effectuer cette action. Réessayez.'**
  String get errTeamActionFailed;

  /// No description provided for @errLoginFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vous connecter pour le moment. Réessayez.'**
  String get errLoginFailed;

  /// No description provided for @errAccountUsesGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte utilise une connexion Google. Connectez-vous avec Google pour accéder à votre compte.'**
  String get errAccountUsesGoogle;

  /// No description provided for @errAccountUsesApple.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte utilise une connexion Apple. Connectez-vous avec Apple pour accéder à votre compte.'**
  String get errAccountUsesApple;

  /// No description provided for @errLoginSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes connecté.'**
  String get errLoginSuccess;

  /// No description provided for @errSocialCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Connexion annulée.'**
  String get errSocialCancelled;

  /// No description provided for @errSocialFailedGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vous connecter avec Google. Réessayez.'**
  String get errSocialFailedGoogle;

  /// No description provided for @errSocialFailedApple.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vous connecter avec Apple. Réessayez.'**
  String get errSocialFailedApple;

  /// No description provided for @errSocialAccountNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte n\'est associé à ce profil. Créez d\'abord un compte.'**
  String get errSocialAccountNotFound;

  /// No description provided for @errSocialEmailUsesPassword.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cet e-mail et utilise un mot de passe. Connectez-vous avec votre mot de passe.'**
  String get errSocialEmailUsesPassword;

  /// No description provided for @errSignupPhoneTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro de téléphone est déjà associé à un compte.'**
  String get errSignupPhoneTaken;

  /// No description provided for @errSignupEmailTaken.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse e-mail est déjà utilisée.'**
  String get errSignupEmailTaken;

  /// No description provided for @errSignupFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer votre compte pour le moment. Réessayez.'**
  String get errSignupFailed;

  /// No description provided for @errSignupSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte a bien été créé.'**
  String get errSignupSuccess;

  /// No description provided for @errForgotAccountNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte n\'est associé à ce numéro de téléphone.'**
  String get errForgotAccountNotFound;

  /// No description provided for @errMerchantForgotAccountNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte n\'est associé à cette adresse e-mail.'**
  String get errMerchantForgotAccountNotFound;

  /// No description provided for @errForgotCodeSent.
  ///
  /// In fr, this message translates to:
  /// **'Un code de réinitialisation vient d\'être envoyé.'**
  String get errForgotCodeSent;

  /// No description provided for @errForgotSendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le code. Réessayez dans quelques instants.'**
  String get errForgotSendFailed;

  /// No description provided for @errOtpInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Ce code est incorrect. Vérifiez-le et réessayez.'**
  String get errOtpInvalid;

  /// No description provided for @errOtpExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a expiré. Demandez-en un nouveau pour continuer.'**
  String get errOtpExpired;

  /// No description provided for @errResetSessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande a expiré. Recommencez la réinitialisation.'**
  String get errResetSessionExpired;

  /// No description provided for @errResetFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de réinitialiser votre mot de passe. Réessayez.'**
  String get errResetFailed;

  /// No description provided for @errResetSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Votre mot de passe a bien été modifié.'**
  String get errResetSuccess;

  /// No description provided for @errProfileSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les modifications. Réessayez.'**
  String get errProfileSaveFailed;

  /// No description provided for @errProfileSaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Les informations ont bien été enregistrées.'**
  String get errProfileSaveSuccess;

  /// No description provided for @errProfileCompleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer votre profil. Réessayez.'**
  String get errProfileCompleteFailed;

  /// No description provided for @errAvatarUpdateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour la photo de profil. Réessayez.'**
  String get errAvatarUpdateFailed;

  /// No description provided for @errAvatarUpdateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil mise à jour.'**
  String get errAvatarUpdateSuccess;

  /// No description provided for @errAvatarRemoveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil supprimée.'**
  String get errAvatarRemoveSuccess;

  /// No description provided for @errAvatarInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Cette image ne peut pas être utilisée. Essayez-en une autre.'**
  String get errAvatarInvalid;

  /// No description provided for @errPasswordCurrentIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe actuel est incorrect.'**
  String get errPasswordCurrentIncorrect;

  /// No description provided for @errPasswordChangeSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Votre mot de passe a bien été modifié.'**
  String get errPasswordChangeSuccess;

  /// No description provided for @errPasswordChangeFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier votre mot de passe. Réessayez.'**
  String get errPasswordChangeFailed;

  /// No description provided for @errFieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner ce champ.'**
  String get errFieldRequired;

  /// No description provided for @errPhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro de téléphone n\'est pas valide.'**
  String get errPhoneInvalid;

  /// No description provided for @errPhoneTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro de téléphone est déjà associé à un compte.'**
  String get errPhoneTaken;

  /// No description provided for @errPhoneRisky.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro ne peut pas être utilisé. Essayez-en un autre.'**
  String get errPhoneRisky;

  /// No description provided for @errEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse e-mail n\'est pas valide.'**
  String get errEmailInvalid;

  /// No description provided for @errEmailTaken.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse e-mail est déjà utilisée.'**
  String get errEmailTaken;

  /// No description provided for @errPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 8 caractères.'**
  String get errPasswordTooShort;

  /// No description provided for @errPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux mots de passe ne correspondent pas.'**
  String get errPasswordMismatch;

  /// No description provided for @errPasswordNeedsUppercase.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins une majuscule.'**
  String get errPasswordNeedsUppercase;

  /// No description provided for @errPasswordNeedsDigit.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins un chiffre.'**
  String get errPasswordNeedsDigit;

  /// No description provided for @errPasswordMustDiffer.
  ///
  /// In fr, this message translates to:
  /// **'Le nouveau mot de passe doit être différent de l\'actuel.'**
  String get errPasswordMustDiffer;

  /// No description provided for @errPasswordIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect.'**
  String get errPasswordIncorrect;

  /// No description provided for @errNameInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Ce nom n\'est pas valide.'**
  String get errNameInvalid;

  /// No description provided for @errBirthdateInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Cette date de naissance n\'est pas valide.'**
  String get errBirthdateInvalid;

  /// No description provided for @errBirthdateRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez indiquer votre date de naissance.'**
  String get errBirthdateRequired;

  /// No description provided for @errReferralCodeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Ce code de parrainage n\'existe pas.'**
  String get errReferralCodeInvalid;

  /// No description provided for @errOtpFieldInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Ce code n\'est pas valide.'**
  String get errOtpFieldInvalid;

  /// No description provided for @errFieldInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Cette information n\'est pas valide.'**
  String get errFieldInvalid;

  /// No description provided for @changePasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le mot de passe'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordVerifySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre mot de passe actuel pour continuer.'**
  String get changePasswordVerifySubtitle;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordVerifying.
  ///
  /// In fr, this message translates to:
  /// **'Vérification...'**
  String get changePasswordVerifying;

  /// No description provided for @changePasswordContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get changePasswordContinue;

  /// No description provided for @changePasswordNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get changePasswordNewTitle;

  /// No description provided for @changePasswordNewSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un mot de passe différent de l\'actuel.'**
  String get changePasswordNewSubtitle;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordSaving.
  ///
  /// In fr, this message translates to:
  /// **'Modification...'**
  String get changePasswordSaving;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get changePasswordSubmit;

  /// No description provided for @editProfileCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get editProfileCity;

  /// No description provided for @editProfileCityHint.
  ///
  /// In fr, this message translates to:
  /// **'Lomé'**
  String get editProfileCityHint;

  /// No description provided for @editProfileCountry.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get editProfileCountry;

  /// No description provided for @editProfileCountryHint.
  ///
  /// In fr, this message translates to:
  /// **'Togo'**
  String get editProfileCountryHint;

  /// No description provided for @editProfileSaving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement...'**
  String get editProfileSaving;

  /// No description provided for @editProfilePhotoChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get editProfilePhotoChange;

  /// No description provided for @editProfilePhotoRemove.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get editProfilePhotoRemove;

  /// No description provided for @editProfileSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get editProfileSecurity;

  /// No description provided for @editProfileNotSet.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get editProfileNotSet;

  /// No description provided for @editProfilePhotoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil'**
  String get editProfilePhotoLabel;

  /// No description provided for @editProfileAuthMethod.
  ///
  /// In fr, this message translates to:
  /// **'Méthode de connexion'**
  String get editProfileAuthMethod;

  /// No description provided for @editProfileConnectedVia.
  ///
  /// In fr, this message translates to:
  /// **'Connecté via {provider}'**
  String editProfileConnectedVia(String provider);

  /// No description provided for @merchantNavClients.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get merchantNavClients;

  /// No description provided for @merchantNavStats.
  ///
  /// In fr, this message translates to:
  /// **'Stats'**
  String get merchantNavStats;

  /// No description provided for @merchantNavValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get merchantNavValidate;

  /// No description provided for @merchantNavSms.
  ///
  /// In fr, this message translates to:
  /// **'SMS'**
  String get merchantNavSms;

  /// No description provided for @merchantNavSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get merchantNavSettings;

  /// No description provided for @merchantMoreBusinessProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil du commerce'**
  String get merchantMoreBusinessProfile;

  /// No description provided for @merchantMoreCompleteProfile.
  ///
  /// In fr, this message translates to:
  /// **'Compléter mon profil'**
  String get merchantMoreCompleteProfile;

  /// No description provided for @merchantMoreLogoBusiness.
  ///
  /// In fr, this message translates to:
  /// **'Logo du commerce'**
  String get merchantMoreLogoBusiness;

  /// No description provided for @merchantMoreSocials.
  ///
  /// In fr, this message translates to:
  /// **'Réseaux sociaux'**
  String get merchantMoreSocials;

  /// No description provided for @merchantMoreGoogleReviewLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien d\'avis Google'**
  String get merchantMoreGoogleReviewLink;

  /// No description provided for @merchantMoreSectionAccount.
  ///
  /// In fr, this message translates to:
  /// **'COMPTE'**
  String get merchantMoreSectionAccount;

  /// No description provided for @merchantMoreHours.
  ///
  /// In fr, this message translates to:
  /// **'Horaires d\'ouverture'**
  String get merchantMoreHours;

  /// No description provided for @merchantMoreToComplete.
  ///
  /// In fr, this message translates to:
  /// **'À compléter'**
  String get merchantMoreToComplete;

  /// No description provided for @merchantMoreSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get merchantMoreSubscription;

  /// No description provided for @merchantMoreProTag.
  ///
  /// In fr, this message translates to:
  /// **'Pro'**
  String get merchantMoreProTag;

  /// No description provided for @merchantMoreLanguageTheme.
  ///
  /// In fr, this message translates to:
  /// **'Langue & thème'**
  String get merchantMoreLanguageTheme;

  /// No description provided for @merchantMoreTeam.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get merchantMoreTeam;

  /// No description provided for @merchantMoreSectionLoyaltyCard.
  ///
  /// In fr, this message translates to:
  /// **'MA CARTE DE FIDÉLITÉ'**
  String get merchantMoreSectionLoyaltyCard;

  /// No description provided for @merchantMoreCustomizeCard.
  ///
  /// In fr, this message translates to:
  /// **'Personnaliser la carte'**
  String get merchantMoreCustomizeCard;

  /// No description provided for @merchantMoreGoalReward.
  ///
  /// In fr, this message translates to:
  /// **'Objectif & récompense'**
  String get merchantMoreGoalReward;

  /// No description provided for @merchantMoreLoyaltyProgram.
  ///
  /// In fr, this message translates to:
  /// **'Programme de fidélité'**
  String get merchantMoreLoyaltyProgram;

  /// No description provided for @merchantMoreMyQrCode.
  ///
  /// In fr, this message translates to:
  /// **'Mon QR code'**
  String get merchantMoreMyQrCode;

  /// No description provided for @merchantMoreMyShowcase.
  ///
  /// In fr, this message translates to:
  /// **'Ma vitrine'**
  String get merchantMoreMyShowcase;

  /// No description provided for @merchantMoreSectionSupport.
  ///
  /// In fr, this message translates to:
  /// **'ASSISTANCE'**
  String get merchantMoreSectionSupport;

  /// No description provided for @merchantMoreLegalPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get merchantMoreLegalPrivacy;

  /// No description provided for @merchantMoreLegalTerms.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get merchantMoreLegalTerms;

  /// No description provided for @merchantMoreWhatsappSupport.
  ///
  /// In fr, this message translates to:
  /// **'Support WhatsApp'**
  String get merchantMoreWhatsappSupport;

  /// No description provided for @merchantSignOutConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get merchantSignOutConfirmTitle;

  /// No description provided for @merchantSignOutConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous devrez vous reconnecter pour accéder à votre espace commerçant.'**
  String get merchantSignOutConfirmMessage;

  /// No description provided for @merchantSignOutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get merchantSignOutConfirm;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get changePasswordConfirmLabel;

  /// No description provided for @merchantAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte & Profil'**
  String get merchantAccountTitle;

  /// No description provided for @merchantAccountProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get merchantAccountProfile;

  /// No description provided for @merchantSubscriptionCategoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement & Équipe'**
  String get merchantSubscriptionCategoryTitle;

  /// No description provided for @merchantSubscriptionMyPlan.
  ///
  /// In fr, this message translates to:
  /// **'Mon Abonnement'**
  String get merchantSubscriptionMyPlan;

  /// No description provided for @merchantSubscriptionTeamMembers.
  ///
  /// In fr, this message translates to:
  /// **'Membres de l\'équipe'**
  String get merchantSubscriptionTeamMembers;

  /// No description provided for @merchantNotifUpdateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour cette préférence. Réessayez.'**
  String get merchantNotifUpdateError;

  /// No description provided for @merchantNotifNewClientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau client'**
  String get merchantNotifNewClientTitle;

  /// No description provided for @merchantNotifNewClientSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Notif. à chaque inscription'**
  String get merchantNotifNewClientSubtitle;

  /// No description provided for @merchantNotifRewardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récompense gagnée'**
  String get merchantNotifRewardTitle;

  /// No description provided for @merchantNotifRewardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quand un palier est atteint'**
  String get merchantNotifRewardSubtitle;

  /// No description provided for @merchantNotifLowSmsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quota SMS faible'**
  String get merchantNotifLowSmsTitle;

  /// No description provided for @merchantNotifLowSmsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sous 20 SMS restants'**
  String get merchantNotifLowSmsSubtitle;

  /// No description provided for @merchantNotifWeeklyReportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport hebdomadaire'**
  String get merchantNotifWeeklyReportTitle;

  /// No description provided for @merchantNotifWeeklyReportSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tous les lundis matin'**
  String get merchantNotifWeeklyReportSubtitle;

  /// No description provided for @merchantNotifPromotionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Promotions Miva-Fid'**
  String get merchantNotifPromotionsTitle;

  /// No description provided for @merchantNotifPromotionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Offres et nouveautés'**
  String get merchantNotifPromotionsSubtitle;

  /// No description provided for @merchantTeamInviteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inviter un membre'**
  String get merchantTeamInviteTitle;

  /// No description provided for @merchantTeamNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get merchantTeamNameLabel;

  /// No description provided for @merchantTeamPhoneOptionalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (optionnel)'**
  String get merchantTeamPhoneOptionalLabel;

  /// No description provided for @merchantTeamPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get merchantTeamPasswordLabel;

  /// No description provided for @merchantTeamRoleOperator.
  ///
  /// In fr, this message translates to:
  /// **'Opérateur'**
  String get merchantTeamRoleOperator;

  /// No description provided for @merchantTeamRoleAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get merchantTeamRoleAdmin;

  /// No description provided for @merchantTeamInviteButton.
  ///
  /// In fr, this message translates to:
  /// **'Inviter'**
  String get merchantTeamInviteButton;

  /// No description provided for @merchantTeamInviteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'inviter ce membre.'**
  String get merchantTeamInviteError;

  /// No description provided for @merchantTeamEmptyState.
  ///
  /// In fr, this message translates to:
  /// **'Aucun membre d\'équipe. Invitez votre premier opérateur.'**
  String get merchantTeamEmptyState;

  /// No description provided for @merchantTeamToggleStatusError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier le statut de ce membre.'**
  String get merchantTeamToggleStatusError;

  /// No description provided for @merchantTierSilver.
  ///
  /// In fr, this message translates to:
  /// **'Argent'**
  String get merchantTierSilver;

  /// No description provided for @merchantTierGold.
  ///
  /// In fr, this message translates to:
  /// **'Or'**
  String get merchantTierGold;

  /// No description provided for @merchantTierPlatinum.
  ///
  /// In fr, this message translates to:
  /// **'Platine'**
  String get merchantTierPlatinum;

  /// No description provided for @merchantDashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get merchantDashboardTitle;

  /// No description provided for @merchantDashboardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de votre activité — juin 2026'**
  String get merchantDashboardSubtitle;

  /// No description provided for @merchantDashboardStampsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tampons'**
  String get merchantDashboardStampsLabel;

  /// No description provided for @merchantDashboardThisMonthLabel.
  ///
  /// In fr, this message translates to:
  /// **'ce mois'**
  String get merchantDashboardThisMonthLabel;

  /// No description provided for @merchantDashboardRewardsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Récomp.'**
  String get merchantDashboardRewardsLabel;

  /// No description provided for @merchantDashboardUsedLabel.
  ///
  /// In fr, this message translates to:
  /// **'utilisées'**
  String get merchantDashboardUsedLabel;

  /// No description provided for @merchantDashboardMonthActivityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Activité du mois'**
  String get merchantDashboardMonthActivityTitle;

  /// No description provided for @merchantDashboardValidationsPerWeekSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Validations par semaine'**
  String get merchantDashboardValidationsPerWeekSubtitle;

  /// No description provided for @merchantDashboardWeekLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sem {number}'**
  String merchantDashboardWeekLabel(String number);

  /// No description provided for @merchantDashboardVipDistributionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Répartition VIP'**
  String get merchantDashboardVipDistributionTitle;

  /// No description provided for @merchantDashboardClientsByTierSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos clients par niveau'**
  String get merchantDashboardClientsByTierSubtitle;

  /// No description provided for @merchantClientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes clients'**
  String get merchantClientsTitle;

  /// No description provided for @merchantClientsActiveCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} clients actifs'**
  String merchantClientsActiveCount(String count);

  /// No description provided for @merchantClientsAddSoonToast.
  ///
  /// In fr, this message translates to:
  /// **'Ajout manuel d\'un client bientôt disponible.'**
  String get merchantClientsAddSoonToast;

  /// No description provided for @merchantClientsExportToast.
  ///
  /// In fr, this message translates to:
  /// **'Exportation de la liste clients au format CSV lancée !'**
  String get merchantClientsExportToast;

  /// No description provided for @merchantClientsExportButton.
  ///
  /// In fr, this message translates to:
  /// **'Exporter la liste'**
  String get merchantClientsExportButton;

  /// No description provided for @merchantClientsSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un client...'**
  String get merchantClientsSearchHint;

  /// No description provided for @merchantClientsFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get merchantClientsFilterAll;

  /// No description provided for @merchantClientsFilterInactive30d.
  ///
  /// In fr, this message translates to:
  /// **'+30j'**
  String get merchantClientsFilterInactive30d;

  /// No description provided for @merchantClientsPaginationInfo.
  ///
  /// In fr, this message translates to:
  /// **'{from}-{to} sur {total}'**
  String merchantClientsPaginationInfo(String from, String to, String total);

  /// No description provided for @merchantClientsPrevious.
  ///
  /// In fr, this message translates to:
  /// **'< Préc.'**
  String get merchantClientsPrevious;

  /// No description provided for @merchantClientsNext.
  ///
  /// In fr, this message translates to:
  /// **'Suiv. >'**
  String get merchantClientsNext;

  /// No description provided for @merchantClientDetailRemoveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du programme ?'**
  String get merchantClientDetailRemoveTitle;

  /// No description provided for @merchantClientDetailRemoveMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir retirer {name} de votre programme de fidélité ? Ses tampons seront réinitialisés.'**
  String merchantClientDetailRemoveMessage(String name);

  /// No description provided for @merchantClientDetailRemoveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get merchantClientDetailRemoveConfirm;

  /// No description provided for @merchantClientDetailRemoveToast.
  ///
  /// In fr, this message translates to:
  /// **'Client retiré du programme.'**
  String get merchantClientDetailRemoveToast;

  /// No description provided for @merchantClientDetailSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Fiche client'**
  String get merchantClientDetailSubtitle;

  /// No description provided for @merchantClientDetailProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get merchantClientDetailProgress;

  /// No description provided for @merchantClientDetailSendSms.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un SMS'**
  String get merchantClientDetailSendSms;

  /// No description provided for @merchantClientDetailCall.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get merchantClientDetailCall;

  /// No description provided for @merchantClientDetailRewardsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Récompenses'**
  String get merchantClientDetailRewardsLabel;

  /// No description provided for @merchantClientDetailLastLabel.
  ///
  /// In fr, this message translates to:
  /// **'Dernière'**
  String get merchantClientDetailLastLabel;

  /// No description provided for @merchantClientDetailHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get merchantClientDetailHistoryTitle;

  /// No description provided for @merchantClientDetailHistoryStampValidated.
  ///
  /// In fr, this message translates to:
  /// **'Tampon validé'**
  String get merchantClientDetailHistoryStampValidated;

  /// No description provided for @merchantClientDetailHistoryRewardUsed.
  ///
  /// In fr, this message translates to:
  /// **'Récompense utilisée'**
  String get merchantClientDetailHistoryRewardUsed;

  /// No description provided for @merchantClientDetailHistoryEnrolled.
  ///
  /// In fr, this message translates to:
  /// **'Inscription au programme'**
  String get merchantClientDetailHistoryEnrolled;

  /// No description provided for @merchantClientDetailRemoveButton.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du programme'**
  String get merchantClientDetailRemoveButton;

  /// No description provided for @merchantValidateQrInvalid.
  ///
  /// In fr, this message translates to:
  /// **'QR code invalide ou illisible.'**
  String get merchantValidateQrInvalid;

  /// No description provided for @merchantValidateNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre réseau.'**
  String get merchantValidateNetworkError;

  /// No description provided for @merchantValidateNoCardFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte de fidélité trouvée pour ce commerce.'**
  String get merchantValidateNoCardFound;

  /// No description provided for @merchantValidateNoRewardFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune récompense de votre commerce ne correspond à ce code.'**
  String get merchantValidateNoRewardFound;

  /// No description provided for @merchantValidateRewardSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Récompense validée avec succès !'**
  String get merchantValidateRewardSuccess;

  /// No description provided for @merchantValidateRewardError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la validation.'**
  String get merchantValidateRewardError;

  /// No description provided for @merchantValidateFailedRetry.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la validation. Réessayez.'**
  String get merchantValidateFailedRetry;

  /// No description provided for @merchantValidateDefaultClientName.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get merchantValidateDefaultClientName;

  /// No description provided for @merchantValidateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Valider une visite'**
  String get merchantValidateTitle;

  /// No description provided for @merchantValidateSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Scannez ou saisissez l\'identifiant'**
  String get merchantValidateSubtitle;

  /// No description provided for @merchantValidateTabScanner.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get merchantValidateTabScanner;

  /// No description provided for @merchantValidateTabPhone.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant'**
  String get merchantValidateTabPhone;

  /// No description provided for @merchantValidateScanInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Pointez la caméra vers le QR du client'**
  String get merchantValidateScanInstruction;

  /// No description provided for @merchantValidateDisableCamera.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la caméra'**
  String get merchantValidateDisableCamera;

  /// No description provided for @merchantValidateEnableCamera.
  ///
  /// In fr, this message translates to:
  /// **'Activer la caméra'**
  String get merchantValidateEnableCamera;

  /// No description provided for @merchantValidateManualSearchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche par identifiant'**
  String get merchantValidateManualSearchTitle;

  /// No description provided for @merchantValidateManualSearchSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez l\'identifiant du client pour valider sa visite.'**
  String get merchantValidateManualSearchSubtitle;

  /// No description provided for @merchantValidateManualSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant du client'**
  String get merchantValidateManualSearchHint;

  /// No description provided for @merchantValidateSearchButton.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher le client'**
  String get merchantValidateSearchButton;

  /// No description provided for @merchantSmsCampaignSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Campagnes & messages'**
  String get merchantSmsCampaignSubtitle;

  /// No description provided for @merchantSmsCampaignSentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Envoyées'**
  String get merchantSmsCampaignSentLabel;

  /// No description provided for @merchantSmsCampaignOpenRateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ouverture'**
  String get merchantSmsCampaignOpenRateLabel;

  /// No description provided for @merchantSmsCampaignReachedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Atteints'**
  String get merchantSmsCampaignReachedLabel;

  /// No description provided for @merchantSmsCampaignCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} campagnes'**
  String merchantSmsCampaignCount(String count);

  /// No description provided for @merchantSmsCampaignDetailSentBadge.
  ///
  /// In fr, this message translates to:
  /// **'Envoyée'**
  String get merchantSmsCampaignDetailSentBadge;

  /// No description provided for @merchantSmsCampaignDetailRecipients.
  ///
  /// In fr, this message translates to:
  /// **'Destinataires'**
  String get merchantSmsCampaignDetailRecipients;

  /// No description provided for @merchantSmsCampaignDetailSent.
  ///
  /// In fr, this message translates to:
  /// **'Envoyés'**
  String get merchantSmsCampaignDetailSent;

  /// No description provided for @merchantSmsCampaignDetailOpened.
  ///
  /// In fr, this message translates to:
  /// **'Ouverts'**
  String get merchantSmsCampaignDetailOpened;

  /// No description provided for @merchantSmsCampaignDetailOpenRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'ouverture'**
  String get merchantSmsCampaignDetailOpenRate;

  /// No description provided for @merchantSmsCampaignDetailMessageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Message envoyé'**
  String get merchantSmsCampaignDetailMessageTitle;

  /// No description provided for @merchantSmsCampaignDetailDuplicateToast.
  ///
  /// In fr, this message translates to:
  /// **'Campagne dupliquée dans un nouveau brouillon !'**
  String get merchantSmsCampaignDetailDuplicateToast;

  /// No description provided for @merchantSmsCampaignDetailDuplicateButton.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer cette campagne'**
  String get merchantSmsCampaignDetailDuplicateButton;

  /// No description provided for @merchantSmsConversationSentToast.
  ///
  /// In fr, this message translates to:
  /// **'SMS envoyé avec succès !'**
  String get merchantSmsConversationSentToast;

  /// No description provided for @merchantSmsConversationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Conversation SMS'**
  String get merchantSmsConversationLabel;

  /// No description provided for @merchantSmsConversationInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Écrire un message...'**
  String get merchantSmsConversationInputHint;

  /// No description provided for @merchantProfileLogoSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Logo mis à jour avec succès'**
  String get merchantProfileLogoSuccess;

  /// No description provided for @merchantProfileLogoError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour le logo.'**
  String get merchantProfileLogoError;

  /// No description provided for @merchantProfileSaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Modifications enregistrées !'**
  String get merchantProfileSaveSuccess;

  /// No description provided for @merchantProfileLogoHint.
  ///
  /// In fr, this message translates to:
  /// **'PNG ou JPG, carré, max 2 Mo.'**
  String get merchantProfileLogoHint;

  /// No description provided for @merchantProfileLoadingEllipsis.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get merchantProfileLoadingEllipsis;

  /// No description provided for @merchantProfileChangeLink.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get merchantProfileChangeLink;

  /// No description provided for @merchantProfileSectionInfo.
  ///
  /// In fr, this message translates to:
  /// **'INFORMATIONS'**
  String get merchantProfileSectionInfo;

  /// No description provided for @merchantProfileBusinessNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'NOM DU COMMERCE'**
  String get merchantProfileBusinessNameLabel;

  /// No description provided for @merchantProfileCategoryLabel.
  ///
  /// In fr, this message translates to:
  /// **'CATÉGORIE'**
  String get merchantProfileCategoryLabel;

  /// No description provided for @merchantProfileDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'DESCRIPTION'**
  String get merchantProfileDescriptionLabel;

  /// No description provided for @merchantProfileCharCount.
  ///
  /// In fr, this message translates to:
  /// **'{count}/200 caractères'**
  String merchantProfileCharCount(String count);

  /// No description provided for @merchantProfileSectionContact.
  ///
  /// In fr, this message translates to:
  /// **'CONTACT'**
  String get merchantProfileSectionContact;

  /// No description provided for @merchantProfileEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'EMAIL'**
  String get merchantProfileEmailLabel;

  /// No description provided for @merchantProfilePhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'TÉLÉPHONE'**
  String get merchantProfilePhoneLabel;

  /// No description provided for @merchantProfileWhatsappLabel.
  ///
  /// In fr, this message translates to:
  /// **'WHATSAPP'**
  String get merchantProfileWhatsappLabel;

  /// No description provided for @merchantProfileSectionAddress.
  ///
  /// In fr, this message translates to:
  /// **'ADRESSE'**
  String get merchantProfileSectionAddress;

  /// No description provided for @merchantProfileCityLabel.
  ///
  /// In fr, this message translates to:
  /// **'VILLE'**
  String get merchantProfileCityLabel;

  /// No description provided for @merchantProfileAddressLabel.
  ///
  /// In fr, this message translates to:
  /// **'ADRESSE / QUARTIER'**
  String get merchantProfileAddressLabel;

  /// No description provided for @merchantProfileSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get merchantProfileSaveButton;

  /// No description provided for @merchantVitrineLogoUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le logo. Réessayez.'**
  String get merchantVitrineLogoUploadError;

  /// No description provided for @merchantVitrineLogoRemoveError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer le logo. Réessayez.'**
  String get merchantVitrineLogoRemoveError;

  /// No description provided for @merchantVitrineSaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Vitrine mise à jour avec succès'**
  String get merchantVitrineSaveSuccess;

  /// No description provided for @merchantVitrineSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String merchantVitrineSaveError(String error);

  /// No description provided for @merchantVitrinePreviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu public'**
  String get merchantVitrinePreviewTitle;

  /// No description provided for @merchantVitrineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma Vitrine'**
  String get merchantVitrineTitle;

  /// No description provided for @merchantVitrineSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Page publique de votre commerce'**
  String get merchantVitrineSubtitle;

  /// No description provided for @merchantVitrinePreviewButton.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get merchantVitrinePreviewButton;

  /// No description provided for @merchantVitrineCoverPhotoSection.
  ///
  /// In fr, this message translates to:
  /// **'Photo de couverture'**
  String get merchantVitrineCoverPhotoSection;

  /// No description provided for @merchantVitrineInfoSection.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get merchantVitrineInfoSection;

  /// No description provided for @merchantVitrineDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Description...'**
  String get merchantVitrineDescriptionHint;

  /// No description provided for @merchantVitrineContactAddressSection.
  ///
  /// In fr, this message translates to:
  /// **'Contact & adresse'**
  String get merchantVitrineContactAddressSection;

  /// No description provided for @merchantVitrineHoursSection.
  ///
  /// In fr, this message translates to:
  /// **'Horaires'**
  String get merchantVitrineHoursSection;

  /// No description provided for @merchantVitrineDayMonday.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get merchantVitrineDayMonday;

  /// No description provided for @merchantVitrineDayTuesday.
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get merchantVitrineDayTuesday;

  /// No description provided for @merchantVitrineDayWednesday.
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get merchantVitrineDayWednesday;

  /// No description provided for @merchantVitrineDayThursday.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get merchantVitrineDayThursday;

  /// No description provided for @merchantVitrineDayFriday.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get merchantVitrineDayFriday;

  /// No description provided for @merchantVitrineDaySaturday.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get merchantVitrineDaySaturday;

  /// No description provided for @merchantVitrineDaySunday.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get merchantVitrineDaySunday;

  /// No description provided for @merchantVitrineClosedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get merchantVitrineClosedLabel;

  /// No description provided for @merchantVitrinePublishButton.
  ///
  /// In fr, this message translates to:
  /// **'Publier les modifications'**
  String get merchantVitrinePublishButton;

  /// No description provided for @merchantVitrineAddPhotoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get merchantVitrineAddPhotoLabel;

  /// No description provided for @merchantSubscriptionPlanStarterName.
  ///
  /// In fr, this message translates to:
  /// **'Démarrage'**
  String get merchantSubscriptionPlanStarterName;

  /// No description provided for @merchantSubscriptionPlanBusinessName.
  ///
  /// In fr, this message translates to:
  /// **'Business'**
  String get merchantSubscriptionPlanBusinessName;

  /// No description provided for @merchantSubscriptionNextInvoiceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine facture'**
  String get merchantSubscriptionNextInvoiceLabel;

  /// No description provided for @merchantSubscriptionCurrentBadge.
  ///
  /// In fr, this message translates to:
  /// **'ACTUEL'**
  String get merchantSubscriptionCurrentBadge;

  /// No description provided for @merchantSubscriptionChooseButton.
  ///
  /// In fr, this message translates to:
  /// **'Choisir'**
  String get merchantSubscriptionChooseButton;

  /// No description provided for @merchantSubscriptionPlanChangedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement modifié : plan {plan} sélectionné'**
  String merchantSubscriptionPlanChangedSuccess(String plan);

  /// No description provided for @merchantSubscriptionPlanChangeError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du changement de plan : {error}'**
  String merchantSubscriptionPlanChangeError(String error);

  /// No description provided for @merchantQrCodeLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get merchantQrCodeLoadError;

  /// No description provided for @merchantQrCodeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Affichez-le pour que les clients scannent'**
  String get merchantQrCodeSubtitle;

  /// No description provided for @merchantQrCodeScanToEarnLabel.
  ///
  /// In fr, this message translates to:
  /// **'Scannez pour gagner un tampon'**
  String get merchantQrCodeScanToEarnLabel;

  /// No description provided for @merchantQrCodePngSavedToast.
  ///
  /// In fr, this message translates to:
  /// **'Image enregistrée dans la galerie !'**
  String get merchantQrCodePngSavedToast;

  /// No description provided for @merchantQrCodeShareButton.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get merchantQrCodeShareButton;

  /// No description provided for @merchantQrCodeUniqueCodeSection.
  ///
  /// In fr, this message translates to:
  /// **'CODE UNIQUE'**
  String get merchantQrCodeUniqueCodeSection;

  /// No description provided for @merchantQrCodeCodeCopiedToast.
  ///
  /// In fr, this message translates to:
  /// **'Code copié dans le presse-papiers !'**
  String get merchantQrCodeCodeCopiedToast;

  /// No description provided for @merchantQrCodeThisWeekLabel.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get merchantQrCodeThisWeekLabel;

  /// No description provided for @merchantQrCodeThisMonthLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get merchantQrCodeThisMonthLabel;

  /// No description provided for @merchantQrCodeNewLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux'**
  String get merchantQrCodeNewLabel;

  /// No description provided for @merchantQrCodeTipLabel.
  ///
  /// In fr, this message translates to:
  /// **'Astuce'**
  String get merchantQrCodeTipLabel;

  /// No description provided for @merchantQrCodeTipMessage.
  ///
  /// In fr, this message translates to:
  /// **'Placez le QR à la caisse ou sur les tables pour maximiser les scans.'**
  String get merchantQrCodeTipMessage;

  /// No description provided for @merchantQrCodePdfScanMessage.
  ///
  /// In fr, this message translates to:
  /// **'Scannez pour cumuler vos points !'**
  String get merchantQrCodePdfScanMessage;

  /// No description provided for @merchantQrCodePdfPoweredBy.
  ///
  /// In fr, this message translates to:
  /// **'Powered by Miva-Fid'**
  String get merchantQrCodePdfPoweredBy;

  /// No description provided for @merchantQrCodeWhatsappShareMessage.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez mon programme de fidélité Miva-Fid chez {name} !'**
  String merchantQrCodeWhatsappShareMessage(String name);

  /// No description provided for @merchantProgrammeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fidélisation'**
  String get merchantProgrammeTitle;

  /// No description provided for @merchantProgrammeCardPreviewLabel.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de la carte'**
  String get merchantProgrammeCardPreviewLabel;

  /// No description provided for @merchantProgrammeConfigTitle.
  ///
  /// In fr, this message translates to:
  /// **'Configuration'**
  String get merchantProgrammeConfigTitle;

  /// No description provided for @merchantProgrammeConfigSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérez les détails de votre programme de fidélité'**
  String get merchantProgrammeConfigSubtitle;

  /// No description provided for @merchantProgrammeAppearanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Apparence de la carte'**
  String get merchantProgrammeAppearanceTitle;

  /// No description provided for @merchantProgrammeAppearanceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisez les couleurs et le style'**
  String get merchantProgrammeAppearanceSubtitle;

  /// No description provided for @merchantProgrammeTiersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paliers de fidélité'**
  String get merchantProgrammeTiersTitle;

  /// No description provided for @merchantProgrammeTiersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs, niveaux et récompenses de votre programme'**
  String get merchantProgrammeTiersSubtitle;

  /// No description provided for @merchantProgrammeRulesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Règles d\'accumulation'**
  String get merchantProgrammeRulesTitle;

  /// No description provided for @merchantProgrammeRulesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Configuration du ratio (ex: 1 point = 500 FCFA)'**
  String get merchantProgrammeRulesSubtitle;

  /// No description provided for @merchantProgrammeLoopTitle.
  ///
  /// In fr, this message translates to:
  /// **'Programme en boucle'**
  String get merchantProgrammeLoopTitle;

  /// No description provided for @merchantProgrammeLoopEnabledSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Dernier palier atteint : nouveau cycle automatique.'**
  String get merchantProgrammeLoopEnabledSubtitle;

  /// No description provided for @merchantProgrammeLoopDisabledSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Dernier palier atteint : carte terminée définitivement.'**
  String get merchantProgrammeLoopDisabledSubtitle;

  /// No description provided for @merchantProgrammeTiersLoadingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paliers'**
  String get merchantProgrammeTiersLoadingTitle;

  /// No description provided for @merchantProgrammeGoalUnitPoints.
  ///
  /// In fr, this message translates to:
  /// **'points / FCFA'**
  String get merchantProgrammeGoalUnitPoints;

  /// No description provided for @merchantProgrammeGoalUnitCashback.
  ///
  /// In fr, this message translates to:
  /// **'FCFA de cashback cumulés'**
  String get merchantProgrammeGoalUnitCashback;

  /// No description provided for @merchantProgrammeGoalUnitStamps.
  ///
  /// In fr, this message translates to:
  /// **'tampons'**
  String get merchantProgrammeGoalUnitStamps;

  /// No description provided for @merchantProgrammeTiersSaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Paliers mis à jour avec succès'**
  String get merchantProgrammeTiersSaveSuccess;

  /// No description provided for @merchantProgrammeTiersSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String merchantProgrammeTiersSaveError(String error);

  /// No description provided for @merchantProgrammeAddTierButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un palier'**
  String get merchantProgrammeAddTierButton;

  /// No description provided for @merchantProgrammeRulesNotApplicable.
  ///
  /// In fr, this message translates to:
  /// **'Votre programme est configuré en mode \"{mode}\".\n\nAucune règle de conversion FCFA -> Points n\'est requise.'**
  String merchantProgrammeRulesNotApplicable(String mode);

  /// No description provided for @merchantProgrammeRulesSaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Règle de conversion mise à jour avec succès'**
  String get merchantProgrammeRulesSaveSuccess;

  /// No description provided for @merchantProgrammeRulesSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String merchantProgrammeRulesSaveError(String error);

  /// No description provided for @merchantProgrammeRulesConversionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Conversion FCFA -> Points'**
  String get merchantProgrammeRulesConversionLabel;

  /// No description provided for @merchantProgrammeRulesConversionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Définissez combien le client doit dépenser pour gagner 1 point.'**
  String get merchantProgrammeRulesConversionSubtitle;

  /// No description provided for @merchantProgrammeRulesInputLabel.
  ///
  /// In fr, this message translates to:
  /// **'1 point tous les combien de FCFA ? *'**
  String get merchantProgrammeRulesInputLabel;

  /// No description provided for @merchantProgrammeRulesInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 500'**
  String get merchantProgrammeRulesInputHint;

  /// No description provided for @merchantProgrammeRulesValidatorError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nombre supérieur à 0'**
  String get merchantProgrammeRulesValidatorError;

  /// No description provided for @merchantProgrammeDesignLogoRemovedToast.
  ///
  /// In fr, this message translates to:
  /// **'Logo supprimé'**
  String get merchantProgrammeDesignLogoRemovedToast;

  /// No description provided for @merchantProgrammeDesignSaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Design mis à jour avec succès'**
  String get merchantProgrammeDesignSaveSuccess;

  /// No description provided for @merchantProgrammeDesignSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String merchantProgrammeDesignSaveError(String error);

  /// No description provided for @merchantProgrammeDesignLoadingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get merchantProgrammeDesignLoadingTitle;

  /// No description provided for @merchantProgrammeDesignChooseIconTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une icône'**
  String get merchantProgrammeDesignChooseIconTitle;

  /// No description provided for @merchantProgrammeDesignChooseEmojiTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un emoji'**
  String get merchantProgrammeDesignChooseEmojiTitle;

  /// No description provided for @merchantProgrammeDesignLogoHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce logo apparaîtra sur votre carte de fidélité et sur vos profils.'**
  String get merchantProgrammeDesignLogoHint;

  /// No description provided for @merchantProgrammeDesignLogoPresent.
  ///
  /// In fr, this message translates to:
  /// **'Logo présent'**
  String get merchantProgrammeDesignLogoPresent;

  /// No description provided for @merchantProgrammeDesignNoLogo.
  ///
  /// In fr, this message translates to:
  /// **'Aucun logo'**
  String get merchantProgrammeDesignNoLogo;

  /// No description provided for @merchantProgrammeDesignSquareFormatHint.
  ///
  /// In fr, this message translates to:
  /// **'Format carré recommandé'**
  String get merchantProgrammeDesignSquareFormatHint;

  /// No description provided for @merchantProgrammeDesignAddButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get merchantProgrammeDesignAddButton;

  /// No description provided for @merchantProgrammeDesignRemoveTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get merchantProgrammeDesignRemoveTooltip;

  /// No description provided for @merchantProgrammeDesignPrimaryColorLabel.
  ///
  /// In fr, this message translates to:
  /// **'Couleur principale'**
  String get merchantProgrammeDesignPrimaryColorLabel;

  /// No description provided for @merchantProgrammeDesignColorHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la couleur dominante de votre carte de fidélité.'**
  String get merchantProgrammeDesignColorHint;

  /// No description provided for @merchantProgrammeDesignPatternLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif de fond'**
  String get merchantProgrammeDesignPatternLabel;

  /// No description provided for @merchantProgrammeDesignPatternNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get merchantProgrammeDesignPatternNone;

  /// No description provided for @merchantProgrammeDesignPatternLines.
  ///
  /// In fr, this message translates to:
  /// **'Traits'**
  String get merchantProgrammeDesignPatternLines;

  /// No description provided for @merchantProgrammeDesignPatternWaves.
  ///
  /// In fr, this message translates to:
  /// **'Vagues'**
  String get merchantProgrammeDesignPatternWaves;

  /// No description provided for @merchantProgrammeDesignPatternDots.
  ///
  /// In fr, this message translates to:
  /// **'Points'**
  String get merchantProgrammeDesignPatternDots;

  /// No description provided for @merchantProgrammeDesignStampStyleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Style des tampons'**
  String get merchantProgrammeDesignStampStyleLabel;

  /// No description provided for @merchantProgrammeDesignStampTypeIcon.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get merchantProgrammeDesignStampTypeIcon;

  /// No description provided for @merchantProgrammeDesignStampTypeEmoji.
  ///
  /// In fr, this message translates to:
  /// **'Emoji'**
  String get merchantProgrammeDesignStampTypeEmoji;

  /// No description provided for @merchantProgrammeDesignIconSelectedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Icône sélectionnée'**
  String get merchantProgrammeDesignIconSelectedLabel;

  /// No description provided for @merchantProgrammeDesignEmojiSelectedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Emoji sélectionné'**
  String get merchantProgrammeDesignEmojiSelectedLabel;

  /// No description provided for @merchantProgrammeDesignSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le design'**
  String get merchantProgrammeDesignSaveButton;

  /// No description provided for @merchantPlanUpgradeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passez à Pro'**
  String get merchantPlanUpgradeTitle;

  /// No description provided for @merchantPlanUpgradeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Campagnes SMS illimitées, analytics avancés et support prioritaire.'**
  String get merchantPlanUpgradeSubtitle;

  /// No description provided for @merchantPlanUpgradeButton.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir Pro'**
  String get merchantPlanUpgradeButton;

  /// No description provided for @merchantPlanUpgradeToast.
  ///
  /// In fr, this message translates to:
  /// **'Offre Pro bientôt disponible'**
  String get merchantPlanUpgradeToast;

  /// No description provided for @merchantValidateRewardUnlockedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récompense débloquée !'**
  String get merchantValidateRewardUnlockedTitle;

  /// No description provided for @merchantValidateCashbackCreditedTitle.
  ///
  /// In fr, this message translates to:
  /// **'{amount} FCFA crédités à {name} !'**
  String merchantValidateCashbackCreditedTitle(String amount, String name);

  /// No description provided for @merchantValidateStampGrantedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tampon accordé à {name} !'**
  String merchantValidateStampGrantedTitle(String name);

  /// No description provided for @merchantValidatePointsGrantedTitle.
  ///
  /// In fr, this message translates to:
  /// **'{points} point(s) accordé(s) à {name} !'**
  String merchantValidatePointsGrantedTitle(String points, String name);

  /// No description provided for @merchantValidateRewardUnlockedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le client peut réclamer sa récompense dès maintenant.'**
  String get merchantValidateRewardUnlockedSubtitle;

  /// No description provided for @merchantValidateCashbackCreditedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Cashback crédité sur le solde du client.'**
  String get merchantValidateCashbackCreditedSubtitle;

  /// No description provided for @merchantValidateStampProgressSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{current} sur {goal} tampons'**
  String merchantValidateStampProgressSubtitle(String current, String goal);

  /// No description provided for @merchantValidatePointsProgressSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{current} sur {goal} points'**
  String merchantValidatePointsProgressSubtitle(String current, String goal);

  /// No description provided for @merchantValidateNextStepButton.
  ///
  /// In fr, this message translates to:
  /// **'Étape suivante'**
  String get merchantValidateNextStepButton;

  /// No description provided for @merchantValidateRewardStatusUsed.
  ///
  /// In fr, this message translates to:
  /// **'Déjà utilisée'**
  String get merchantValidateRewardStatusUsed;

  /// No description provided for @merchantValidateRewardStatusCanceled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get merchantValidateRewardStatusCanceled;

  /// No description provided for @merchantValidateRewardStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expirée'**
  String get merchantValidateRewardStatusExpired;

  /// No description provided for @merchantValidateRewardStatusAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get merchantValidateRewardStatusAvailable;

  /// No description provided for @merchantValidateRewardSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récompense'**
  String get merchantValidateRewardSheetTitle;

  /// No description provided for @merchantValidateRewardClientLabel.
  ///
  /// In fr, this message translates to:
  /// **'Client : {name}'**
  String merchantValidateRewardClientLabel(String name);

  /// No description provided for @merchantValidateRewardConfirmButton.
  ///
  /// In fr, this message translates to:
  /// **'Valider l\'utilisation'**
  String get merchantValidateRewardConfirmButton;

  /// No description provided for @merchantValidateRewardCancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler cette récompense'**
  String get merchantValidateRewardCancelButton;

  /// No description provided for @merchantValidateCardInactive.
  ///
  /// In fr, this message translates to:
  /// **'Carte inactive'**
  String get merchantValidateCardInactive;

  /// No description provided for @merchantValidateConfirmAndCredit.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer et créditer'**
  String get merchantValidateConfirmAndCredit;

  /// No description provided for @merchantValidateCreditCashback.
  ///
  /// In fr, this message translates to:
  /// **'Créditer le cashback'**
  String get merchantValidateCreditCashback;

  /// No description provided for @merchantValidateValidateStamp.
  ///
  /// In fr, this message translates to:
  /// **'Valider le tampon'**
  String get merchantValidateValidateStamp;

  /// No description provided for @merchantValidateCreditCashbackButton.
  ///
  /// In fr, this message translates to:
  /// **'Créditer du cashback'**
  String get merchantValidateCreditCashbackButton;

  /// No description provided for @merchantValidateRedeemCashbackButton.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser du cashback'**
  String get merchantValidateRedeemCashbackButton;

  /// No description provided for @merchantValidateNoCashbackBalance.
  ///
  /// In fr, this message translates to:
  /// **'Aucun solde cashback à utiliser pour ce client.'**
  String get merchantValidateNoCashbackBalance;

  /// No description provided for @merchantValidatePurchaseAmountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Montant de l\'achat'**
  String get merchantValidatePurchaseAmountLabel;

  /// No description provided for @merchantValidateCashbackCreditedHelper.
  ///
  /// In fr, this message translates to:
  /// **'{percent}% crédités en cashback'**
  String merchantValidateCashbackCreditedHelper(String percent);

  /// No description provided for @merchantValidateEnterAmountCashbackHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le montant pour voir le cashback crédité.'**
  String get merchantValidateEnterAmountCashbackHint;

  /// No description provided for @merchantValidateCashbackCreditedResult.
  ///
  /// In fr, this message translates to:
  /// **'= {amount} de cashback crédités'**
  String merchantValidateCashbackCreditedResult(String amount);

  /// No description provided for @merchantValidateCashbackToUseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Cashback à utiliser'**
  String get merchantValidateCashbackToUseLabel;

  /// No description provided for @merchantValidateAvailableBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde disponible : {amount}'**
  String merchantValidateAvailableBalance(String amount);

  /// No description provided for @merchantValidateAmountToPay.
  ///
  /// In fr, this message translates to:
  /// **'= {amount} à payer'**
  String merchantValidateAmountToPay(String amount);

  /// No description provided for @merchantValidateExceedsBalance.
  ///
  /// In fr, this message translates to:
  /// **'Dépasse le solde disponible.'**
  String get merchantValidateExceedsBalance;

  /// No description provided for @merchantValidateExceedsPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Ne peut pas dépasser le montant de l\'achat.'**
  String get merchantValidateExceedsPurchase;

  /// No description provided for @merchantValidateViewSummaryButton.
  ///
  /// In fr, this message translates to:
  /// **'Voir le résumé'**
  String get merchantValidateViewSummaryButton;

  /// No description provided for @merchantValidateSummaryPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Achat'**
  String get merchantValidateSummaryPurchase;

  /// No description provided for @merchantValidateSummaryCashbackUsed.
  ///
  /// In fr, this message translates to:
  /// **'Cashback utilisé'**
  String get merchantValidateSummaryCashbackUsed;

  /// No description provided for @merchantValidateSummaryToPay.
  ///
  /// In fr, this message translates to:
  /// **'À payer'**
  String get merchantValidateSummaryToPay;

  /// No description provided for @merchantValidateSummaryCashbackGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Cashback généré'**
  String get merchantValidateSummaryCashbackGenerated;

  /// No description provided for @merchantValidateSummaryNewBalance.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau solde'**
  String get merchantValidateSummaryNewBalance;

  /// No description provided for @merchantValidateConfirmUsageButton.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'utilisation'**
  String get merchantValidateConfirmUsageButton;

  /// No description provided for @merchantValidateInactiveBadge.
  ///
  /// In fr, this message translates to:
  /// **'Inactive'**
  String get merchantValidateInactiveBadge;

  /// No description provided for @merchantValidatePointsRatioHelper.
  ///
  /// In fr, this message translates to:
  /// **'1 point tous les {amount} FCFA d\'achat'**
  String merchantValidatePointsRatioHelper(String amount);

  /// No description provided for @merchantValidateEnterAmountPointsHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le montant pour voir les points crédités.'**
  String get merchantValidateEnterAmountPointsHint;

  /// No description provided for @merchantValidatePointsCreditedResult.
  ///
  /// In fr, this message translates to:
  /// **'= {points} point(s) crédité(s)'**
  String merchantValidatePointsCreditedResult(String points);

  /// No description provided for @merchantValidateCashbackLabel.
  ///
  /// In fr, this message translates to:
  /// **'CASHBACK'**
  String get merchantValidateCashbackLabel;

  /// No description provided for @merchantValidateAvailableBalanceLabel.
  ///
  /// In fr, this message translates to:
  /// **'solde disponible'**
  String get merchantValidateAvailableBalanceLabel;

  /// No description provided for @merchantValidatePurchasesLabel.
  ///
  /// In fr, this message translates to:
  /// **'ACHATS'**
  String get merchantValidatePurchasesLabel;

  /// No description provided for @merchantValidatePointsLabel.
  ///
  /// In fr, this message translates to:
  /// **'POINTS'**
  String get merchantValidatePointsLabel;

  /// No description provided for @merchantValidateSpendGoalLabel.
  ///
  /// In fr, this message translates to:
  /// **'sur {goal} pts (achats)'**
  String merchantValidateSpendGoalLabel(String goal);

  /// No description provided for @merchantValidatePointsGoalLabel.
  ///
  /// In fr, this message translates to:
  /// **'sur {goal} points'**
  String merchantValidatePointsGoalLabel(String goal);

  /// No description provided for @merchantTierEditorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos paliers'**
  String get merchantTierEditorTitle;

  /// No description provided for @merchantTierEditorCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} palier} other{{count} paliers}}'**
  String merchantTierEditorCount(int count);

  /// No description provided for @merchantTierEditorMultiTierHint.
  ///
  /// In fr, this message translates to:
  /// **'Chaque palier attribue un niveau nommé par vous et débloque sa propre récompense, sans jamais redescendre une fois atteint.'**
  String get merchantTierEditorMultiTierHint;

  /// No description provided for @merchantTierEditorEmptyState.
  ///
  /// In fr, this message translates to:
  /// **'Aucun palier configuré — le cashback fonctionne normalement sans palier.'**
  String get merchantTierEditorEmptyState;

  /// No description provided for @merchantTierEditorDefaultTierName.
  ///
  /// In fr, this message translates to:
  /// **'Palier {number}'**
  String merchantTierEditorDefaultTierName(String number);

  /// No description provided for @merchantTierEditorConfigurePrompt.
  ///
  /// In fr, this message translates to:
  /// **'Configurer ce palier'**
  String get merchantTierEditorConfigurePrompt;

  /// No description provided for @merchantTierEditorDeleteTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce palier'**
  String get merchantTierEditorDeleteTooltip;

  /// No description provided for @merchantTierEditorGoalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Objectif ({unit}) *'**
  String merchantTierEditorGoalLabel(String unit);

  /// No description provided for @merchantTierEditorGoalRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'objectif est obligatoire'**
  String get merchantTierEditorGoalRequired;

  /// No description provided for @merchantTierEditorMustExceedPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Doit être supérieur au palier précédent ({value})'**
  String merchantTierEditorMustExceedPrevious(String value);

  /// No description provided for @merchantTierEditorLevelNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du niveau *'**
  String get merchantTierEditorLevelNameLabel;

  /// No description provided for @merchantTierEditorLevelNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Découverte, Habitué, VIP'**
  String get merchantTierEditorLevelNameHint;

  /// No description provided for @merchantTierEditorLevelNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du niveau est obligatoire'**
  String get merchantTierEditorLevelNameRequired;

  /// No description provided for @merchantTierEditorRewardLabel.
  ///
  /// In fr, this message translates to:
  /// **'Récompense offerte *'**
  String get merchantTierEditorRewardLabel;

  /// No description provided for @merchantTierEditorRewardHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : 1 café offert, 10% de réduction'**
  String get merchantTierEditorRewardHint;

  /// No description provided for @merchantTierEditorRewardRequired.
  ///
  /// In fr, this message translates to:
  /// **'La description de la récompense est obligatoire'**
  String get merchantTierEditorRewardRequired;

  /// No description provided for @merchantTierEditorSurpriseRewardLabel.
  ///
  /// In fr, this message translates to:
  /// **'Récompense surprise 🎁'**
  String get merchantTierEditorSurpriseRewardLabel;

  /// No description provided for @merchantTierEditorSurpriseRewardHint.
  ///
  /// In fr, this message translates to:
  /// **'Cacher ce palier au client jusqu\'à ce qu\'il le débloque.'**
  String get merchantTierEditorSurpriseRewardHint;

  /// No description provided for @merchantTierEditorValidityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Validité (jours, optionnel)'**
  String get merchantTierEditorValidityLabel;

  /// No description provided for @merchantTierEditorValidityHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 30 — vide = pas d\'expiration'**
  String get merchantTierEditorValidityHint;

  /// No description provided for @merchantTierEditorValidityError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nombre de jours supérieur à 0'**
  String get merchantTierEditorValidityError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
