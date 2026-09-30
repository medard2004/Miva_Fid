import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class OfflineCacheDatabase {
  static final OfflineCacheDatabase instance = OfflineCacheDatabase._();
  OfflineCacheDatabase._();

  Database? _db;

  static const String _tableName = 'offline_cache';
  static const String _mutationsTable = 'offline_mutations';
  static const String _dbName = 'miva_fid_offline.db';

  // Clés standardisées
  static const String keyClientUser = 'client_user';
  static const String keyClientWallet = 'client_wallet';
  static const String keyClientRewards = 'client_rewards';
  static const String keyMerchantAccount = 'merchant_account';
  static const String keyMerchantStats = 'merchant_dashboard_stats';
  static const String keyMerchantClients = 'merchant_clients';
  static const String keyMerchantNotifications = 'merchant_notifications';
  static const String keyMerchantProgramme = 'merchant_programme';
  static const String keyMerchantCampaigns = 'merchant_campaigns';
  static const String keyMerchantReviews = 'merchant_reviews';

  static String keyMerchantClientDetail(String cardId) =>
      'merchant_client_detail_$cardId';
  static String keyMerchantClientHistory(String cardId) =>
      'merchant_client_history_$cardId';

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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            key TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_mutationsTable (
            id TEXT PRIMARY KEY,
            action_type TEXT NOT NULL,
            card_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'pending'
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_mutationsTable (
              id TEXT PRIMARY KEY,
              action_type TEXT NOT NULL,
              card_id TEXT NOT NULL,
              payload TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              attempts INTEGER NOT NULL DEFAULT 0,
              status TEXT NOT NULL DEFAULT 'pending'
            )
          ''');
        }
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
    } catch (e) {
      debugPrint('[offline_cache_database] Erreur décodage JSON pour clé $key: $e');
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
      where: 'key LIKE ?',
      whereArgs: ['merchant_%'],
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
    final config = json['loyalty_config'];
    if (config is Map<String, dynamic>) {
      await saveMerchantProgramme(config);
    } else if (config is Map) {
      await saveMerchantProgramme(Map<String, dynamic>.from(config));
    }
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

  // ---------------------------------------------------------
  // Notifications marchand
  // ---------------------------------------------------------

  Future<void> saveMerchantNotifications(List<dynamic> list) async {
    await put(keyMerchantNotifications, list);
  }

  Future<List<Map<String, dynamic>>?> getMerchantNotifications() async {
    final res = await get(keyMerchantNotifications);
    if (res is List) {
      return res
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return null;
  }

  // ---------------------------------------------------------
  // Programme de fidélité (config) marchand
  // ---------------------------------------------------------

  Future<void> saveMerchantProgramme(Map<String, dynamic> json) async {
    await put(keyMerchantProgramme, json);
  }

  Future<Map<String, dynamic>?> getMerchantProgramme() async {
    final res = await get(keyMerchantProgramme);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return null;
  }

  // ---------------------------------------------------------
  // Campagnes SMS marchand
  // ---------------------------------------------------------

  Future<void> saveMerchantCampaigns(List<dynamic> list) async {
    await put(keyMerchantCampaigns, list);
  }

  Future<List<Map<String, dynamic>>?> getMerchantCampaigns() async {
    final res = await get(keyMerchantCampaigns);
    if (res is List) {
      return res
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return null;
  }

  // ---------------------------------------------------------
  // Avis clients marchand
  // ---------------------------------------------------------

  Future<void> saveMerchantReviews(Map<String, dynamic> json) async {
    await put(keyMerchantReviews, json);
  }

  Future<Map<String, dynamic>?> getMerchantReviews() async {
    final res = await get(keyMerchantReviews);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return null;
  }

  // ---------------------------------------------------------
  // Fiche détaillée d'un client et historique
  // ---------------------------------------------------------

  Future<void> saveMerchantClientDetail(
      String cardId, Map<String, dynamic> json) async {
    await put(keyMerchantClientDetail(cardId), json);
  }

  Future<Map<String, dynamic>?> getMerchantClientDetail(String cardId) async {
    final res = await get(keyMerchantClientDetail(cardId));
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return null;
  }

  Future<void> saveMerchantClientHistory(
      String cardId, List<dynamic> list) async {
    await put(keyMerchantClientHistory(cardId), list);
  }

  Future<List<Map<String, dynamic>>?> getMerchantClientHistory(
      String cardId) async {
    final res = await get(keyMerchantClientHistory(cardId));
    if (res is List) {
      return res
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return null;
  }

  // ---------------------------------------------------------
  // Méta-données du cache (pour la page hors-ligne)
  // ---------------------------------------------------------

  /// Renvoie un map { clé_cache: DateTime_dernière_MAJ } pour toutes les
  /// entrées marchand existantes.
  Future<Map<String, DateTime>> getMerchantCacheTimestamps() async {
    final db = await database;
    final keys = [
      keyMerchantAccount,
      keyMerchantStats,
      keyMerchantClients,
      keyMerchantNotifications,
      keyMerchantProgramme,
      keyMerchantCampaigns,
      keyMerchantReviews,
    ];
    final placeholders = keys.map((_) => '?').join(', ');
    final rows = await db.query(
      _tableName,
      columns: ['key', 'updated_at'],
      where: 'key IN ($placeholders)',
      whereArgs: keys,
    );
    final result = <String, DateTime>{};
    for (final row in rows) {
      final k = row['key'] as String;
      final ts = row['updated_at'] as int?;
      if (ts != null) result[k] = DateTime.fromMillisecondsSinceEpoch(ts);
    }
    return result;
  }

  // ---------------------------------------------------------
  // Mutations offline (actions en attente de synchronisation)
  // ---------------------------------------------------------

  Future<void> insertMutation(OfflineMutation mutation) async {
    final db = await database;
    await db.insert(
      _mutationsTable,
      mutation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OfflineMutation>> getPendingMutations() async {
    final db = await database;
    final rows = await db.query(
      _mutationsTable,
      where: 'status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => OfflineMutation.fromMap(r)).toList();
  }

  Future<void> deleteMutation(String id) async {
    final db = await database;
    await db.delete(
      _mutationsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateMutationStatus(
    String id,
    String status, {
    int? attempts,
  }) async {
    final db = await database;
    final values = <String, dynamic>{'status': status};
    if (attempts != null) {
      values['attempts'] = attempts;
    }
    await db.update(
      _mutationsTable,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getPendingMutationsCount() async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_mutationsTable WHERE status IN (?, ?)',
      ['pending', 'failed'],
    );
    if (res.isNotEmpty) {
      return (res.first['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}

/// Modèle d'une action hors ligne à synchroniser
class OfflineMutation {
  final String id;
  final String actionType;
  final String cardId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
  final String status;

  OfflineMutation({
    required this.id,
    required this.actionType,
    required this.cardId,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'action_type': actionType,
        'card_id': cardId,
        'payload': jsonEncode(payload),
        'created_at': createdAt.millisecondsSinceEpoch,
        'attempts': attempts,
        'status': status,
      };

  factory OfflineMutation.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> payloadMap = {};
    try {
      final raw = map['payload'] as String?;
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) payloadMap = decoded;
        if (decoded is Map) payloadMap = Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      debugPrint('[offline_cache_database] Erreur parsing payload mutation: $e');
    }

    return OfflineMutation(
      id: map['id'] as String,
      actionType: map['action_type'] as String,
      cardId: map['card_id'] as String,
      payload: payloadMap,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending',
    );
  }
}
