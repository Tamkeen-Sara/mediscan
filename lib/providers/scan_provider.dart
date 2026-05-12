import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medicine_model.dart';
import '../models/identification_result.dart';
import '../models/scan_history_model.dart';
import '../services/ocr_service.dart';
import '../services/medicine_identifier.dart';
import '../services/gemini_service.dart';
import '../services/realtime_db_service.dart';
import '../utils/app_logger.dart';

enum ScanPhase { idle, processing, result, failed }

class ScanProvider extends ChangeNotifier {
  ScanPhase _phase = ScanPhase.idle;
  String? _imagePath;
  IdentificationResult? _result;
  GeminiSummaryResult? _summaryResult;
  String _processingStep = '';
  bool _isSaved = false;

  ScanPhase get phase => _phase;
  String? get imagePath => _imagePath;
  IdentificationResult? get result => _result;
  GeminiSummaryResult? get summaryResult => _summaryResult;
  String get processingStep => _processingStep;
  bool get isSaved => _isSaved;

  MedicineModel? get medicine => _result?.medicine;

  List<String> get suggestedQuestions =>
      _summaryResult?.suggestedQuestions ??
      _result?.medicine.cachedSuggestedQuestions ??
      [];

  String get summaryEn =>
      _summaryResult?.summaryEn ??
      _result?.medicine.cachedSummaryEn ??
      _result?.medicine.summaryEn ??
      '';

  // ─────────────── Camera / image scan ──────────────────────────────────────

  Future<void> processImage(String imagePath,
      {bool autoSummarise = true}) async {
    _imagePath = imagePath;
    _phase = ScanPhase.processing;
    _result = null;
    _summaryResult = null;
    _isSaved = false;
    notifyListeners();

    try {
      _processingStep = 'extracting_text';
      notifyListeners();
      final rawText = await OcrService.instance.extractText(imagePath);
      final tokens = OcrService.instance.extractTokens(rawText);
      await _runPipeline(rawText: rawText, tokens: tokens,
          autoSummarise: autoSummarise);
    } catch (e, st) {
      AppLogger.error('Image scan pipeline failed', error: e, stackTrace: st);
      _phase = ScanPhase.failed;
      notifyListeners();
    }
  }

  // ─────────────── Manual text entry scan ───────────────────────────────────

  /// Process text the user typed manually (medicine name or packet text).
  /// Skips OCR — feeds the text directly into the identification pipeline.
  Future<void> processManualText(String text,
      {bool autoSummarise = true}) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    _imagePath = null;
    _phase = ScanPhase.processing;
    _result = null;
    _summaryResult = null;
    _isSaved = false;
    notifyListeners();

