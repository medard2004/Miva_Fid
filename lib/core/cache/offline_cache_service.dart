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

  Future<void> clearClientData() => _db.clearClientData();
  Future<void> clearMerchantData() => _db.clearMerchantData();
  Future<void> clearAll() => _db.clearAll();
}

final offlineCacheServiceProvider = Provider<OfflineCacheService>((ref) {
  final db = ref.watch(offlineCacheDatabaseProvider);
  return OfflineCacheService(db);
});
