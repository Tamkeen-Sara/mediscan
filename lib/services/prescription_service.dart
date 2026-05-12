import '../models/medicine_model.dart';
import '../models/prescription_models.dart';
import '../models/scan_history_model.dart';
import 'medicine_identifier.dart';
import 'gemini_service.dart';
import 'ocr_service.dart';
import 'realtime_db_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrescriptionService {
  static PrescriptionService? _instance;
  static PrescriptionService get instance => _instance ??= PrescriptionService._();
  PrescriptionService._();

  Future<PrescriptionAnalysisResult> analyzePrescriptionImage(String imagePath) async {
    final ocrText = await OcrService.instance.extractText(imagePath);
    final entries = await _extractEntries(ocrText);
    final warnings = _buildInteractionWarnings(entries);

    return PrescriptionAnalysisResult(
      rawOcrText: ocrText,
      entries: entries,
      interactionWarnings: warnings,
    );
  }

  Future<List<PrescriptionEntry>> _extractEntries(String ocrText) async {
    if (ocrText.trim().isEmpty) return const [];

    final aiEntries = await GeminiService.instance.extractPrescriptionEntries(ocrText);
    final filteredAiEntries = aiEntries.where(_isLikelyPrescriptionEntry).toList();
    final normalizedAiEntries = await _normalizeEntries(filteredAiEntries);
    if (normalizedAiEntries.isNotEmpty) return normalizedAiEntries;

    final fallbackEntries = _fallbackParseEntries(ocrText).where(_isLikelyPrescriptionEntry).toList();
    final normalizedFallbackEntries = await _normalizeEntries(fallbackEntries);
    return normalizedFallbackEntries.isNotEmpty ? normalizedFallbackEntries : fallbackEntries;
  }

  Future<PrescriptionEntry> generateExplanationForEntry(
      PrescriptionEntry entry) async {
    if (entry.rawName.trim().isEmpty) return entry;

    final lookupText = [
      entry.rawName,
      entry.dosageText,
      entry.frequencyText,
      entry.notes,
    ].where((part) => part.trim().isNotEmpty).join(' ');

    final tokens = lookupText
        .split(RegExp(r'[\s,\/\-\(\)\[\]\|:;]+'))
        .map((token) => token.trim().toLowerCase())
        .where((token) => token.isNotEmpty)
        .toList();

    try {
      final identResult = await MedicineIdentifier.instance.identify(
        rawOcrText: lookupText,
        tokens: tokens,
      );

      final medicine = identResult.isFailed
          ? MedicineModel(
              id: _buildFallbackMedicineId(entry.rawName),
              brandName: entry.rawName,
              genericName: entry.rawName,
              dosageForm: entry.dosageText,
              strength: entry.dosageText,
              dosageAdults: entry.frequencyText,
              source: 'Prescription fallback',
            )
          : identResult.medicine;

      final summary = await GeminiService.instance.generateMedicineSummary(medicine);
      if (summary != null) {
        return entry.copyWith(
          explanationEn: summary.summaryEn,
          explanationUr: summary.summaryUr,
        );
      }
    } catch (_) {
      // Fall through to returning the original entry.
    }

    return entry;
  }

  Future<void> saveAnalysisToHistory(
    PrescriptionAnalysisResult result, {
    String? imagePath,
  }) async {
    try {
      var uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        uid = cred.user?.uid;
      }
      if (uid == null) return;

      final primary = result.entries.isNotEmpty
          ? result.entries.first
          : const PrescriptionEntry(rawName: 'Prescription Scan');

      final medicineName = primary.rawName.trim().isNotEmpty
          ? primary.rawName.trim()
          : 'Prescription Scan';

      final historyItem = ScanHistoryModel(
        id: '',
        medicineId: _buildFallbackMedicineId(medicineName),
        brandName: medicineName,
        genericName: medicineName,
        manufacturer: 'Prescription',
        confidence: result.entries.isNotEmpty ? 0.72 : 0.5,
        status: result.entries.isNotEmpty
            ? ScanStatus.mediumConfidence
            : ScanStatus.lowConfidence,
        scannedAt: DateTime.now(),
        imagePath: imagePath,
        rawOcrText: result.rawOcrText,
        notes: 'Prescription scan (${result.entries.length} medicines)',
      );

      await RealtimeDatabaseService.instance.saveToHistory(uid, historyItem);
    } catch (_) {
      // best-effort history write for prescription scans
    }
  }

  Future<List<PrescriptionEntry>> _normalizeEntries(
      List<PrescriptionEntry> entries) async {
    if (entries.isEmpty) return const [];

    final normalized = <PrescriptionEntry>[];
    for (final entry in entries.take(6)) {
      final lookupText = [
        entry.rawName,
        entry.dosageText,
        entry.frequencyText,
        entry.notes,
      ].where((part) => part.trim().isNotEmpty).join(' ');

      final tokens = lookupText
          .split(RegExp(r'[\s,\/\-\(\)\[\]\|:;]+'))
          .map((token) => token.trim().toLowerCase())
          .where((token) => token.isNotEmpty)
          .toList();

      final ident = await MedicineIdentifier.instance.identify(
        rawOcrText: lookupText,
        tokens: tokens,
      );

      if (ident.isFailed || ident.overallScore < 0.45) {
        continue;
      }

      final medicine = ident.medicine;
      normalized.add(entry.copyWith(
        rawName: medicine.displayName.isNotEmpty ? medicine.displayName : entry.rawName,
        dosageText: entry.dosageText.isNotEmpty ? entry.dosageText : medicine.strength,
      ));
    }

    return _dedupeEntries(normalized);
  }

  List<PrescriptionEntry> _fallbackParseEntries(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final out = <PrescriptionEntry>[];
    for (final line in lines) {
      final hasLetters = RegExp(r'[A-Za-z]').hasMatch(line);
      if (!hasLetters) continue;
      if (line.length < 4) continue;

      final dosageMatch = RegExp(r'(\d+(?:\.\d+)?)\s?(mg|mcg|g|ml|iu)', caseSensitive: false)
          .firstMatch(line);
      final dosage = dosageMatch == null ? '' : '${dosageMatch.group(1)}${dosageMatch.group(2)}';

      out.add(PrescriptionEntry(
        rawName: line,
        dosageText: dosage,
      ));

      if (out.length >= 6) break;
    }
    return out;
  }

  bool _isLikelyPrescriptionEntry(PrescriptionEntry entry) {
    final value = entry.rawName.trim();
    if (value.isEmpty || value.length < 3) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) return false;

    final lower = value.toLowerCase();
    const noiseWords = [
      'patient',
      'name',
      'doctor',
      'dr',
      'signature',
      'date',
      'age',
      'male',
      'female',
      'tablet',
      'tablets',
      'capsule',
      'capsules',
      'take',
      'daily',
      'twice',
      'thrice',
      'morning',
      'night',
      'after food',
      'before food',
    ];

    if (noiseWords.any((word) => lower.contains(word))) {
      return false;
    }

    return true;
  }

  List<PrescriptionEntry> _dedupeEntries(List<PrescriptionEntry> entries) {
    final seen = <String>{};
    final out = <PrescriptionEntry>[];
    for (final entry in entries) {
      final key = entry.rawName.toLowerCase().trim();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      out.add(entry);
    }
    return out;
  }

  String _buildFallbackMedicineId(String rawName) {
    final slug = rawName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return slug.isEmpty ? 'prescription_fallback' : 'prescription_$slug';
  }

  List<String> _buildInteractionWarnings(List<PrescriptionEntry> entries) {
    if (entries.length < 2) return const [];
    final warnings = <String>[];

    final names = entries.map((e) => e.rawName.toLowerCase()).toList();
    final hasNsaid = names.any((n) => n.contains('ibuprofen') || n.contains('diclofenac') || n.contains('naproxen') || n.contains('aspirin'));
    final hasBloodThinner = names.any((n) => n.contains('warfarin') || n.contains('clopidogrel') || n.contains('rivaroxaban'));

    if (hasNsaid && hasBloodThinner) {
      warnings.add('Potential bleeding risk: painkillers like ibuprofen/diclofenac with blood thinners should be reviewed.');
    }

    for (var i = 0; i < names.length; i++) {
      for (var j = i + 1; j < names.length; j++) {
        if (names[i] == names[j]) {
          warnings.add('Duplicate medicine appears in prescription: ${entries[i].rawName}.');
        }
      }
    }

    return warnings;
  }
}
