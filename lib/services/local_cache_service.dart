import 'dart:convert';
import '../utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/medicine_model.dart';

// ── Top-level helpers so compute() can send them to a background isolate ──

List<Map<String, dynamic>> _buildSeedRows(String jsonString) {
  final list = json.decode(jsonString) as List;
  return list.map((e) {
    final entry = e as Map<String, dynamic>;
    final m = MedicineModel.fromJson(entry);
    return <String, dynamic>{
      'id': m.id,
      'brand_name': m.brandName,
      'generic_name': m.genericName,
      'manufacturer': m.manufacturer,
      'category': m.category,
      'strength': m.strength,
      'dosage_form': m.dosageForm,
      'search_keywords': m.searchKeywords.toLowerCase(),
      'aliases': m.aliases.join(' ').toLowerCase(),
      'json_blob': json.encode(entry),
    };
  }).toList();
}

List<MedicineModel> _decodeBlobs(List<String> blobs) {
  return blobs
      .map((b) =>
          MedicineModel.fromJson(json.decode(b) as Map<String, dynamic>))
      .toList();
}

class LocalCacheService {
  static LocalCacheService? _instance;
  static LocalCacheService get instance =>
      _instance ??= LocalCacheService._();
  LocalCacheService._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'mediscan.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createSchema(db);
        await _addV2Indices(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _addV2Indices(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE medicines (
        id TEXT PRIMARY KEY,
        brand_name TEXT NOT NULL,
        generic_name TEXT NOT NULL,
        manufacturer TEXT,
        category TEXT,
        strength TEXT,
        dosage_form TEXT,
        search_keywords TEXT,
        aliases TEXT,
        json_blob TEXT NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_brand ON medicines(brand_name COLLATE NOCASE)');
    await db.execute(
        'CREATE INDEX idx_generic ON medicines(generic_name COLLATE NOCASE)');
  }

  Future<void> _addV2Indices(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_keywords ON medicines(search_keywords)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_aliases ON medicines(aliases)');
  }

  Future<void> seedIfEmpty() async {
    final db = await _database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM medicines'));
    if (count != null && count > 0) return;

    // Load base + extended databases in parallel, parse in background isolates.
    final results = await Future.wait([
      rootBundle.loadString('assets/database/medicines.json'),
      rootBundle.loadString('assets/database/medicines_extra.json'),
    ]);

    final allRows = await Future.wait([
      compute(_buildSeedRows, results[0]),
      compute(_buildSeedRows, results[1]),
    ]);

    final batch = db.batch();
    for (final row in [...allRows[0], ...allRows[1]]) {
      batch.insert('medicines', row,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearLocalCache() async {
    final db = _db;
    _db = null;
    try {
      await db?.close();
    } catch (_) {}

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'mediscan.db');
    try {
      await deleteDatabase(path);
    } catch (_) {}
  }

  Future<MedicineModel?> searchLocal(String query) async {
    if (query.trim().isEmpty) return null;
    final db = await _database;
    final q = query.toLowerCase().trim();
    AppLogger.info('LocalCache.searchLocal — q=$q');

    // Exact brand name match first
    List<Map<String, dynamic>> rows = await db.query(
      'medicines',
      where: 'LOWER(brand_name) = ?',
      whereArgs: [q],
      limit: 1,
    );

    // Then generic name match
    if (rows.isEmpty) {
      rows = await db.query(
        'medicines',
        where: 'LOWER(generic_name) = ?',
        whereArgs: [q],
        limit: 1,
      );
    }

    // Then strict whole-word brand match only.
    if (rows.isEmpty) {
      rows = await db.query(
        'medicines',
        where: 'LOWER(brand_name) LIKE ? OR LOWER(brand_name) LIKE ?',
        whereArgs: ['$q %', '% $q'],
        limit: 1,
      );
    }

    // Then strict keyword / alias whole-token matching only.
    if (rows.isEmpty) {
      rows = await db.rawQuery(
        '''SELECT * FROM medicines
           WHERE search_keywords LIKE ? OR search_keywords LIKE ? OR search_keywords LIKE ?
              OR aliases LIKE ? OR aliases LIKE ? OR aliases LIKE ?
           LIMIT 1''',
        ['%$q %', '% $q %', '% $q', '%$q %', '% $q %', '% $q'],
      );
    }

    if (rows.isEmpty) return null;
    final blob = rows.first['json_blob'] as String;
    AppLogger.info('LocalCache.searchLocal matched id=${json.decode(blob)['id']} brand=${json.decode(blob)['brand_name']}');
    return MedicineModel.fromJson(json.decode(blob) as Map<String, dynamic>);
  }

  Future<List<MedicineModel>> getAllMedicines({int limit = 80}) async {
    final db = await _database;
    final rows = await db.query('medicines', limit: limit);
    final blobs = rows.map((r) => r['json_blob'] as String).toList();
    return compute(_decodeBlobs, blobs);
  }

  Future<List<MedicineModel>> searchMedicines(String query) async {
    // Empty query returns nothing — callers should show a prompt instead of
    // loading the entire database onto the main thread.
    if (query.trim().isEmpty) return [];
    final db = await _database;
    final q = query.toLowerCase().trim();
     AppLogger.info('LocalCache.searchMedicines — q=$q');
     final rows = await db.rawQuery(
      '''SELECT * FROM medicines
         WHERE LOWER(brand_name) LIKE ? OR LOWER(generic_name) LIKE ?
            OR search_keywords LIKE ? OR aliases LIKE ?
         LIMIT 50''',
      ['%$q%', '%$q%', '%$q%', '%$q%'],
    );
    final blobs = rows.map((r) => r['json_blob'] as String).toList();
    return compute(_decodeBlobs, blobs);
  }

  Future<void> upsertMedicine(MedicineModel m) async {
    final db = await _database;
    await db.insert(
      'medicines',
      {
        'id': m.id,
        'brand_name': m.brandName,
        'generic_name': m.genericName,
        'manufacturer': m.manufacturer,
        'category': m.category,
        'strength': m.strength,
        'dosage_form': m.dosageForm,
        'search_keywords': m.searchKeywords.toLowerCase(),
        'aliases': m.aliases.join(' ').toLowerCase(),
        'json_blob': json.encode(m.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
