/// Affichage marchand — dérivé du `loyaltyType` du restaurant
/// (`stamps`/`points`/`spend`/`cashback`). Centralise les libellés, icônes et
/// unités par mode de fidélité pour que les écrans du dashboard (fiche client,
/// dashboard, hub) parlent la même langue quelle que soit la mécanique.
class MerchantDisplay {
  final String type;

  bool get isAchats => type == 'points' || type == 'spend';
  bool get isCashback => type == 'cashback';
  bool get isStamps => type == 'stamps';

  const MerchantDisplay(this.type);

  factory MerchantDisplay.fromType(String? type) =>
      MerchantDisplay(type ?? 'stamps');

  String get unitLabel =>
      isCashback ? 'cashback' : (isAchats ? 'point' : 'tampon');
  String get unitLabelPlural =>
      isCashback ? 'cashback' : (isAchats ? 'points' : 'tampons');
  String get progressLabel =>
      isCashback ? 'Cashback' : (isAchats ? 'Points' : 'Tampons');
  String get removeLabel => isCashback ? 'Retirer le dernier crédit'
      : (isAchats ? 'Retirer le dernier point' : 'Retirer un tampon');
  String removalLabel(int value) {
    final a = value.abs();
    if (isCashback) return '-$a FCFA';
    if (isAchats) return a > 1 ? '-$a points' : '-$a point';
    return a == 1 ? '-1 tampon' : '-$a tampons';
  }
  String grantLabel(int value) {
    if (isCashback) return '+$value FCFA';
    if (isAchats) return value > 1 ? '+$value points' : '+$value point';
    return value == 1 ? '+1 tampon' : '+$value tampons';
  }
  bool get showTierDistribution => isStamps;
  bool get showProgressDistribution => isAchats || isCashback;
  String get progressDistributionTitle => isCashback ? 'Répartition du cashback'
      : (isAchats ? 'Répartition des points' : 'Répartition des niveaux');
}