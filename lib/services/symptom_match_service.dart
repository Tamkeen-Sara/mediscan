import '../models/medicine_model.dart';

enum SymptomMode { myMedicines, allMedicines }

class SymptomMatchResult {
  final MedicineModel medicine;
  final double matchScore;
  final List<String> matchedSymptoms;
  final bool isInHome;

  const SymptomMatchResult({
    required this.medicine,
    required this.matchScore,
    required this.matchedSymptoms,
    required this.isInHome,
  });
}

class SymptomMatchService {
  static SymptomMatchService? _instance;
  static SymptomMatchService get instance =>
      _instance ??= SymptomMatchService._();
  SymptomMatchService._();

  /// Find medicines matching [selectedSymptoms].
  ///
  /// [allMedicines] — the full database pool.
  /// [savedMedicines] — the user's saved medicines (for "In your home" badge).
  /// [mode] — whether to search only saved medicines or the whole database.
  List<SymptomMatchResult> findMedicines({
    required List<String> selectedSymptoms,
    required List<MedicineModel> allMedicines,
    required List<MedicineModel> savedMedicines,
    required SymptomMode mode,
  }) {
    if (selectedSymptoms.isEmpty) return [];

    final pool =
        mode == SymptomMode.myMedicines ? savedMedicines : allMedicines;
    if (pool.isEmpty) return [];

    final savedIds = savedMedicines.map((m) => m.id).toSet();
    final normalised =
        selectedSymptoms.map((s) => s.toLowerCase().trim()).toList();

    final results = <SymptomMatchResult>[];

    for (final medicine in pool) {
      final medSymptoms = medicine.symptomsPlain
          .map((s) => s.toLowerCase().trim())
          .toList();

      final matched = normalised
          .where((s) => _symptomMatches(s, medSymptoms))
          .toList();

      if (matched.isEmpty) continue;

      final score = matched.length / normalised.length;

      results.add(SymptomMatchResult(
        medicine: medicine,
        matchScore: score,
        matchedSymptoms: matched,
        isInHome: savedIds.contains(medicine.id),
      ));
    }

    // Sort: "in your home" first, then by match score descending
    results.sort((a, b) {
      if (a.isInHome != b.isInHome) {
        return a.isInHome ? -1 : 1;
      }
      return b.matchScore.compareTo(a.matchScore);
    });

    return results;
  }

  bool _symptomMatches(String query, List<String> medSymptoms) {
    for (final symptom in medSymptoms) {
      if (symptom == query) return true;
      if (symptom.contains(query) || query.contains(symptom)) return true;
      // Check individual words (e.g. "headache" matches "headache & migraine")
      final queryWords = query.split(RegExp(r'[\s&,/]+'));
      final symptomWords = symptom.split(RegExp(r'[\s&,/]+'));
      if (queryWords.any((w) => w.length > 3 && symptomWords.contains(w))) {
        return true;
      }
    }
    return false;
  }
}
