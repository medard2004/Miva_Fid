import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../models/merchant_model.dart';
import '../models/restaurant_account.dart';
import 'merchant_auth_provider.dart';

part 'merchant_provider.g.dart';

/// Vue « dashboard » du commerce connecté.
///
/// Source unique : la session Laravel ([merchantAuthProvider]), alimentée par
/// `/auth/merchant/me` et par les écrans d'onboarding. Le provider ne fait
/// donc aucun appel réseau propre : il reprojette le [RestaurantAccount] de
/// la session (infos business de step1/localisation + config du programme de
/// step2/step3) dans le [MerchantModel] que consomment les écrans marchand.
///
/// Auparavant adossé à Supabase, alors que l'inscription marchand écrit
/// désormais dans Laravel : le dashboard n'y trouvait jamais rien et affichait
/// des valeurs de repli ("Votre Commerce", QR vide).
@Riverpod(keepAlive: true)
class MerchantNotifier extends _$MerchantNotifier {
  @override
  Future<MerchantModel?> build() async {
    final restaurant = ref.watch(
      merchantAuthProvider.select((s) => s.restaurant),
    );
    if (restaurant == null) return null;
    return _fromRestaurant(restaurant);
  }

  /// Recharge la session marchande depuis `/auth/merchant/me` — à appeler
  /// après une écriture serveur (fin d'onboarding, édition du programme)
  /// pour que le dashboard reflète l'état réel.
  Future<void> refresh() async {
    await ref.read(merchantAuthProvider.notifier).refreshFromApi();
  }

  /// Applique une modification partielle depuis les écrans du dashboard
  /// (vitrine, réglages, programme).
  ///
  /// Laravel expose deux surfaces distinctes — les infos commerce
  /// (`PUT /auth/merchant/profile`) et le programme de fidélité
  /// (`POST /loyalty-programs`) — et toutes deux attendent une charge utile
  /// complète. On répartit donc les clés reçues et on renvoie l'état courant
  /// fusionné avec le patch, plutôt que le patch seul.
  Future<void> updateProgramme(Map<String, dynamic> data) async {
    final restaurant = ref.read(merchantAuthProvider).restaurant;
    if (restaurant == null) return;

    final businessPatch = <String, dynamic>{};
    final configPatch = <String, dynamic>{};
    for (final entry in data.entries) {
      if (_businessKeys.contains(entry.key)) {
        businessPatch[entry.key] = entry.value;
      } else if (_configKeys.contains(entry.key)) {
        // Le dashboard parle de `stamps_required`, le backend de `goal`.
        final key = entry.key == 'stamps_required' ? 'goal' : entry.key;
        configPatch[key] = entry.value;
      } else if (entry.key == 'plan') {
        await ref
            .read(merchantAuthProvider.notifier)
            .updatePlan(entry.value.toString());
      }
    }

    if (businessPatch.isNotEmpty) {
      await ref.read(merchantAuthProvider.notifier).updateBusinessInfo({
        'name': restaurant.name,
        'category': restaurant.category,
        'phone': restaurant.phone,
        'address': restaurant.address,
        'city': restaurant.city,
        'description': restaurant.description,
        'whatsapp': restaurant.whatsapp,
        'instagram': restaurant.instagram,
        'facebook': restaurant.facebook,
        'tiktok': restaurant.tiktok,
        ...businessPatch,
      });
    }

    if (configPatch.isNotEmpty) {
      final config = Map<String, dynamic>.from(restaurant.loyaltyConfig)
        ..addAll(configPatch);
      await ref.read(loyaltyProgramServiceProvider).save({
        'mode': restaurant.loyaltyType ?? 'stamps',
        'goal': config['goal'] ?? 10,
        'reward_description': config['reward_description'],
        'rewards': config['rewards'],
        'levels': config['levels'],
        'reward_validity_days': config['reward_validity_days'],
        'show_review_button': config['show_review_button'] ?? false,
        'google_review_url': config['google_review_url'],
        'color_primary': config['color_primary'] ?? '#4F46E5',
        'color_secondary': config['color_secondary'] ?? '#3730A3',
        'stamp_design_type': config['stamp_design_type'] ?? 'check',
        'stamp_emoji': config['stamp_emoji'],
        'stamp_icon': config['stamp_icon'],
        'card_decoration_pattern': config['card_decoration_pattern'],
        'card_gradient_type': config['card_gradient_type'],
        'logo_url': config['logo_url'],
        if (restaurant.loyaltyType == 'spend')
          'fcfa_per_point': config['fcfa_per_point'] ?? 100,
        if (restaurant.loyaltyType == 'cashback') ...{
          'cashback_percentage': config['cashback_percentage'] ?? 5,
          if (config['cashback_redeem_cap_percent'] != null)
            'cashback_redeem_cap_percent': config['cashback_redeem_cap_percent'],
        },
      });
    }

    await refresh();
  }
}

/// Clés portées par `PUT /auth/merchant/profile`.
const _businessKeys = {
  'name',
  'category',
  'phone',
  'address',
  'city',
  'description',
  'whatsapp',
  'instagram',
  'facebook',
  'tiktok',
};

/// Clés portées par la `config` du programme (`POST /loyalty-programs`).
const _configKeys = {
  'stamps_required',
  'goal',
  'reward_description',
  'rewards',
  'levels',
  'reward_validity_days',
  'show_review_button',
  'google_review_url',
  'color_primary',
  'color_secondary',
  'stamp_design_type',
  'stamp_emoji',
  'stamp_icon',
  'card_decoration_pattern',
  'card_gradient_type',
  'logo_url',
  'fcfa_per_point',
};

MerchantModel _fromRestaurant(RestaurantAccount r) {
  final config = r.loyaltyConfig;

  String? asString(String key) => config[key]?.toString();

  int? asInt(String key) {
    final value = config[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  return MerchantModel(
    id: r.id,
    userId: r.uuid,
    name: r.name ?? '',
    category: r.category ?? '',
    address: r.address,
    logoUrl: asString('logo_url') ?? r.logoUrl,
    description: r.description,
    phone: r.phone,
    whatsapp: r.whatsapp,
    instagram: r.instagram,
    facebook: r.facebook,
    tiktok: r.tiktok,
    colorPrimary: asString('color_primary') ?? '#4F46E5',
    colorSecondary: asString('color_secondary') ?? '#3730A3',
    // Le backend nomme le mode `type` (`stamps`/`points`/`spend`) ; le module
    // marchand parle de `loyaltyMode` avec les mêmes valeurs.
    loyaltyMode: r.loyaltyType ?? 'stamps',
    stampsRequired: asInt('goal') ?? 10,
    rewardDescription: asString('reward_description'),
    googleReviewUrl: asString('google_review_url'),
    showReviewButton: config['show_review_button'] == true,
    stampDesignType: asString('stamp_design_type') ?? 'check',
    stampEmoji: asString('stamp_emoji') ?? '✨',
    stampIcon: asString('stamp_icon') ?? 'check_rounded',
    cardDecorationPattern: asString('card_decoration_pattern') ?? 'none',
    cardGradientType: asString('card_gradient_type') ?? 'linear',
    plan: r.plan,
    smsRemaining: r.smsCredits,
    createdAt: DateTime.now(),
  );
}