    try {
      // Skip extracting_text step — user already provided the text
      _processingStep = 'identifying_medicine';
      notifyListeners();
      final tokens = OcrService.instance.extractTokens(cleaned);
      await _runPipeline(rawText: cleaned, tokens: tokens,
          autoSummarise: autoSummarise);
    } catch (e, st) {
      AppLogger.error('Manual text scan failed', error: e, stackTrace: st);
      _phase = ScanPhase.failed;
      notifyListeners();
    }
  }

  // ─────────────── Shared pipeline (after OCR) ──────────────────────────────

  Future<void> _runPipeline({
    required String rawText,
    required List<String> tokens,
    bool autoSummarise = true,
  }) async {
    debugPrint('[SCAN] pipeline start | rawLen=${rawText.length} | tokens=${tokens.length} | firstLine=${rawText.split('\n').first}');
    _processingStep = 'identifying_medicine';
    notifyListeners();
    final identResult = await MedicineIdentifier.instance.identify(
      rawOcrText: rawText,
      tokens: tokens,
    );

    debugPrint('[SCAN] ident result | failed=${identResult.isFailed} | source=${identResult.source} | name=${identResult.medicine.displayName} | score=${identResult.overallScore}');

    if (identResult.isFailed) {
      debugPrint('[SCAN] pipeline failed at identify step');
      _phase = ScanPhase.failed;
      notifyListeners();
      return;
    }

    _result = identResult;

    if (autoSummarise) {
      _processingStep = 'generating_summary';
      notifyListeners();
      try {
        debugPrint('[SCAN] calling Gemini summary | medicine=${identResult.medicine.displayName} | source=${identResult.source} | cached=${identResult.medicine.cachedSummaryEn?.isNotEmpty == true}');
        _summaryResult = await GeminiService.instance
            .generateMedicineSummary(identResult.medicine);
        debugPrint('[SCAN] summary generated=${_summaryResult != null} | medicine=${identResult.medicine.displayName} | hasApiResult=${_summaryResult != null && _summaryResult!.summaryEn.isNotEmpty}');
      } catch (e) {
        AppLogger.warning('Gemini summary skipped', error: e);
        debugPrint('[SCAN] summary error=$e');
      }
    } else {
      debugPrint('[SCAN] autoSummarise disabled; Gemini summary not called | medicine=${identResult.medicine.displayName}');
    }

    _processingStep = 'almost_done';
    notifyListeners();
    await _saveToHistory(identResult);

    _phase = ScanPhase.result;
    notifyListeners();
  }

  // ─────────────── History ──────────────────────────────────────────────────

  Future<void> _saveToHistory(IdentificationResult identResult) async {
    try {
      var uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        uid = cred.user?.uid;
      }
      if (uid == null) return;
      final historyItem = ScanHistoryModel(
        id: '',
        medicineId: identResult.medicine.id,
        brandName: identResult.medicine.displayName,
        genericName: identResult.medicine.genericName,
        imagePath: _imagePath,
        confidence: identResult.overallScore,
        status: identResult.scanStatus,
        scannedAt: DateTime.now(),
      );
      await RealtimeDatabaseService.instance.saveToHistory(uid, historyItem);
    } catch (e) {
      AppLogger.warning('Save to history failed', error: e);
    }
  }

  // ─────────────── Saved medicines ──────────────────────────────────────────

  Future<void> saveCurrentMedicine() async {
    if (_result == null) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await RealtimeDatabaseService.instance
          .saveMedicine(uid, _result!.medicine);
      _isSaved = true;
      notifyListeners();
    } catch (e) {
      AppLogger.warning('Save medicine failed', error: e);
    }
  }

  // ─────────────── Manual / history modes ───────────────────────────────────

  void setManualMedicineFromHistory(ScanHistoryModel history) {
    final medicine = MedicineModel(
      id: history.medicineId.isNotEmpty
          ? history.medicineId
          : 'history_${history.id}',
      brandName: history.brandName,
      genericName: history.genericName,
      manufacturer: history.manufacturer,
    );
    setManualMedicine(medicine);
  }

  void setManualMedicine(MedicineModel medicine) {
    _result = IdentificationResult(
      medicine: medicine,
      overallScore: 1.0,
      nameScore: 1.0,
      dosageScore: 1.0,
      brandScore: 1.0,
      rawOcrText: '',
      extractedTokens: [],
    );
    _summaryResult = null;  // Clear cached summary from previous scan
    _phase = ScanPhase.result;
    _isSaved = false;
    notifyListeners();
  }

  /// Generate summary for the current medicine (used when viewing details from symptom checker)
  Future<void> generateSummaryForCurrentMedicine() async {
    if (_result?.medicine == null) return;
    try {
      _summaryResult = await GeminiService.instance
          .generateMedicineSummary(_result!.medicine);
      notifyListeners();
      debugPrint('[SCAN] summary generated for manual medicine=${_summaryResult != null}');
    } catch (e) {
      AppLogger.warning('Gemini summary failed for manual medicine', error: e);
      debugPrint('[SCAN] summary error=$e');
    }
  }

  void reset() {
    _phase = ScanPhase.idle;
    _imagePath = null;
    _result = null;
    _summaryResult = null;
    _processingStep = '';
    _isSaved = false;
    notifyListeners();
  }
}
