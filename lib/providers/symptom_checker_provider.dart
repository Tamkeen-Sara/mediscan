import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medicine_model.dart';
import '../services/local_cache_service.dart';
import '../services/realtime_db_service.dart';
import '../services/symptom_match_service.dart';

class SymptomCheckerProvider extends ChangeNotifier {
  final List<String> _selectedSymptoms = [];
  SymptomMode _mode = SymptomMode.allMedicines;
  List<SymptomMatchResult> _results = [];
  bool _isSearching = false;

  List<String> get selectedSymptoms => List.unmodifiable(_selectedSymptoms);
  SymptomMode get mode => _mode;
  List<SymptomMatchResult> get results => _results;
  bool get isSearching => _isSearching;
  bool get hasSelections => _selectedSymptoms.isNotEmpty;
  int get selectionCount => _selectedSymptoms.length;

  void toggleSymptom(String symptom) {
    if (_selectedSymptoms.contains(symptom)) {
      _selectedSymptoms.remove(symptom);
    } else {
      _selectedSymptoms.add(symptom);
    }
    notifyListeners();
    _runSearch();
  }

  void setMode(SymptomMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    _runSearch();
  }

  void clearAll() {
    _selectedSymptoms.clear();
    _results = [];
    notifyListeners();
  }

  Future<void> _runSearch() async {
    if (_selectedSymptoms.isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final allMedicines = await LocalCacheService.instance.getAllMedicines();

      List<MedicineModel> savedMedicines = [];
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        savedMedicines =
            await RealtimeDatabaseService.instance.getSavedMedicines(uid);
      }

      _results = SymptomMatchService.instance.findMedicines(
        selectedSymptoms: _selectedSymptoms,
        allMedicines: allMedicines,
        savedMedicines: savedMedicines,
        mode: _mode,
      );
    } catch (_) {
      _results = [];
    }

    _isSearching = false;
    notifyListeners();
  }
}
