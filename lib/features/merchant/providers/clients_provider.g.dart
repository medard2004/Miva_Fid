// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clientsNotifierHash() => r'b7e52cc4d9bf2acd2434175af42528e383844f6f';

/// Clientèle du commerce connecté (`GET /merchant/clients`, paginé).
///
/// Recherche, inactivité, niveau (clé canonique) et cycles terminés sont
/// filtrés côté serveur ; chaque changement de filtre repart de la page 1.
///
/// Copied from [ClientsNotifier].
@ProviderFor(ClientsNotifier)
final clientsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    ClientsNotifier, ClientsListState>.internal(
  ClientsNotifier.new,
  name: r'clientsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$clientsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ClientsNotifier = AutoDisposeAsyncNotifier<ClientsListState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
