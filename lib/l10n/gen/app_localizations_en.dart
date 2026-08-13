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
  String get editProfileFullNameHint => 'First Last';

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
      'The code is printed below the QR code shown by the establishment.';

  @override
  String get qrManualEntryPlaceholder => 'E.g. JARDIN-2024';

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
  String get phonePickerTitle => 'Select a dial code';

  @override
  String get phonePickerSearchHint => 'Search a country or dial code...';

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
  String get errLoginAccountNotFound => 'This account doesn\'t exist yet.';

  @override
  String get errLoginFailed => 'We can\'t sign you in right now. Try again.';

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
  String get editProfileSaving => 'Saving...';

  @override
  String get editProfilePhotoChange => 'Change photo';

  @override
  String get editProfilePhotoRemove => 'Remove photo';

  @override
  String get editProfileSecurity => 'Security';
}
