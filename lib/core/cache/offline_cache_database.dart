import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class OfflineCacheDatabase {
  static final OfflineCacheDatabase instance = OfflineCacheDatabase._();
  OfflineCacheDatabase._();

  Database? _db;

  static const String _tableName = 'offline_cache';
  static const String _dbName = 'miva_fid_offline.db';

  // Clés standardisées
  static const String keyClientUser = 'client_user';
  static const String keyClientWallet = 'client_wallet';
  static const String keyClientRewards = 'client_rewards';
  static const String keyMerchantAccount = 'merchant_account';
  static const String keyMerchantStats = 'merchant_dashboard_stats';
  static const String keyMerchantClients = 'merchant_clients';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            key TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Sauvegarde une entrée JSON brute associée à une clé
  Future<void> put(String key, dynamic value) async {
    final db = await database;
    final jsonString = jsonEncode(value);
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      _tableName,
      {
        'key': key,
        'data': jsonString,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère et décode une entrée JSON brute
  Future<dynamic> get(String key) async {
    final db = await database;
    final results = await db.query(
      _tableName,
      columns: ['data'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (results.isEmpty) return null;
    final raw = results.first['data'] as String?;
    if (raw == null || raw.isEmpty) return null;

    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  /// Récupère la date de dernière mise à jour d'une clé
  Future<DateTime?> getLastUpdated(String key) async {
    final db = await database;
    final results = await db.query(
      _tableName,
      columns: ['updated_at'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (results.isEmpty) return null;
    final timestamp = results.first['updated_at'] as int?;
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Supprime une entrée spécifique
  Future<void> delete(String key) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  /// Purge toutes les données en cache (ex: déconnexion globale)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }

  /// Purge les données du client (profil, cartes, récompenses)
  Future<void> clearClientData() async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'key IN (?, ?, ?)',
      whereArgs: [keyClientUser, keyClientWallet, keyClientRewards],
    );
  }

  /// Purge les données du marchand
  Future<void> clearMerchantData() async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'key IN (?, ?, ?)',
      whereArgs: [keyMerchantAccount, keyMerchantStats, keyMerchantClients],
    );
  }

  // ---------------------------------------------------------
  // Helpers typés pour Client
  // ---------------------------------------------------------

  Future<void> saveClientUser(Map<String, dynamic> json) async {
    await put(keyClientUser, json);
  }

  Future<Map<String, dynamic>?> getClientUser() async {
    final res = await get(keyClientUser);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return null;
  }

  Future<void> saveClientWallet(List<dynamic> list) async {
    await put(keyClientWallet, list);
  }

  Future<List<Map<String, dynamic>>?> getClientWallet() async {
    final res = await get(keyClientWallet);
    if (res is List) {
      return res
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return null;
  }

  Future<void> saveClientRewards(List<dynamic> list) async {
    await put(keyClientRewards, list);
  }

  Future<List<Map<String, dynamic>>?> getClientRewards() async {
    final res = await get(keyClientRewards);
    if (res is List) {
      return res
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return null;
  }

  // ---------------------------------------------------------
  // Helpers typés pour Marchand
  // ---------------------------------------------------------

  Future<void> saveMerchantAccount(Map<String, dynamic> json) async {
    await put(keyMerchantAccount, json);
  }

  Future<Map<String, dynamic>?> getMerchantAccount() async {
    final res = await get(keyMerchantAccount);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return null;
  }

  Future<void> saveMerchantStats(Map<String, dynamic> json) async {
    await put(keyMerchantStats, json);
  }

  Future<Map<String, dynamic>?> getMerchantStats() async {
    final res = await get(keyMerchantStats);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return null;
  }

  Future<void> saveMerchantClients(Map<String, dynamic> json) async {
    await put(keyMerchantClients, json);
  }

  Future<Map<String, dynamic>?> getMerchantClients() async {
    final res = await get(keyMerchantClients);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return null;
  }
}
