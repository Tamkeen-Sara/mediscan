import 'medicine_model.dart';
import 'scan_history_model.dart';

class IdentificationResult {
  final MedicineModel medicine;
  final double overallScore;
  final double nameScore;
  final double dosageScore;
  final double brandScore;
  final String rawOcrText;
  final List<String> extractedTokens;
  final String? source; // e.g., "Local Cache", "Firebase", "Gemini"

  const IdentificationResult({
    required this.medicine,
    required this.overallScore,
    this.nameScore = 0.0,
    this.dosageScore = 0.0,
    this.brandScore = 0.0,
    this.rawOcrText = '',
    this.extractedTokens = const [],
    this.source,
  });

  ScanStatus get scanStatus {
    if (overallScore >= 0.80) return ScanStatus.highConfidence;
    if (overallScore >= 0.50) return ScanStatus.mediumConfidence;
    if (overallScore > 0.0) return ScanStatus.lowConfidence;
    return ScanStatus.failed;
  }

  bool get isHighConfidence => overallScore >= 0.80;
  bool get isMediumConfidence =>
      overallScore >= 0.50 && overallScore < 0.80;
  bool get isLowConfidence =>
      overallScore > 0.0 && overallScore < 0.50;
  bool get isFailed => overallScore == 0.0;

  int get confidencePercent => (overallScore * 100).round();

  static IdentificationResult empty() => const IdentificationResult(
        medicine: MedicineModel(id: '', brandName: '', genericName: ''),
        overallScore: 0.0,
        source: null,
      );
}
