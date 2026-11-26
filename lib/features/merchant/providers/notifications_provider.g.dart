// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$merchantNotificationsNotifierHash() =>
    r'3cd4d40afce6113397a9dee55cd8716e40da75b1';

/// Centre de notifications marchand (`/merchant/notifications`).
///
/// Copied from [MerchantNotificationsNotifier].
@ProviderFor(MerchantNotificationsNotifier)
final merchantNotificationsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    MerchantNotificationsNotifier, List<AppNotification>>.internal(
  MerchantNotificationsNotifier.new,
  name: r'merchantNotificationsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$merchantNotificationsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MerchantNotificationsNotifier
    = AutoDisposeAsyncNotifier<List<AppNotification>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
