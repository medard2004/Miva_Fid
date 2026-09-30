import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'offline_cache_database.dart';

final offlineCacheDatabaseProvider = Provider<OfflineCacheDatabase>((ref) {
  return OfflineCacheDatabase.instance;
});

class OfflineCacheService {
  final OfflineCacheDatabase _db;

  OfflineCacheService(this._db);

  Future<void> saveClientUser(Map<String, dynamic> json) => _db.saveClientUser(json);
  Future<Map<String, dynamic>?> getClientUser() => _db.getClientUser();

  Future<void> saveClientWallet(List<dynamic> list) => _db.saveClientWallet(list);
  Future<List<Map<String, dynamic>>?> getClientWallet() => _db.getClientWallet();

  Future<void> saveClientRewards(List<dynamic> list) => _db.saveClientRewards(list);
  Future<List<Map<String, dynamic>>?> getClientRewards() => _db.getClientRewards();

  Future<void> saveMerchantAccount(Map<String, dynamic> json) => _db.saveMerchantAccount(json);
  Future<Map<String, dynamic>?> getMerchantAccount() => _db.getMerchantAccount();

  Future<void> saveMerchantStats(Map<String, dynamic> json) => _db.saveMerchantStats(json);
  Future<Map<String, dynamic>?> getMerchantStats() => _db.getMerchantStats();

  Future<void> saveMerchantClients(Map<String, dynamic> json) => _db.saveMerchantClients(json);
  Future<Map<String, dynamic>?> getMerchantClients() => _db.getMerchantClients();

  Future<void> saveMerchantNotifications(List<dynamic> list) => _db.saveMerchantNotifications(list);
  Future<List<Map<String, dynamic>>?> getMerchantNotifications() => _db.getMerchantNotifications();

  Future<void> saveMerchantProgramme(Map<String, dynamic> json) => _db.saveMerchantProgramme(json);
  Future<Map<String, dynamic>?> getMerchantProgramme() => _db.getMerchantProgramme();

  Future<void> saveMerchantCampaigns(List<dynamic> list) => _db.saveMerchantCampaigns(list);
  Future<List<Map<String, dynamic>>?> getMerchantCampaigns() => _db.getMerchantCampaigns();

  Future<void> saveMerchantReviews(Map<String, dynamic> json) => _db.saveMerchantReviews(json);
  Future<Map<String, dynamic>?> getMerchantReviews() => _db.getMerchantReviews();

  Future<void> saveMerchantClientDetail(String cardId, Map<String, dynamic> json) =>
      _db.saveMerchantClientDetail(cardId, json);
  Future<Map<String, dynamic>?> getMerchantClientDetail(String cardId) =>
      _db.getMerchantClientDetail(cardId);

  Future<void> saveMerchantClientHistory(String cardId, List<dynamic> list) =>
      _db.saveMerchantClientHistory(cardId, list);
  Future<List<Map<String, dynamic>>?> getMerchantClientHistory(String cardId) =>
      _db.getMerchantClientHistory(cardId);

  Future<DateTime?> getLastUpdated(String key) => _db.getLastUpdated(key);
  Future<Map<String, DateTime>> getMerchantCacheTimestamps() => _db.getMerchantCacheTimestamps();

  // Mutations offline
  Future<void> insertMutation(OfflineMutation mutation) => _db.insertMutation(mutation);
  Future<List<OfflineMutation>> getPendingMutations() => _db.getPendingMutations();
  Future<void> deleteMutation(String id) => _db.deleteMutation(id);
  Future<void> updateMutationStatus(String id, String status, {int? attempts}) =>
      _db.updateMutationStatus(id, status, attempts: attempts);
  Future<int> getPendingMutationsCount() => _db.getPendingMutationsCount();

  Future<void> clearClientData() => _db.clearClientData();
  Future<void> clearMerchantData() => _db.clearMerchantData();
  Future<void> clearAll() => _db.clearAll();
}

final offlineCacheServiceProvider = Provider<OfflineCacheService>((ref) {
  final db = ref.watch(offlineCacheDatabaseProvider);
  return OfflineCacheService(db);
});
