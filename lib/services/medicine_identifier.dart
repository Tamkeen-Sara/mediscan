import '../models/medicine_model.dart';
import '../models/identification_result.dart';
import 'local_cache_service.dart';
import 'realtime_db_service.dart';
import 'openfda_service.dart';

class MedicineIdentifier {
  static MedicineIdentifier? _instance;
  static MedicineIdentifier get instance =>
      _instance ??= MedicineIdentifier._();
  MedicineIdentifier._();

  final LocalCacheService _local = LocalCacheService.instance;
  final RealtimeDatabaseService _rtdb = RealtimeDatabaseService.instance;
  final OpenFdaService _fda = OpenFdaService.instance;

  /// Main entry point. Runs 3-tier lookup and computes confidence scores.
  Future<IdentificationResult> identify({
    required String rawOcrText,
    required List<String> tokens,
  }) async {
    if (rawOcrText.trim().isEmpty && tokens.isEmpty) {
      return IdentificationResult.empty();
    }

    // ── Tier 1: SQLite local cache ──────────────────────────────────
    MedicineModel? candidate = await _tierOneLookup(tokens, rawOcrText);

    // ── Tier 2: Firebase Realtime Database ─────────────────────────
    candidate ??= await _tierTwoLookup(tokens, rawOcrText);

    // ── Tier 3: OpenFDA API ────────────────────────────────────────
    candidate ??= await _tierThreeLookup(tokens, rawOcrText);

    if (candidate == null) {
      return IdentificationResult.empty();
    }

    return _scoreResult(
      medicine: candidate,
      rawOcrText: rawOcrText,
      tokens: tokens,
    );
  }

  // ─────────────── Tier Implementations ─────────────────────────────

  Future<MedicineModel?> _tierOneLookup(
      List<String> tokens, String raw) async {
    // Try longest token substrings first (more specific)
    final sorted = List<String>.from(tokens)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final token in sorted.take(10)) {
      if (token.length < 3) continue;
      final result = await _local.searchLocal(token);
      if (result != null) return result;
    }

    // Fallback: first line of OCR text (often the brand name)
    final firstLine = raw.split('\n').first.trim();
    if (firstLine.isNotEmpty) {
      final result = await _local.searchLocal(firstLine);
      if (result != null) return result;
    }
    return null;
  }

  Future<MedicineModel?> _tierTwoLookup(
      List<String> tokens, String raw) async {
    final sorted = List<String>.from(tokens)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final token in sorted.take(6)) {
      if (token.length < 3) continue;
      final results = await _rtdb.searchMedicines(token);
      if (results.isNotEmpty) {
        // Cache best match locally for next time
        await _local.upsertMedicine(results.first);
        return results.first;
      }
    }
    return null;
  }

  Future<MedicineModel?> _tierThreeLookup(
      List<String> tokens, String raw) async {
    final sorted = List<String>.from(tokens)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final token in sorted.take(4)) {
      if (token.length < 3) continue;
      final result = await _fda.searchMedicine(token);
      if (result != null) {
        // Cache in local SQLite and RTDB
        await _local.upsertMedicine(result);
        await _rtdb.cacheMedicine(result);
        return result;
      }
    }
    return null;
  }

  // ─────────────── Confidence Scoring ───────────────────────────────

  IdentificationResult _scoreResult({
    required MedicineModel medicine,
    required String rawOcrText,
    required List<String> tokens,
  }) {
    final text = rawOcrText.toLowerCase();

    // Name match score
    final brandScore =
        _fuzzyScore(medicine.brandName.toLowerCase(), text, tokens);
    final genericScore =
        _fuzzyScore(medicine.genericName.toLowerCase(), text, tokens);
    final nameScore = brandScore > genericScore ? brandScore : genericScore;

    // Dosage match score
    double dosageScore;
    if (medicine.strength.isNotEmpty) {
      final strengthLower = medicine.strength.toLowerCase();
      dosageScore = text.contains(strengthLower)
          ? 1.0
          : tokens.any((t) => t.contains(strengthLower)) ? 0.7 : 0.0;
    } else {
      dosageScore = 0.5; // no dosage info to compare against
    }

    // Brand/manufacturer score
    double brandMfgScore;
    if (medicine.manufacturer.isNotEmpty) {
      brandMfgScore =
          text.contains(medicine.manufacturer.toLowerCase()) ? 1.0 : 0.3;
    } else {
      brandMfgScore = 0.5;
    }

    // Weighted overall score
    final overallScore =
        nameScore * 0.55 + dosageScore * 0.25 + brandMfgScore * 0.20;

    return IdentificationResult(
      medicine: medicine,
      overallScore: overallScore.clamp(0.0, 1.0),
      nameScore: nameScore.clamp(0.0, 1.0),
      dosageScore: dosageScore.clamp(0.0, 1.0),
      brandScore: brandMfgScore.clamp(0.0, 1.0),
      rawOcrText: rawOcrText,
      extractedTokens: tokens,
    );
  }

  double _fuzzyScore(
      String target, String fullText, List<String> tokens) {
    // Exact substring match
    if (fullText.contains(target)) return 1.0;

    // Any token matches exactly
    if (tokens.any((t) => t == target)) return 0.95;

    // Target words all present as tokens
    final targetWords = target.split(RegExp(r'\s+'));
    if (targetWords.every((w) => tokens.any((t) => t.contains(w)))) {
      return 0.85;
    }

    // Levenshtein similarity on best matching token
    double best = 0.0;
    for (final token in tokens) {
      final sim = _levenshteinSimilarity(target, token);
      if (sim > best) best = sim;
    }
    return best;
  }

  double _levenshteinSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final maxLen = a.length > b.length ? a.length : b.length;
    final dist = _levenshtein(a, b);
    return 1.0 - dist / maxLen;
  }

  int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 0; i <= m; i++) { dp[i][0] = i; }
    for (int j = 0; j <= n; j++) { dp[0][j] = j; }

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
    }
    return dp[m][n];
  }
}
