// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$archivedCampaignsHash() => r'ca154c20196d2a724709df6587b608c58cd68e7d';

/// See also [archivedCampaigns].
@ProviderFor(archivedCampaigns)
final archivedCampaignsProvider =
    AutoDisposeFutureProvider<List<CampaignModel>>.internal(
  archivedCampaigns,
  name: r'archivedCampaignsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$archivedCampaignsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ArchivedCampaignsRef
    = AutoDisposeFutureProviderRef<List<CampaignModel>>;
String _$smsNotifierHash() => r'8a3ade5e3ad31e6ccd770fd799c9e0587f93791b';

/// Campagnes du commerce (`/merchant/campaigns`).
///
/// Copied from [SmsNotifier].
@ProviderFor(SmsNotifier)
final smsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<SmsNotifier, List<CampaignModel>>.internal(
  SmsNotifier.new,
  name: r'smsNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$smsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SmsNotifier = AutoDisposeAsyncNotifier<List<CampaignModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
