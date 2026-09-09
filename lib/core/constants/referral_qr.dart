/// Préfixe distinguant un QR de parrainage d'un QR d'établissement/récompense
/// au scan — généré côté client depuis `LoyaltyCard.referralQrToken`
/// ([lib/features/client/referral/referral_screen.dart]), reconnu côté
/// serveur ([LoyaltyCardController::join] dans `restaurant-loyalty-api`)
/// pour rattacher le filleul au bon parrain.
const referralQrPrefix = 'MIVAFID-REFERRAL:';
