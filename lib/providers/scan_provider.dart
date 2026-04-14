import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medicine_model.dart';
import '../models/identification_result.dart';
import '../models/scan_history_model.dart';
import '../services/ocr_service.dart';
import '../services/medicine_identifier.dart';
import '../services/gemini_service.dart';
import '../services/realtime_db_service.dart';

/// Processing phase for the scan pipeline — distinct from ScanStatus in the model.
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

  Future<void> processImage(String imagePath,
      {bool autoSummarise = true}) async {
    _imagePath = imagePath;
    _phase = ScanPhase.processing;
    _result = null;
    _summaryResult = null;
    _isSaved = false;
    notifyListeners();

    try {
      // Step 1: OCR
      _processingStep = 'extracting_text';
      notifyListeners();
      final rawText = await OcrService.instance.extractText(imagePath);
      final tokens = OcrService.instance.extractTokens(rawText);

      // Step 2: Identify
      _processingStep = 'identifying_medicine';
      notifyListeners();
      final identResult = await MedicineIdentifier.instance.identify(
        rawOcrText: rawText,
        tokens: tokens,
      );

      if (identResult.isFailed) {
        _phase = ScanPhase.failed;
        notifyListeners();
        return;
      }

      _result = identResult;

      // Step 3: Gemini summary — best-effort, never blocks the pipeline
      if (autoSummarise) {
        _processingStep = 'generating_summary';
        notifyListeners();
        try {
          _summaryResult = await GeminiService.instance
              .generateMedicineSummary(identResult.medicine);
        } catch (_) {
          // Gemini failed — continue without summary, results still show
        }
      }

      // Step 4: Save to history
      _processingStep = 'almost_done';
      notifyListeners();
      await _saveToHistory(identResult);

      _phase = ScanPhase.result;
      notifyListeners();
    } catch (_) {
      // Any unhandled exception (network, Firebase, etc.) → show scan-failed
      _phase = ScanPhase.failed;
      notifyListeners();
    }
  }

  Future<void> _saveToHistory(IdentificationResult identResult) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
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
    } catch (_) {}
  }

  Future<void> saveCurrentMedicine() async {
    if (_result == null) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await RealtimeDatabaseService.instance
          .saveMedicine(uid, _result!.medicine);
      _isSaved = true;
      notifyListeners();
    } catch (_) {}
  }

  /// Used by history screen when full medicine data isn't in local cache.
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

  /// Used by manual edit screen or info mode (Addendum 2).
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
    _phase = ScanPhase.result;
    _isSaved = false;
    notifyListeners();
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
