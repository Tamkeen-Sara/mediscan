import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/medicine_model.dart';

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
      version: 1,
      onCreate: (db, version) async {
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
      },
    );
  }

  Future<void> seedIfEmpty() async {
    final db = await _database;
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM medicines'));
    if (count != null && count > 0) return;

    final jsonString =
        await rootBundle.loadString('assets/database/medicines.json');
    final List<dynamic> list = json.decode(jsonString);
    final batch = db.batch();
    for (final entry in list) {
      final m = MedicineModel.fromJson(entry as Map<String, dynamic>);
      batch.insert(
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
          'json_blob': json.encode(entry),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<MedicineModel?> searchLocal(String query) async {
    if (query.trim().isEmpty) return null;
    final db = await _database;
    final q = query.toLowerCase().trim();

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

    // Then LIKE search on brand
    if (rows.isEmpty) {
      rows = await db.query(
        'medicines',
        where: 'LOWER(brand_name) LIKE ?',
        whereArgs: ['%$q%'],
        limit: 1,
      );
    }

    // Then keywords / aliases
    if (rows.isEmpty) {
      rows = await db.rawQuery(
        '''SELECT * FROM medicines
           WHERE search_keywords LIKE ? OR aliases LIKE ?
           LIMIT 1''',
        ['%$q%', '%$q%'],
      );
    }

    if (rows.isEmpty) return null;
    final blob = rows.first['json_blob'] as String;
    return MedicineModel.fromJson(json.decode(blob) as Map<String, dynamic>);
  }

  Future<List<MedicineModel>> getAllMedicines() async {
    final db = await _database;
    final rows = await db.query('medicines');
    return rows.map((r) {
      final blob = r['json_blob'] as String;
      return MedicineModel.fromJson(
          json.decode(blob) as Map<String, dynamic>);
    }).toList();
  }

  Future<List<MedicineModel>> searchMedicines(String query) async {
    if (query.trim().isEmpty) return getAllMedicines();
    final db = await _database;
    final q = query.toLowerCase().trim();
    final rows = await db.rawQuery(
      '''SELECT * FROM medicines
         WHERE LOWER(brand_name) LIKE ? OR LOWER(generic_name) LIKE ?
            OR search_keywords LIKE ? OR aliases LIKE ?''',
      ['%$q%', '%$q%', '%$q%', '%$q%'],
    );
    return rows.map((r) {
      final blob = r['json_blob'] as String;
      return MedicineModel.fromJson(
          json.decode(blob) as Map<String, dynamic>);
    }).toList();
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
