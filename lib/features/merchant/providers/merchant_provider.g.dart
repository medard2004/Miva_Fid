// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$merchantNotifierHash() => r'd1b2778527ea78b47cda8099deaedcf528d6aafb';

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
///
/// Copied from [MerchantNotifier].
@ProviderFor(MerchantNotifier)
final merchantNotifierProvider =
    AsyncNotifierProvider<MerchantNotifier, MerchantModel?>.internal(
  MerchantNotifier.new,
  name: r'merchantNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$merchantNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MerchantNotifier = AsyncNotifier<MerchantModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
