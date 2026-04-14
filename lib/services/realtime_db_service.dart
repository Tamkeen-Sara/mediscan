import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/medicine_model.dart';
import '../models/scan_history_model.dart';
import '../models/user_preferences_model.dart';

class RealtimeDatabaseService {
  static RealtimeDatabaseService? _instance;
  static RealtimeDatabaseService get instance =>
      _instance ??= RealtimeDatabaseService._();
  RealtimeDatabaseService._();

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ─────────────────────────── Medicine ────────────────────────────

  Future<MedicineModel?> getMedicineById(String id) async {
    try {
      final snap = await _db.ref('medicines/$id').get();
      if (!snap.exists || snap.value == null) return null;
      final map = Map<String, dynamic>.from(snap.value as Map);
      return MedicineModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<MedicineModel?> getMedicineByName(String name) async {
    try {
      final snap = await _db
          .ref('medicines')
          .orderByChild('brandName')
          .equalTo(name)
          .limitToFirst(1)
          .get();
      if (!snap.exists || snap.value == null) return null;
      final outerMap = Map<String, dynamic>.from(snap.value as Map);
      final firstValue =
          Map<String, dynamic>.from(outerMap.values.first as Map);
      return MedicineModel.fromJson(firstValue);
    } catch (_) {
      return null;
    }
  }

  Future<List<MedicineModel>> searchMedicines(String query) async {
    try {
      final snap = await _db.ref('medicines').get();
      if (!snap.exists || snap.value == null) return [];
      final outerMap = Map<String, dynamic>.from(snap.value as Map);
      final q = query.toLowerCase();
      return outerMap.values
          .map((v) =>
              MedicineModel.fromJson(Map<String, dynamic>.from(v as Map)))
          .where((m) =>
              m.brandName.toLowerCase().contains(q) ||
              m.genericName.toLowerCase().contains(q) ||
              m.searchKeywords.toLowerCase().contains(q))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheMedicine(MedicineModel medicine) async {
    try {
      await _db.ref('medicines/${medicine.id}').set(medicine.toJson());
    } catch (_) {}
  }

  Future<void> updateMedicineSummaryCache({
    required String medicineId,
    required String summaryEn,
    required String summaryUr,
    required List<String> suggestedQuestions,
  }) async {
    try {
      await _db.ref('medicines/$medicineId').update({
        'cachedSummaryEn': summaryEn,
        'cachedSummaryUr': summaryUr,
        'cachedSuggestedQuestions': suggestedQuestions,
      });
    } catch (_) {}
  }

  // ─────────────────────────── Scan History ────────────────────────

  Stream<List<ScanHistoryModel>> watchHistory(
    String uid, {
    HistoryFilter filter = HistoryFilter.all,
  }) {
    final ref = _db
        .ref('users/$uid/scan_history')
        .orderByChild('scannedAt')
        .limitToLast(200);

    return ref.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final outerMap =
          Map<String, dynamic>.from(event.snapshot.value as Map);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final last7 = today.subtract(const Duration(days: 7));
      final last30 = today.subtract(const Duration(days: 30));

      final items = outerMap.entries.map((e) {
        final map = Map<String, dynamic>.from(e.value as Map);
        map['_key'] = e.key;
        return ScanHistoryModel.fromJson(map);
      }).toList()
        ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

      switch (filter) {
        case HistoryFilter.favourites:
          return items.where((h) => h.isFavourite).toList();
        case HistoryFilter.today:
          return items
              .where((h) =>
                  h.scannedAt.isAfter(today) ||
                  h.scannedAt.isAtSameMomentAs(today))
              .toList();
        case HistoryFilter.last7days:
          return items.where((h) => h.scannedAt.isAfter(last7)).toList();
        case HistoryFilter.last30days:
          return items.where((h) => h.scannedAt.isAfter(last30)).toList();
        case HistoryFilter.all:
          return items;
      }
    });
  }

  Future<String?> saveToHistory(
      String uid, ScanHistoryModel historyItem) async {
    try {
      final ref = _db.ref('users/$uid/scan_history').push();
      await ref.set(historyItem.toJson());
      return ref.key;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateHistory(
      String uid, String pushKey, Map<String, dynamic> updates) async {
    try {
      await _db.ref('users/$uid/scan_history/$pushKey').update(updates);
    } catch (_) {}
  }

  Future<void> deleteHistory(String uid, String pushKey) async {
    try {
      await _db.ref('users/$uid/scan_history/$pushKey').remove();
    } catch (_) {}
  }

  Future<void> deleteAllHistory(String uid) async {
    try {
      await _db.ref('users/$uid/scan_history').remove();
    } catch (_) {}
  }

  Future<void> toggleFavourite(
      String uid, String pushKey, bool isFavourite) async {
    try {
      await _db
          .ref('users/$uid/scan_history/$pushKey')
          .update({'isFavourite': isFavourite});
    } catch (_) {}
  }

  Future<Set<String>> getHistoryMedicineIds(String uid) async {
    try {
      final snap = await _db
          .ref('users/$uid/scan_history')
          .orderByChild('medicineId')
          .get();
      if (!snap.exists || snap.value == null) return {};
      final outerMap = Map<String, dynamic>.from(snap.value as Map);
      return outerMap.values
          .map((v) {
            final map = Map<String, dynamic>.from(v as Map);
            return map['medicineId']?.toString() ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  // ─────────────────────────── Saved Medicines ─────────────────────

  Stream<List<MedicineModel>> watchSavedMedicines(String uid) {
    return _db.ref('users/$uid/saved_medicines').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final outerMap =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      return outerMap.values
          .map((v) =>
              MedicineModel.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
    });
  }

  Future<void> saveMedicine(String uid, MedicineModel medicine) async {
    try {
      await _db
          .ref('users/$uid/saved_medicines/${medicine.id}')
          .set(medicine.toJson());
    } catch (_) {}
  }

  Future<void> removeSavedMedicine(String uid, String medicineId) async {
    try {
      await _db.ref('users/$uid/saved_medicines/$medicineId').remove();
    } catch (_) {}
  }

  Future<bool> isMedicineSaved(String uid, String medicineId) async {
    try {
      final snap =
          await _db.ref('users/$uid/saved_medicines/$medicineId').get();
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  Future<List<MedicineModel>> getSavedMedicines(String uid) async {
    try {
      final snap = await _db.ref('users/$uid/saved_medicines').get();
      if (!snap.exists || snap.value == null) return [];
      final outerMap = Map<String, dynamic>.from(snap.value as Map);
      return outerMap.values
          .map((v) =>
              MedicineModel.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────── Preferences ─────────────────────────

  Future<UserPreferencesModel> getPreferences(String uid) async {
    try {
      final snap =
          await _db.ref('users/$uid/preferences/settings').get();
      if (!snap.exists || snap.value == null) {
        return UserPreferencesModel.defaults();
      }
      final map = Map<String, dynamic>.from(snap.value as Map);
      return UserPreferencesModel.fromJson(map);
    } catch (_) {
      return UserPreferencesModel.defaults();
    }
  }

  Future<void> savePreferences(
      String uid, UserPreferencesModel prefs) async {
    try {
      await _db
          .ref('users/$uid/preferences/settings')
          .set(prefs.toJson());
    } catch (_) {}
  }

  Future<void> deleteUserData(String uid) async {
    try {
      await _db.ref('users/$uid').remove();
    } catch (_) {}
  }
}
