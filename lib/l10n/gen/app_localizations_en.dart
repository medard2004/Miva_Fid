// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navWallet => 'Wallet';

  @override
  String get navRewards => 'Rewards';

  @override
  String get navReferral => 'Referral';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDone => 'Done';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSubtitle => 'Manage alerts per establishment';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutConfirmTitle => 'Sign out';

  @override
  String get settingsSignOutConfirmMessage =>
      'Are you sure you want to sign out of your Carte account?';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEditProfile => 'Edit profile';

  @override
  String profileMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get profileCards => 'Cards';

  @override
  String get profileOffers => 'Offers';

  @override
  String get profileReferrals => 'Referrals';

  @override
  String get profileNotConnectedTitle => 'You\'re not signed in';

  @override
  String get profileNotConnectedMessage => 'Sign in to access your profile.';

  @override
  String get profileSignIn => 'Sign in';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileSettingsSubtitle => 'Appearance, language, notifications';

  @override
  String get profileReferralCode => 'Your invite code';

  @override
  String get profileReferralCodeCopied => 'Referral code copied to clipboard!';

  @override
  String get profileBirthdayBannerTitle => 'Happy birthday month!';

  @override
  String get profileBirthdayBannerMessage =>
      'Exclusive treats await you at your restaurants.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileFullName => 'Full name';

  @override
  String get editProfileFullNameHint => 'Kokou John';

  @override
  String get editProfileFullNameError => 'Please enter your full name';

  @override
  String get editProfilePhone => 'Phone number';

  @override
  String get editProfileBirthDate => 'Date of birth';

  @override
  String get editProfileEmail => 'Email';

  @override
  String get editProfileEmailHint => 'you@email.com';

  @override
  String get editProfileSaveSuccess => 'Profile updated successfully!';

  @override
  String get referralTitle => 'Referral';

  @override
  String get referralSubtitle =>
      'Recommend your favorite restaurants and earn points.';

  @override
  String get referralEmptyTitle => 'No card to refer';

  @override
  String get referralEmptyMessage =>
      'Join at least one establishment to recommend it to your friends.';

  @override
  String get referralPointsLabel => 'Referral points';

  @override
  String referralPointsEarned(int count) {
    return '$count points earned';
  }

  @override
  String referralSharesToNext(int count) {
    return '$count shares to go';
  }

  @override
  String get referralChoosePartner => 'Choose partner';

  @override
  String get referralRecipientHint => 'Phone or name';

  @override
  String get referralSendButton => 'Send invitation';

  @override
  String referralSendButtonWithCount(int count) {
    return 'Send invitation ($count)';
  }

  @override
  String get referralDuplicateRecipient =>
      'This recipient is already in your list.';

  @override
  String get referralNoRecipient =>
      'Please add at least one recipient before sending.';

  @override
  String referralSentSuccess(int count) {
    return '$count invitation(s) sent!';
  }

  @override
  String get referralHistoryTitle => 'Share history';

  @override
  String get referralHistoryEmpty => 'No shares yet.';

  @override
  String get referralMessageLabel => 'Your message';

  @override
  String get referralRecipientsLabel => 'Recipients';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptyMessage =>
      'You\'ll be notified here about your stamps, rewards and VIP status.';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonHistory => 'History';

  @override
  String get commonCountdownPrefix => 'D-';

  @override
  String get cardStampsLabel => 'STAMPS';

  @override
  String get cardPointsLabel => 'BALANCE';

  @override
  String get cardPointsSuffix => 'PTS';

  @override
  String get cardSpendLabel => 'PURCHASE GOAL';

  @override
  String get cardCashbackLabel => 'CASHBACK';

  @override
  String get cardCashbackSuffix => 'FCFA';

  @override
  String get cardVipMaxTier => 'Top tier reached';

  @override
  String cardVipNextTier(int count) {
    return 'Platinum in $count visits';
  }

  @override
  String get rewardsTitle => 'Rewards';

  @override
  String get rewardsEmptyActiveTitle => 'No perk available';

  @override
  String get rewardsEmptyActiveMessage => 'Check back soon for new offers.';

  @override
  String get rewardsToUnlock => 'To unlock';

  @override
  String get rewardsAllUnlockedTitle => 'Everything unlocked';

  @override
  String get rewardsAllUnlockedMessage => 'No locked reward at the moment.';

  @override
  String get rewardsHistoryEmptyTitle => 'No history';

  @override
  String get rewardsHistoryEmptyMessage =>
      'Your used rewards will appear here.';

  @override
  String get rewardsRedeemConfirmTitle => 'Use this reward?';

  @override
  String rewardsRedeemConfirmMessage(String title) {
    return '\"$title\" will be marked as used and removed from your active perks. Show this screen to the establishment before confirming.';
  }

  @override
  String get rewardsRedeemSuccess => 'Reward marked as used';

  @override
  String get rewardsUseButton => 'Use';

  @override
  String get rewardsShowQrInstruction =>
      'Show this code to the merchant to use it. Valid once only.';

  @override
  String get walletGreetingMorning => 'GOOD MORNING';

  @override
  String get walletGreetingAfternoon => 'GOOD AFTERNOON';

  @override
  String get walletGreetingEvening => 'GOOD EVENING';

  @override
  String get walletFallbackName => 'there';

  @override
  String get walletSearchSemanticLabel => 'Search a card';

  @override
  String get walletSearchHint => 'Search a card or a merchant';

  @override
  String get walletSearchNoResultsTitle => 'No card found';

  @override
  String get walletSearchNoResultsMessage => 'Try another name or merchant.';

  @override
  String get walletEmptyTitle => 'No card yet';

  @override
  String get walletEmptyMessage =>
      'Scan your first QR code to start your collection.';

  @override
  String get walletScanButton => 'Scan a QR code';

  @override
  String get cardDetailNotFound => 'Card not found';

  @override
  String get cardDetailTitle => 'Your card';

  @override
  String get cardDetailExportTooltip => 'Export / Share';

  @override
  String get cardDetailDefaultOfferRestaurant => 'Offer';

  @override
  String get cardDetailDefaultOfferTitle => 'Reward coming soon';

  @override
  String get cardDetailDefaultOfferMessage =>
      'Keep earning to unlock your next perk.';

  @override
  String get cardDetailExportSheetTitle => 'Export';

  @override
  String get cardDetailSaveTitle => 'Save the card';

  @override
  String get cardDetailSaveSubtitle => 'Keep it in your app Wallet';

  @override
  String get cardDetailDownloadTitle => 'Download the card';

  @override
  String get cardDetailDownloadSubtitle =>
      'Save an HD visual to your gallery (Pass format)';

  @override
  String get cardDetailShareTitle => 'Share the card';

  @override
  String get cardDetailShareSubtitle =>
      'Generate and send a clean version to a friend';

  @override
  String get cardDetailFullScreen => 'Full screen';

  @override
  String get cardDetailIdCopied => 'ID copied';

  @override
  String get cardDetailQrInstructions => 'Show this QR code at checkout';

  @override
  String cardDetailVisitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count VISITS',
      one: '$count VISIT',
    );
    return '$_temp0';
  }

  @override
  String get rewardStatusReady => 'READY';

  @override
  String get rewardStatusLocked => 'LOCKED';

  @override
  String get rewardStatusUsed => 'USED';

  @override
  String get rewardStatusExpired => 'EXPIRED';

  @override
  String get rewardExpirationDate => 'Expires on';

  @override
  String get rewardUsedDate => 'Used on';

  @override
  String get rewardQrInstructions2 => 'Show this QR Code to use your reward';

  @override
  String get historyStampEntry => '+1 stamp · Checkout visit';

  @override
  String historyPointsEntry(int points) {
    return '+$points points · Checkout visit';
  }

  @override
  String historyCashbackEntry(int amount) {
    return '+$amount FCFA · Checkout visit';
  }

  @override
  String get historyVisitEntry => 'Visit recorded';

  @override
  String get historySignupEntry => 'Joined the card';

  @override
  String historyCashbackRedeemEntry(int amount) {
    return '-$amount FCFA · Cashback used';
  }

  @override
  String get cardDetailHistoryEmpty => 'No activity yet.';

  @override
  String get exportFailedRetry => 'Export failed: please try again.';

  @override
  String exportShareSubject(String name) {
    return 'My $name card — Carte';
  }

  @override
  String exportShareText(String name) {
    return 'Check out $name on Carte!';
  }

  @override
  String exportDownloadReady(String id) {
    return 'HD image of card $id ready — choose \"Save image\".';
  }

  @override
  String exportShareSuccess(String name) {
    return '$name card visual shared.';
  }

  @override
  String exportSaveReady(String name) {
    return '\"$name\" card ready to be saved.';
  }

  @override
  String get exportFailedGeneric => 'Export failed: an error occurred.';

  @override
  String get commonPhoneLabel => 'Phone number';

  @override
  String get commonOptional => 'Optional';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authContinueApple => 'Continue with Apple';

  @override
  String get authNoAccountPrefix => 'Not a member yet? ';

  @override
  String get authSignUpLink => 'Sign up';

  @override
  String get authSignupTitle => 'Create an account';

  @override
  String get authBirthDateError => 'Please select your date of birth';

  @override
  String get authPhoneRequiredError => 'Please enter your phone number';

  @override
  String get authSignupButton => 'Sign up';

  @override
  String get authSignupGoogle => 'Sign up with Google';

  @override
  String get authSignupApple => 'Sign up with Apple';

  @override
  String get authHasAccountPrefix => 'Already a member? ';

  @override
  String get authAcceptPrefix => 'By continuing, you agree to the ';

  @override
  String get authTermsLink => 'Terms of Use';

  @override
  String get authAcceptAnd => ' and ';

  @override
  String get authPrivacyLink => 'Privacy Policy';

  @override
  String get legalTermsTitle => 'Terms of Use';

  @override
  String get legalPrivacyTitle => 'Privacy Policy';

  @override
  String get authTermsRequiredError =>
      'Please accept the Terms of Use and Privacy Policy to continue.';

  @override
  String get otpContextLogin => 'Sign in';

  @override
  String get otpContextSignup => 'Sign up';

  @override
  String get otpContextSocial => 'Verification';

  @override
  String get otpTitle => 'Verification';

  @override
  String otpSentMessage(String phone) {
    return 'A 6-digit code was sent to\n$phone';
  }

  @override
  String otpResendCountdown(String seconds) {
    return 'Resend code in 00:$seconds';
  }

  @override
  String get otpResendButton => 'Resend code';

  @override
  String completeProfileWelcomeNamed(String name) {
    return 'Welcome, $name!\nYour account has been created.';
  }

  @override
  String get completeProfileWelcomeAnon =>
      'Welcome!\nYour account has been created.';

  @override
  String get completeProfileTitle => 'Complete your profile';

  @override
  String get completeProfileSubmit => 'Go to the app';

  @override
  String get completeProfileSkip => 'Skip this step';

  @override
  String get completeSocialProfileTitle => 'Complete your profile';

  @override
  String get onboardingSlide1Title => 'All your cards,\none wallet';

  @override
  String get onboardingSlide1Subtitle =>
      'Bring your favorite loyalty cards together in one seamless, frictionless experience.';

  @override
  String get onboardingSlide2Title => 'Perks on\nevery visit';

  @override
  String get onboardingSlide2Subtitle =>
      'Earn stamps and points automatically, and unlock exclusive perks at your favorite spots.';

  @override
  String get onboardingSlide3Title => 'Share,\nearn together';

  @override
  String get onboardingSlide3Subtitle =>
      'Invite your friends with your personal code and earn referral points.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get commonValidate => 'Confirm';

  @override
  String get qrManualEntryLabel => 'Enter the code manually';

  @override
  String get qrScanTitle => 'SCAN A QR CODE';

  @override
  String get qrToggleFlash => 'Toggle flash';

  @override
  String get qrPlaceInFrame => 'Place the restaurant\'s QR code in the frame.';

  @override
  String get qrManualEntryHint =>
      'The unique 8-character code is printed below the QR code shown by the establishment.';

  @override
  String get qrManualEntryPlaceholder => 'E.g. 8XKQ2P9Z';

  @override
  String get qrCameraUnavailableTitle => 'Camera unavailable';

  @override
  String get qrCameraUnavailableMessage =>
      'Allow camera access in settings, or enter the code manually.';

  @override
  String get joinOfferDetail => 'Earn 10 stamps for a free full meal.';

  @override
  String get joinUnrecognizedTitle => 'Code not recognized';

  @override
  String joinUnrecognizedMessage(String code) {
    return '\"$code\" doesn\'t match any Carte partner establishment at the moment.';
  }

  @override
  String get joinRetryScan => 'Try scanning again';

  @override
  String get joinBackToWallet => 'Back to Wallet';

  @override
  String get joinEyebrow => 'Join';

  @override
  String get joinWelcomeOfferEyebrow => 'Welcome offer';

  @override
  String get joinButton => 'Join the program';

  @override
  String get joinCardCreatedTitle => 'Card created!';

  @override
  String get joinCardAlreadyMemberTitle => 'Already a member!';

  @override
  String get joinCardAlreadyMemberMessage =>
      'You\'re already a member of this loyalty program.';

  @override
  String get phonePickerTitle => 'Select a dial code';

  @override
  String get phonePickerSearchHint => 'Search a country or dial code...';

  @override
  String phoneDigitsError(int count, String country) {
    return 'The number must contain $count digits for $country.';
  }

  @override
  String get countryPickerTitle => 'Select a country';

  @override
  String get countryPickerSearchHint => 'Search a country...';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authForgotPasswordLink => 'Forgot password?';

  @override
  String get authLoadingLogin => 'Signing in...';

  @override
  String get authLoadingGoogle => 'Signing in with Google...';

  @override
  String get authLoadingApple => 'Signing in with Apple...';

  @override
  String get authLoadingSignup => 'Creating your account...';

  @override
  String get authLoadingSignOut => 'Signing out...';

  @override
  String get createPasswordTitle => 'Create your password';

  @override
  String get createPasswordSubtitle => 'One last step to secure your account.';

  @override
  String get createPasswordConfirmLabel => 'Confirm password';

  @override
  String get createPasswordRuleMinLength => 'At least 8 characters';

  @override
  String get createPasswordRuleUppercase => 'One uppercase letter';

  @override
  String get createPasswordRuleDigit => 'One digit';

  @override
  String get createPasswordButton => 'Create my account';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your phone number and we\'ll send you a verification code.';

  @override
  String get forgotPasswordButton => 'Send code';

  @override
  String get resetPasswordTitle => 'New password';

  @override
  String get resetPasswordSubtitle => 'Choose a new password for your account.';

  @override
  String get resetPasswordButton => 'Reset';

  @override
  String get resetPasswordLoading => 'Resetting...';

  @override
  String get otpVerifyLoading => 'Verifying code...';

  @override
  String get splashLoading => 'Loading...';

  @override
  String get forgotPasswordUseEmail => 'Use my email address';

  @override
  String get forgotPasswordUsePhone => 'Use my phone number';

  @override
  String get forgotPasswordEmailLabel => 'Email address';

  @override
  String get forgotPasswordEmailHint => 'you@example.com';

  @override
  String get forgotPasswordSubtitleEmail =>
      'Enter your email address and we\'ll send you a verification code.';

  @override
  String get forgotPasswordSending => 'Sending code...';

  @override
  String get errNoInternet =>
      'You appear to be offline. Check your connection, then try again.';

  @override
  String get errServerUnreachable =>
      'We can\'t reach our servers. Try again in a few moments.';

  @override
  String get errServerError =>
      'The service is temporarily unavailable. Try again in a few moments.';

  @override
  String get errUnexpected => 'Something went wrong. Try again.';

  @override
  String get errTooManyAttempts =>
      'Too many attempts. Wait a few moments before trying again.';

  @override
  String get errSessionExpired =>
      'Your session has expired. Sign in again to continue.';

  @override
  String get errMissingRequiredFields => 'Please fill in all required fields.';

  @override
  String get errLoginInvalidCredentials =>
      'Incorrect phone number or password.';

  @override
  String get errMerchantLoginInvalidCredentials =>
      'Incorrect email address or password.';

  @override
  String get errLoginAccountNotFound => 'This account doesn\'t exist yet.';

  @override
  String get errLoginAccountDeactivated =>
      'This account has been deactivated. Contact your administrator.';

  @override
  String get errTeamActionFailed =>
      'Couldn\'t complete this action. Try again.';

  @override
  String get errLoginFailed => 'We can\'t sign you in right now. Try again.';

  @override
  String get errAccountUsesGoogle =>
      'This account uses Google sign-in. Sign in with Google to access your account.';

  @override
  String get errAccountUsesApple =>
      'This account uses Apple sign-in. Sign in with Apple to access your account.';

  @override
  String get errLoginSuccess => 'You\'re signed in.';

  @override
  String get errSocialCancelled => 'Sign-in cancelled.';

  @override
  String get errSocialFailedGoogle =>
      'We couldn\'t sign you in with Google. Try again.';

  @override
  String get errSocialFailedApple =>
      'We couldn\'t sign you in with Apple. Try again.';

  @override
  String get errSocialAccountNotFound =>
      'No account is linked to this profile. Create an account first.';

  @override
  String get errSocialEmailUsesPassword =>
      'An account already exists with this email and uses a password. Sign in with your password instead.';

  @override
  String get errSignupPhoneTaken =>
      'This phone number is already linked to an account.';

  @override
  String get errSignupEmailTaken => 'This email address is already in use.';

  @override
  String get errSignupFailed =>
      'We can\'t create your account right now. Try again.';

  @override
  String get errSignupSuccess => 'Your account has been created.';

  @override
  String get errForgotAccountNotFound =>
      'No account is linked to this phone number.';

  @override
  String get errMerchantForgotAccountNotFound =>
      'No account is linked to this email address.';

  @override
  String get errForgotCodeSent => 'A reset code has just been sent.';

  @override
  String get errForgotSendFailed =>
      'We couldn\'t send the code. Try again in a few moments.';

  @override
  String get errOtpInvalid => 'This code is incorrect. Check it and try again.';

  @override
  String get errOtpExpired =>
      'This code has expired. Request a new one to continue.';

  @override
  String get errResetSessionExpired =>
      'Your request has expired. Start the reset over.';

  @override
  String get errResetFailed => 'We couldn\'t reset your password. Try again.';

  @override
  String get errResetSuccess => 'Your password has been changed.';

  @override
  String get errProfileSaveFailed =>
      'We couldn\'t save your changes. Try again.';

  @override
  String get errProfileSaveSuccess => 'Your information has been saved.';

  @override
  String get errProfileCompleteFailed =>
      'We couldn\'t save your profile. Try again.';

  @override
  String get errAvatarUpdateFailed =>
      'We couldn\'t update your profile picture. Try again.';

  @override
  String get errAvatarUpdateSuccess => 'Profile picture updated.';

  @override
  String get errAvatarRemoveSuccess => 'Profile picture removed.';

  @override
  String get errAvatarInvalid => 'This image can\'t be used. Try another one.';

  @override
  String get errPasswordCurrentIncorrect =>
      'Your current password is incorrect.';

  @override
  String get errPasswordChangeSuccess => 'Your password has been changed.';

  @override
  String get errPasswordChangeFailed =>
      'We couldn\'t change your password. Try again.';

  @override
  String get errFieldRequired => 'Please fill in this field.';

  @override
  String get errPhoneInvalid => 'This phone number isn\'t valid.';

  @override
  String get errPhoneTaken =>
      'This phone number is already linked to an account.';

  @override
  String get errPhoneRisky => 'This number can\'t be used. Try another one.';

  @override
  String get errEmailInvalid => 'This email address isn\'t valid.';

  @override
  String get errEmailTaken => 'This email address is already in use.';

  @override
  String get errPasswordTooShort =>
      'Your password must be at least 8 characters.';

  @override
  String get errPasswordMismatch => 'The two passwords don\'t match.';

  @override
  String get errPasswordNeedsUppercase =>
      'Your password must contain at least one uppercase letter.';

  @override
  String get errPasswordNeedsDigit =>
      'Your password must contain at least one digit.';

  @override
  String get errPasswordMustDiffer =>
      'Your new password must differ from the current one.';

  @override
  String get errPasswordIncorrect => 'Incorrect password.';

  @override
  String get errNameInvalid => 'This name isn\'t valid.';

  @override
  String get errBirthdateInvalid => 'This date of birth isn\'t valid.';

  @override
  String get errBirthdateRequired => 'Please enter your date of birth.';

  @override
  String get errReferralCodeInvalid => 'This referral code doesn\'t exist.';

  @override
  String get errOtpFieldInvalid => 'This code isn\'t valid.';

  @override
  String get errFieldInvalid => 'This information isn\'t valid.';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordVerifySubtitle =>
      'Confirm your current password to continue.';

  @override
  String get changePasswordCurrentLabel => 'Current password';

  @override
  String get changePasswordVerifying => 'Verifying...';

  @override
  String get changePasswordContinue => 'Continue';

  @override
  String get changePasswordNewTitle => 'New password';

  @override
  String get changePasswordNewSubtitle =>
      'Choose a password different from the current one.';

  @override
  String get changePasswordNewLabel => 'New password';

  @override
  String get changePasswordSaving => 'Saving...';

  @override
  String get changePasswordSubmit => 'Save';

  @override
  String get editProfileCity => 'City';

  @override
  String get editProfileCityHint => 'Lomé';

  @override
  String get editProfileCountry => 'Country';

  @override
  String get editProfileCountryHint => 'Togo';

  @override
  String get editProfileSaving => 'Saving...';

  @override
  String get editProfilePhotoChange => 'Change photo';

  @override
  String get editProfilePhotoRemove => 'Remove photo';

  @override
  String get editProfileSecurity => 'Security';

  @override
  String get editProfileNotSet => 'Not set';

  @override
  String get editProfilePhotoLabel => 'Profile photo';

  @override
  String get editProfileAuthMethod => 'Sign-in method';

  @override
  String editProfileConnectedVia(String provider) {
    return 'Connected via $provider';
  }

  @override
  String get merchantNavClients => 'Clients';

  @override
  String get merchantNavStats => 'Stats';

  @override
  String get merchantNavValidate => 'Validate';

  @override
  String get merchantNavSms => 'SMS';

  @override
  String get merchantNavSettings => 'Settings';

  @override
  String get merchantMoreBusinessProfile => 'Business profile';

  @override
  String get merchantMoreCompleteProfile => 'Complete my profile';

  @override
  String get merchantMoreLogoBusiness => 'Business logo';

  @override
  String get merchantMoreSocials => 'Social media';

  @override
  String get merchantMoreGoogleReviewLink => 'Google review link';

  @override
  String get merchantMoreSectionAccount => 'ACCOUNT';

  @override
  String get merchantMoreHours => 'Opening hours';

  @override
  String get merchantMoreToComplete => 'To complete';

  @override
  String get merchantMoreSubscription => 'Subscription';

  @override
  String get merchantMoreProTag => 'Pro';

  @override
  String get merchantMoreLanguageTheme => 'Language & theme';

  @override
  String get merchantMoreTeam => 'Team';

  @override
  String get merchantMoreSectionLoyaltyCard => 'MY LOYALTY CARD';

  @override
  String get merchantMoreCustomizeCard => 'Customize the card';

  @override
  String get merchantMoreGoalReward => 'Goal & reward';

  @override
  String get merchantMoreLoyaltyProgram => 'Loyalty program';

  @override
  String get merchantMoreMyQrCode => 'My QR code';

  @override
  String get merchantMoreMyShowcase => 'My showcase';

  @override
  String get merchantMoreSectionSupport => 'SUPPORT';

  @override
  String get merchantMoreLegalPrivacy => 'Privacy';

  @override
  String get merchantMoreLegalTerms => 'Terms of use';

  @override
  String get merchantMoreWhatsappSupport => 'WhatsApp support';

  @override
  String get merchantSignOutConfirmTitle => 'Sign out?';

  @override
  String get merchantSignOutConfirmMessage =>
      'You\'ll need to sign in again to access your merchant space.';

  @override
  String get merchantSignOutConfirm => 'Sign out';

  @override
  String get changePasswordConfirmLabel => 'Confirm new password';

  @override
  String get merchantAccountTitle => 'Account & Profile';

  @override
  String get merchantAccountProfile => 'Profile';

  @override
  String get merchantSubscriptionCategoryTitle => 'Subscription & Team';

  @override
  String get merchantSubscriptionMyPlan => 'My Subscription';

  @override
  String get merchantSubscriptionTeamMembers => 'Team members';

  @override
  String get merchantNotifUpdateError =>
      'Couldn\'t update this preference. Try again.';

  @override
  String get merchantNotifNewClientTitle => 'New client';

  @override
  String get merchantNotifNewClientSubtitle => 'Notify on every sign-up';

  @override
  String get merchantNotifRewardTitle => 'Reward earned';

  @override
  String get merchantNotifRewardSubtitle => 'When a tier is reached';

  @override
  String get merchantNotifLowSmsTitle => 'Low SMS quota';

  @override
  String get merchantNotifLowSmsSubtitle => 'Under 20 SMS remaining';

  @override
  String get merchantNotifWeeklyReportTitle => 'Weekly report';

  @override
  String get merchantNotifWeeklyReportSubtitle => 'Every Monday morning';

  @override
  String get merchantNotifPromotionsTitle => 'Miva-Fid promotions';

  @override
  String get merchantNotifPromotionsSubtitle => 'Offers and news';

  @override
  String get merchantTeamInviteTitle => 'Invite a member';

  @override
  String get merchantTeamNameLabel => 'Name';

  @override
  String get merchantTeamPhoneOptionalLabel => 'Phone (optional)';

  @override
  String get merchantTeamPasswordLabel => 'Password';

  @override
  String get merchantTeamRoleOperator => 'Operator';

  @override
  String get merchantTeamRoleAdmin => 'Administrator';

  @override
  String get merchantTeamInviteButton => 'Invite';

  @override
  String get merchantTeamInviteError => 'Couldn\'t invite this member.';

  @override
  String get merchantTeamEmptyState =>
      'No team members yet. Invite your first operator.';

  @override
  String get merchantTeamToggleStatusError =>
      'Couldn\'t update this member\'s status.';

  @override
  String get merchantTierSilver => 'Silver';

  @override
  String get merchantTierGold => 'Gold';

  @override
  String get merchantTierPlatinum => 'Platinum';

  @override
  String get merchantDashboardTitle => 'Statistics';

  @override
  String get merchantDashboardSubtitle =>
      'Overview of your activity — June 2026';

  @override
  String get merchantDashboardStampsLabel => 'Stamps';

  @override
  String get merchantDashboardThisMonthLabel => 'this month';

  @override
  String get merchantDashboardRewardsLabel => 'Rewards';

  @override
  String get merchantDashboardUsedLabel => 'used';

  @override
  String get merchantDashboardMonthActivityTitle => 'Activity this month';

  @override
  String get merchantDashboardValidationsPerWeekSubtitle =>
      'Validations per week';

  @override
  String merchantDashboardWeekLabel(String number) {
    return 'Week $number';
  }

  @override
  String get merchantDashboardVipDistributionTitle => 'VIP breakdown';

  @override
  String get merchantDashboardClientsByTierSubtitle => 'Your clients by tier';

  @override
  String get merchantClientsTitle => 'My clients';

  @override
  String merchantClientsActiveCount(String count) {
    return '$count active clients';
  }

  @override
  String get merchantClientsAddSoonToast =>
      'Manually adding a client will be available soon.';

  @override
  String get merchantClientsExportToast =>
      'Exporting the client list as CSV has started!';

  @override
  String get merchantClientsExportButton => 'Export list';

  @override
  String get merchantClientsSearchHint => 'Search for a client...';

  @override
  String get merchantClientsFilterAll => 'All';

  @override
  String get merchantClientsFilterInactive30d => '+30d';

  @override
  String merchantClientsPaginationInfo(String from, String to, String total) {
    return '$from-$to of $total';
  }

  @override
  String get merchantClientsPrevious => '< Prev.';

  @override
  String get merchantClientsNext => 'Next >';

  @override
  String get merchantClientDetailRemoveTitle => 'Remove from program?';

  @override
  String merchantClientDetailRemoveMessage(String name) {
    return 'Are you sure you want to remove $name from your loyalty program? Their stamps will be reset.';
  }

  @override
  String get merchantClientDetailRemoveConfirm => 'Remove';

  @override
  String get merchantClientDetailRemoveToast =>
      'Client removed from the program.';

  @override
  String get merchantClientDetailSubtitle => 'Client profile';

  @override
  String get merchantClientDetailProgress => 'Progress';

  @override
  String get merchantClientDetailSendSms => 'Send an SMS';

  @override
  String get merchantClientDetailCall => 'Call';

  @override
  String get merchantClientDetailRewardsLabel => 'Rewards';

  @override
  String get merchantClientDetailLastLabel => 'Last';

  @override
  String get merchantClientDetailHistoryTitle => 'History';

  @override
  String get merchantClientDetailHistoryStampValidated => 'Stamp validated';

  @override
  String get merchantClientDetailHistoryRewardUsed => 'Reward used';

  @override
  String get merchantClientDetailHistoryEnrolled => 'Enrolled in the program';

  @override
  String get merchantClientDetailRemoveButton => 'Remove from program';

  @override
  String get merchantValidateQrInvalid => 'Invalid or unreadable QR code.';

  @override
  String get merchantValidateNetworkError =>
      'Can\'t connect. Check your network.';

  @override
  String get merchantValidateNoCardFound =>
      'No loyalty card found for this business.';

  @override
  String get merchantValidateNoRewardFound =>
      'No reward from your business matches this code.';

  @override
  String get merchantValidateRewardSuccess => 'Reward validated successfully!';

  @override
  String get merchantValidateRewardError => 'Error while validating.';

  @override
  String get merchantValidateFailedRetry => 'Validation failed. Try again.';

  @override
  String get merchantValidateDefaultClientName => 'Client';

  @override
  String get merchantValidateTitle => 'Validate a visit';

  @override
  String get merchantValidateSubtitle => 'Scan or enter the ID';

  @override
  String get merchantValidateTabScanner => 'Scanner';

  @override
  String get merchantValidateTabPhone => 'ID';

  @override
  String get merchantValidateScanInstruction =>
      'Point the camera at the client\'s QR code';

  @override
  String get merchantValidateDisableCamera => 'Turn off camera';

  @override
  String get merchantValidateEnableCamera => 'Turn on camera';

  @override
  String get merchantValidateManualSearchTitle => 'Search by ID';

  @override
  String get merchantValidateManualSearchSubtitle =>
      'Enter the client\'s ID to validate their visit.';

  @override
  String get merchantValidateManualSearchHint => 'Client ID';

  @override
  String get merchantValidateSearchButton => 'Search for client';

  @override
  String get merchantSmsCampaignSubtitle => 'Campaigns & messages';

  @override
  String get merchantSmsCampaignSentLabel => 'Sent';

  @override
  String get merchantSmsCampaignOpenRateLabel => 'Open rate';

  @override
  String get merchantSmsCampaignReachedLabel => 'Reached';

  @override
  String merchantSmsCampaignCount(String count) {
    return '$count campaigns';
  }

  @override
  String get merchantSmsCampaignDetailSentBadge => 'Sent';

  @override
  String get merchantSmsCampaignDetailRecipients => 'Recipients';

  @override
  String get merchantSmsCampaignDetailSent => 'Sent';

  @override
  String get merchantSmsCampaignDetailOpened => 'Opened';

  @override
  String get merchantSmsCampaignDetailOpenRate => 'Open rate';

  @override
  String get merchantSmsCampaignDetailMessageTitle => 'Message sent';

  @override
  String get merchantSmsCampaignDetailDuplicateToast =>
      'Campaign duplicated into a new draft!';

  @override
  String get merchantSmsCampaignDetailDuplicateButton =>
      'Duplicate this campaign';

  @override
  String get merchantSmsConversationSentToast => 'SMS sent successfully!';

  @override
  String get merchantSmsConversationLabel => 'SMS conversation';

  @override
  String get merchantSmsConversationInputHint => 'Write a message...';

  @override
  String get merchantProfileLogoSuccess => 'Logo updated successfully';

  @override
  String get merchantProfileLogoError => 'Couldn\'t update the logo.';

  @override
  String get merchantProfileSaveSuccess => 'Changes saved!';

  @override
  String get merchantProfileLogoHint => 'PNG or JPG, square, max 2 MB.';

  @override
  String get merchantProfileLoadingEllipsis => 'Loading...';

  @override
  String get merchantProfileChangeLink => 'Change';

  @override
  String get merchantProfileSectionInfo => 'INFORMATION';

  @override
  String get merchantProfileBusinessNameLabel => 'BUSINESS NAME';

  @override
  String get merchantProfileCategoryLabel => 'CATEGORY';

  @override
  String get merchantProfileDescriptionLabel => 'DESCRIPTION';

  @override
  String merchantProfileCharCount(String count) {
    return '$count/200 characters';
  }

  @override
  String get merchantProfileSectionContact => 'CONTACT';

  @override
  String get merchantProfileEmailLabel => 'EMAIL';

  @override
  String get merchantProfilePhoneLabel => 'PHONE';

  @override
  String get merchantProfileWhatsappLabel => 'WHATSAPP';

  @override
  String get merchantProfileSectionAddress => 'ADDRESS';

  @override
  String get merchantProfileCityLabel => 'CITY';

  @override
  String get merchantProfileAddressLabel => 'ADDRESS / NEIGHBORHOOD';

  @override
  String get merchantProfileSaveButton => 'Save changes';

  @override
  String get merchantVitrineLogoUploadError =>
      'Couldn\'t upload the logo. Try again.';

  @override
  String get merchantVitrineLogoRemoveError =>
      'Couldn\'t remove the logo. Try again.';

  @override
  String get merchantVitrineSaveSuccess => 'Showcase updated successfully';

  @override
  String merchantVitrineSaveError(String error) {
    return 'Error: $error';
  }

  @override
  String get merchantVitrinePreviewTitle => 'Public preview';

  @override
  String get merchantVitrineTitle => 'My Showcase';

  @override
  String get merchantVitrineSubtitle => 'Public page for your business';

  @override
  String get merchantVitrinePreviewButton => 'Preview';

  @override
  String get merchantVitrineCoverPhotoSection => 'Cover photo';

  @override
  String get merchantVitrineInfoSection => 'Information';

  @override
  String get merchantVitrineDescriptionHint => 'Description...';

  @override
  String get merchantVitrineContactAddressSection => 'Contact & address';

  @override
  String get merchantVitrineHoursSection => 'Hours';

  @override
  String get merchantVitrineDayMonday => 'Monday';

  @override
  String get merchantVitrineDayTuesday => 'Tuesday';

  @override
  String get merchantVitrineDayWednesday => 'Wednesday';

  @override
  String get merchantVitrineDayThursday => 'Thursday';

  @override
  String get merchantVitrineDayFriday => 'Friday';

  @override
  String get merchantVitrineDaySaturday => 'Saturday';

  @override
  String get merchantVitrineDaySunday => 'Sunday';

  @override
  String get merchantVitrineClosedLabel => 'Closed';

  @override
  String get merchantVitrinePublishButton => 'Publish changes';

  @override
  String get merchantVitrineAddPhotoLabel => 'Add a photo';

  @override
  String get merchantSubscriptionPlanStarterName => 'Starter';

  @override
  String get merchantSubscriptionPlanBusinessName => 'Business';

  @override
  String get merchantSubscriptionNextInvoiceLabel => 'Next invoice';

  @override
  String get merchantSubscriptionCurrentBadge => 'CURRENT';

  @override
  String get merchantSubscriptionChooseButton => 'Choose';

  @override
  String merchantSubscriptionPlanChangedSuccess(String plan) {
    return 'Subscription changed: $plan plan selected';
  }

  @override
  String merchantSubscriptionPlanChangeError(String error) {
    return 'Error while changing plan: $error';
  }

  @override
  String get merchantQrCodeLoadError => 'Error';

  @override
  String get merchantQrCodeSubtitle => 'Display it so clients can scan';

  @override
  String get merchantQrCodeScanToEarnLabel => 'Scan to earn a stamp';

  @override
  String get merchantQrCodePngSavedToast => 'Image saved to gallery!';

  @override
  String get merchantQrCodeShareButton => 'Share';

  @override
  String get merchantQrCodeUniqueCodeSection => 'UNIQUE CODE';

  @override
  String get merchantQrCodeCodeCopiedToast => 'Code copied to clipboard!';

  @override
  String get merchantQrCodeThisWeekLabel => 'This week';

  @override
  String get merchantQrCodeThisMonthLabel => 'This month';

  @override
  String get merchantQrCodeNewLabel => 'New';

  @override
  String get merchantQrCodeTipLabel => 'Tip';

  @override
  String get merchantQrCodeTipMessage =>
      'Place the QR code at checkout or on tables to maximize scans.';

  @override
  String get merchantQrCodePdfScanMessage => 'Scan to earn your points!';

  @override
  String get merchantQrCodePdfPoweredBy => 'Powered by Miva-Fid';

  @override
  String merchantQrCodeWhatsappShareMessage(String name) {
    return 'Join my Miva-Fid loyalty program at $name!';
  }

  @override
  String get merchantProgrammeTitle => 'Loyalty';

  @override
  String get merchantProgrammeCardPreviewLabel => 'Card preview';

  @override
  String get merchantProgrammeConfigTitle => 'Configuration';

  @override
  String get merchantProgrammeConfigSubtitle =>
      'Manage the details of your loyalty program';

  @override
  String get merchantProgrammeAppearanceTitle => 'Card appearance';

  @override
  String get merchantProgrammeAppearanceSubtitle =>
      'Customize the colors and style';

  @override
  String get merchantProgrammeTiersTitle => 'Loyalty tiers';

  @override
  String get merchantProgrammeTiersSubtitle =>
      'Goals, levels, and rewards for your program';

  @override
  String get merchantProgrammeRulesTitle => 'Accumulation rules';

  @override
  String get merchantProgrammeRulesSubtitle =>
      'Configure the ratio (e.g.: 1 point = 500 FCFA)';

  @override
  String get merchantProgrammeLoopTitle => 'Looping program';

  @override
  String get merchantProgrammeLoopEnabledSubtitle =>
      'Once the last tier is reached: a new cycle starts automatically.';

  @override
  String get merchantProgrammeLoopDisabledSubtitle =>
      'Once the last tier is reached: the card is permanently complete.';

  @override
  String get merchantProgrammeTiersLoadingTitle => 'Tiers';

  @override
  String get merchantProgrammeGoalUnitPoints => 'points / FCFA';

  @override
  String get merchantProgrammeGoalUnitCashback => 'FCFA of cumulative cashback';

  @override
  String get merchantProgrammeGoalUnitStamps => 'stamps';

  @override
  String get merchantProgrammeTiersSaveSuccess => 'Tiers updated successfully';

  @override
  String merchantProgrammeTiersSaveError(String error) {
    return 'Error: $error';
  }

  @override
  String get merchantProgrammeAddTierButton => 'Add a tier';

  @override
  String merchantProgrammeRulesNotApplicable(String mode) {
    return 'Your program is configured in \"$mode\" mode.\n\nNo FCFA -> Points conversion rule is required.';
  }

  @override
  String get merchantProgrammeRulesSaveSuccess =>
      'Conversion rule updated successfully';

  @override
  String merchantProgrammeRulesSaveError(String error) {
    return 'Error: $error';
  }

  @override
  String get merchantProgrammeRulesConversionLabel =>
      'FCFA -> Points conversion';

  @override
  String get merchantProgrammeRulesConversionSubtitle =>
      'Set how much the client must spend to earn 1 point.';

  @override
  String get merchantProgrammeRulesInputLabel => '1 point per how many FCFA? *';

  @override
  String get merchantProgrammeRulesInputHint => 'E.g.: 500';

  @override
  String get merchantProgrammeRulesValidatorError =>
      'Please enter a number greater than 0';

  @override
  String get merchantProgrammeDesignLogoRemovedToast => 'Logo removed';

  @override
  String get merchantProgrammeDesignSaveSuccess =>
      'Design updated successfully';

  @override
  String merchantProgrammeDesignSaveError(String error) {
    return 'Error: $error';
  }

  @override
  String get merchantProgrammeDesignLoadingTitle => 'Appearance';

  @override
  String get merchantProgrammeDesignChooseIconTitle => 'Choose an icon';

  @override
  String get merchantProgrammeDesignChooseEmojiTitle => 'Choose an emoji';

  @override
  String get merchantProgrammeDesignLogoHint =>
      'This logo will appear on your loyalty card and on your profiles.';

  @override
  String get merchantProgrammeDesignLogoPresent => 'Logo present';

  @override
  String get merchantProgrammeDesignNoLogo => 'No logo';

  @override
  String get merchantProgrammeDesignSquareFormatHint =>
      'Square format recommended';

  @override
  String get merchantProgrammeDesignAddButton => 'Add';

  @override
  String get merchantProgrammeDesignRemoveTooltip => 'Remove';

  @override
  String get merchantProgrammeDesignPrimaryColorLabel => 'Primary color';

  @override
  String get merchantProgrammeDesignColorHint =>
      'Choose the dominant color of your loyalty card.';

  @override
  String get merchantProgrammeDesignPatternLabel => 'Background pattern';

  @override
  String get merchantProgrammeDesignPatternNone => 'None';

  @override
  String get merchantProgrammeDesignPatternLines => 'Lines';

  @override
  String get merchantProgrammeDesignPatternWaves => 'Waves';

  @override
  String get merchantProgrammeDesignPatternDots => 'Dots';

  @override
  String get merchantProgrammeDesignStampStyleLabel => 'Stamp style';

  @override
  String get merchantProgrammeDesignStampTypeIcon => 'Icon';

  @override
  String get merchantProgrammeDesignStampTypeEmoji => 'Emoji';

  @override
  String get merchantProgrammeDesignIconSelectedLabel => 'Icon selected';

  @override
  String get merchantProgrammeDesignEmojiSelectedLabel => 'Emoji selected';

  @override
  String get merchantProgrammeDesignSaveButton => 'Save design';

  @override
  String get merchantPlanUpgradeTitle => 'Upgrade to Pro';

  @override
  String get merchantPlanUpgradeSubtitle =>
      'Unlimited SMS campaigns, advanced analytics, and priority support.';

  @override
  String get merchantPlanUpgradeButton => 'Discover Pro';

  @override
  String get merchantPlanUpgradeToast => 'Pro offer coming soon';

  @override
  String get merchantValidateRewardUnlockedTitle => 'Reward unlocked!';

  @override
  String merchantValidateCashbackCreditedTitle(String amount, String name) {
    return '$amount FCFA credited to $name!';
  }

  @override
  String merchantValidateStampGrantedTitle(String name) {
    return 'Stamp granted to $name!';
  }

  @override
  String merchantValidatePointsGrantedTitle(String points, String name) {
    return '$points point(s) granted to $name!';
  }

  @override
  String get merchantValidateRewardUnlockedSubtitle =>
      'The client can now claim their reward.';

  @override
  String get merchantValidateCashbackCreditedSubtitle =>
      'Cashback credited to the client\'s balance.';

  @override
  String merchantValidateStampProgressSubtitle(String current, String goal) {
    return '$current out of $goal stamps';
  }

  @override
  String merchantValidatePointsProgressSubtitle(String current, String goal) {
    return '$current out of $goal points';
  }

  @override
  String get merchantValidateNextStepButton => 'Next step';

  @override
  String get merchantValidateRewardStatusUsed => 'Already used';

  @override
  String get merchantValidateRewardStatusCanceled => 'Canceled';

  @override
  String get merchantValidateRewardStatusExpired => 'Expired';

  @override
  String get merchantValidateRewardStatusAvailable => 'Available';

  @override
  String get merchantValidateRewardSheetTitle => 'Reward';

  @override
  String merchantValidateRewardClientLabel(String name) {
    return 'Client: $name';
  }

  @override
  String get merchantValidateRewardConfirmButton => 'Confirm redemption';

  @override
  String get merchantValidateRewardCancelButton => 'Cancel this reward';

  @override
  String get merchantValidateCardInactive => 'Inactive card';

  @override
  String get merchantValidateConfirmAndCredit => 'Confirm and credit';

  @override
  String get merchantValidateCreditCashback => 'Credit the cashback';

  @override
  String get merchantValidateValidateStamp => 'Validate the stamp';

  @override
  String get merchantValidateCreditCashbackButton => 'Credit cashback';

  @override
  String get merchantValidateRedeemCashbackButton => 'Use cashback';

  @override
  String get merchantValidateNoCashbackBalance =>
      'No cashback balance to use for this client.';

  @override
  String get merchantValidatePurchaseAmountLabel => 'Purchase amount';

  @override
  String merchantValidateCashbackCreditedHelper(String percent) {
    return '$percent% credited as cashback';
  }

  @override
  String get merchantValidateEnterAmountCashbackHint =>
      'Enter the amount to see the cashback credited.';

  @override
  String merchantValidateCashbackCreditedResult(String amount) {
    return '= $amount of cashback credited';
  }

  @override
  String get merchantValidateCashbackToUseLabel => 'Cashback to use';

  @override
  String merchantValidateAvailableBalance(String amount) {
    return 'Available balance: $amount';
  }

  @override
  String merchantValidateAmountToPay(String amount) {
    return '= $amount to pay';
  }

  @override
  String get merchantValidateExceedsBalance => 'Exceeds the available balance.';

  @override
  String get merchantValidateExceedsPurchase =>
      'Cannot exceed the purchase amount.';

  @override
  String get merchantValidateViewSummaryButton => 'View summary';

  @override
  String get merchantValidateSummaryPurchase => 'Purchase';

  @override
  String get merchantValidateSummaryCashbackUsed => 'Cashback used';

  @override
  String get merchantValidateSummaryToPay => 'To pay';

  @override
  String get merchantValidateSummaryCashbackGenerated => 'Cashback generated';

  @override
  String get merchantValidateSummaryNewBalance => 'New balance';

  @override
  String get merchantValidateConfirmUsageButton => 'Confirm usage';

  @override
  String get merchantValidateInactiveBadge => 'Inactive';

  @override
  String merchantValidatePointsRatioHelper(String amount) {
    return '1 point per $amount FCFA spent';
  }

  @override
  String get merchantValidateEnterAmountPointsHint =>
      'Enter the amount to see the points credited.';

  @override
  String merchantValidatePointsCreditedResult(String points) {
    return '= $points point(s) credited';
  }

  @override
  String get merchantValidateCashbackLabel => 'CASHBACK';

  @override
  String get merchantValidateAvailableBalanceLabel => 'available balance';

  @override
  String get merchantValidatePurchasesLabel => 'PURCHASES';

  @override
  String get merchantValidatePointsLabel => 'POINTS';

  @override
  String merchantValidateSpendGoalLabel(String goal) {
    return 'out of $goal pts (purchases)';
  }

  @override
  String merchantValidatePointsGoalLabel(String goal) {
    return 'out of $goal points';
  }

  @override
  String get merchantTierEditorTitle => 'Your tiers';

  @override
  String merchantTierEditorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tiers',
      one: '$count tier',
    );
    return '$_temp0';
  }

  @override
  String get merchantTierEditorMultiTierHint =>
      'Each tier grants a level you name and unlocks its own reward, and never goes back down once reached.';

  @override
  String get merchantTierEditorEmptyState =>
      'No tier configured — cashback works normally without a tier.';

  @override
  String merchantTierEditorDefaultTierName(String number) {
    return 'Tier $number';
  }

  @override
  String get merchantTierEditorConfigurePrompt => 'Configure this tier';

  @override
  String get merchantTierEditorDeleteTooltip => 'Delete this tier';

  @override
  String merchantTierEditorGoalLabel(String unit) {
    return 'Goal ($unit) *';
  }

  @override
  String get merchantTierEditorGoalRequired => 'The goal is required';

  @override
  String merchantTierEditorMustExceedPrevious(String value) {
    return 'Must be greater than the previous tier ($value)';
  }

  @override
  String get merchantTierEditorLevelNameLabel => 'Level name *';

  @override
  String get merchantTierEditorLevelNameHint => 'E.g.: Discovery, Regular, VIP';

  @override
  String get merchantTierEditorLevelNameRequired =>
      'The level name is required';

  @override
  String get merchantTierEditorRewardLabel => 'Reward offered *';

  @override
  String get merchantTierEditorRewardHint => 'E.g.: 1 free coffee, 10% off';

  @override
  String get merchantTierEditorRewardRequired =>
      'The reward description is required';

  @override
  String get merchantTierEditorSurpriseRewardLabel => 'Surprise reward 🎁';

  @override
  String get merchantTierEditorSurpriseRewardHint =>
      'Hide this tier from the client until they unlock it.';

  @override
  String get merchantTierEditorValidityLabel => 'Validity (days, optional)';

  @override
  String get merchantTierEditorValidityHint =>
      'E.g.: 30 — empty = no expiration';

  @override
  String get merchantTierEditorValidityError =>
      'Please enter a number of days greater than 0';
}
