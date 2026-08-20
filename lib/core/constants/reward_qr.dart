/// Préfixe distinguant un QR de récompense d'un QR de carte de fidélité —
/// généré côté client ([lib/features/client/rewards/rewards_screen.dart]),
/// reconnu côté scan marchand ([lib/features/merchant/screens/validate_screen.dart])
/// pour router vers le bon flux (confirmation récompense vs recherche client).
const rewardQrPrefix = 'MIVAFID-REWARD:';
