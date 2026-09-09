import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';
import 'package:miva_fid/features/client/models/user.dart';

class MockData {
  MockData._();

  static AppUser get user => AppUser(
        id: 'u1',
        fullName: 'Amina Kokou',
        phoneNumber: '+228 90 12 34 56',
        birthDate: DateTime(1996, 4, 18),
        joinDate: DateTime(2024, 3, 1),
        email: 'amina@example.com',
        friendsInvited: 3,
        friendsJoined: 1,
        city: 'Lomé',
        neighborhood: 'Bè',
        authProvider: AuthProvider.phone,
        profileCompleted: true,
      );

  static List<LoyaltyCard> get cards => [
        const LoyaltyCard(
          id: 'card_comptoir',
          restaurantName: 'Bistrot de Quartier',
          restaurantCategory: 'BISTROT DE QUARTIER',
          mechanic: LoyaltyMechanic.stamps,
          liningColor: AppColors.liningTerracotta,
          stampsCurrent: 5,
          stampsGoal: 8,
          fallbackId: 'COM-11829',
          welcomeOffer: 'Un café offert pour votre première visite',
        ),
        const LoyaltyCard(
          id: 'card_palais',
          restaurantName: 'Le Palais',
          restaurantCategory: 'TABLE GASTRONOMIQUE',
          mechanic: LoyaltyMechanic.points,
          liningColor: AppColors.liningIndigo,
          pointsBalance: 1240,
          fallbackId: 'PAL-40217',
          welcomeOffer: '100 points offerts à l\'inscription',
        ),
        const LoyaltyCard(
          id: 'card_sunset',
          restaurantName: 'Sunset Lounge',
          restaurantCategory: 'ROOFTOP & COCKTAILS',
          mechanic: LoyaltyMechanic.cashback,
          liningColor: AppColors.liningPlum,
          cashbackBalanceFcfa: 3400,
          fallbackId: 'SUN-28392',
          welcomeOffer: '500 FCFA de cashback offerts',
        ),
        const LoyaltyCard(
          id: 'card_macbouffe',
          restaurantName: 'Mac Bouffe',
          restaurantCategory: 'CUISINE DU MONDE',
          mechanic: LoyaltyMechanic.vip,
          liningColor: AppColors.liningVip,
          vipTier: VipTier.gold,
          vipProgressToNextTier: 0.65,
          fallbackId: 'MAC-90014',
          welcomeOffer: 'Statut Gold offert dès l\'inscription',
        ),
      ];

  /// Établissements partenaires "découvrables" via scan QR (pas encore dans
  /// le portefeuille de l'utilisateur). En l'absence de backend, la mise en
  /// correspondance code scanné → restaurant est simulée ici.
  static const List<LoyaltyCard> joinableRestaurants = [
    LoyaltyCard(
      id: 'card_jardin_dore',
      restaurantName: 'Le Jardin Doré',
      restaurantCategory: 'BRUNCH & PÂTISSERIE',
      mechanic: LoyaltyMechanic.stamps,
      liningColor: AppColors.liningEmerald,
      stampsCurrent: 1,
      stampsGoal: 8,
      fallbackId: 'JARDIN-2024',
      welcomeOffer: 'Un dessert offert à votre 3e visite',
    ),
  ];

  /// Recherche un établissement partenaire par code scanné/saisi
  /// (insensible à la casse et aux espaces).
  static LoyaltyCard? findJoinableByCode(String rawCode) {
    final normalized = rawCode.trim().toUpperCase();
    for (final card in joinableRestaurants) {
      if (card.fallbackId.toUpperCase() == normalized) return card;
    }
    return null;
  }

}
