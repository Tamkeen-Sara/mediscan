import '../models/medicine_model.dart';
import '../models/identification_result.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';
import 'local_cache_service.dart';
import 'realtime_db_service.dart';
import 'openfda_service.dart';
import 'drap_service.dart';
import 'rxnorm_service.dart';
import 'gemini_service.dart';
/// 5-tier medicine identification pipeline:
///
///  Tier 1 — SQLite local cache  (fastest, offline, 150 + medicines)
///  Tier 2 — Firebase RTDB       (shared cloud cache of previously identified meds)
///  Tier 3 — DRAP portal         (Pakistani drug register, free web scrape)
///  Tier 4 — RxNorm / NIH        (free, stable, strong for generic names)
///  Tier 5 — OpenFDA             (US database; useful for international generics)
class MedicineIdentifier {
  static MedicineIdentifier? _instance;
  static MedicineIdentifier get instance =>
      _instance ??= MedicineIdentifier._();
  MedicineIdentifier._();

  final LocalCacheService _local = LocalCacheService.instance;
  final RealtimeDatabaseService _rtdb = RealtimeDatabaseService.instance;
  final OpenFdaService _fda = OpenFdaService.instance;
  final DrapService _drap = DrapService.instance;
  final RxNormService _rxnorm = RxNormService.instance;

  static const Set<String> _noiseTokens = {
    'tablet',
    'tablets',
    'tab',
    'tabs',
    'capsule',
    'capsules',
    'cap',
    'caps',
    'syrup',
    'suspension',
    'injection',
    'injectable',
    'inj',
    'mg',
    'mcg',
    'g',
    'ml',
    'iu',
    'pack',
    'strip',
    'blister',
    'film',
    'coated',
    'oral',
    'solution',
    'medicine',
    'medicines',
    'dose',
    'doses',
  };

  Future<IdentificationResult> identify({
    required String rawOcrText,
    required List<String> tokens,
  }) async {
    debugPrint('[ID] identify start | rawLen=${rawOcrText.length} | tokens=${tokens.length}');
    final usefulCount = tokens.where(_isUsefulLookupToken).length;
    debugPrint('[ID] useful tokens=$usefulCount/${tokens.length}');
    AppLogger.info('MedicineIdentifier.identify called — tokens=${tokens.length} rawPreview=${rawOcrText.split('\n').first}');
    if (rawOcrText.trim().isEmpty && tokens.isEmpty) {
      return IdentificationResult.empty();
    }

    IdentificationResult? tryTier(
        MedicineModel? candidate, String source) {
      if (candidate == null) return null;
      final res = _scoreResult(medicine: candidate, rawOcrText: rawOcrText, tokens: tokens);
        AppLogger.info('tryTier computed — source=$source medicine=${candidate.displayName} overall=${res.overallScore}');
      final lowEvidence = usefulCount <= 1;
      final hasDirectNameEvidence = _hasDirectNameEvidence(candidate, tokens, rawOcrText);
      final sourceThreshold = switch (source) {
        'Local Cache' || 'Firebase' => hasDirectNameEvidence ? (lowEvidence ? 0.9 : 0.62) : 1.01,
        'DRAP' || 'RxNorm' || 'OpenFDA' => 0.5,
        _ => 0.5,
      };
      final nameThreshold = switch (source) {
        'Local Cache' || 'Firebase' => hasDirectNameEvidence ? (lowEvidence ? 0.95 : 0.8) : 1.01,
        'DRAP' || 'RxNorm' || 'OpenFDA' => 0.0,
        _ => 0.0,
      };

      if (res.overallScore >= sourceThreshold && res.nameScore >= nameThreshold) {
        return _attachSource(res, source);
      }
      AppLogger.info('tryTier rejected — source=$source medicine=${candidate.displayName} overall=${res.overallScore}');
      return null;
    }

    // Try all 5 tiers; return early if high confidence (>= 0.5) found
    var tierResult = await _tryTierOneLookup(tokens, rawOcrText, tryTier);
    debugPrint('[ID] tier1 result=${tierResult?.medicine.displayName} score=${tierResult?.overallScore}');
    if (tierResult != null) return tierResult;

    tierResult = await _tryTierTwoLookup(tokens, rawOcrText, tryTier);
    debugPrint('[ID] tier2 result=${tierResult?.medicine.displayName} score=${tierResult?.overallScore}');
    if (tierResult != null) return tierResult;

    tierResult = await _tryTierThreeLookup(tokens, tryTier);
    debugPrint('[ID] tier3 result=${tierResult?.medicine.displayName} score=${tierResult?.overallScore}');
    if (tierResult != null) return tierResult;

    tierResult = await _tryTierFourLookup(tokens, tryTier);
    debugPrint('[ID] tier4 result=${tierResult?.medicine.displayName} score=${tierResult?.overallScore}');
    if (tierResult != null) return tierResult;

    tierResult = await _tryTierFiveLookup(tokens, tryTier);
    debugPrint('[ID] tier5 result=${tierResult?.medicine.displayName} score=${tierResult?.overallScore}');
    if (tierResult != null) return tierResult;

    // Tier 6: Gemini fallback. This only runs after all cache/database tiers
    // have failed to find a good match.
    final geminiMed = await GeminiService.instance.identifyMedicineFromOcr(rawOcrText);
    debugPrint('[ID] tier6 gemini result=${geminiMed?.displayName}');
    if (geminiMed != null) {
      return IdentificationResult(
        medicine: geminiMed,
        overallScore: 0.8, // High confidence as it's directly extracted by LLM
        nameScore: 0.8,
        dosageScore: 0.8,
        brandScore: 0.8,
        rawOcrText: rawOcrText,
        extractedTokens: tokens,
        source: 'Gemini AI',
      );
    }

    // Final offline-safe fallback: build a best-effort medicine guess from OCR
    // tokens so the user can continue via manual correction instead of a hard fail.
    final heuristic = _buildOcrHeuristic(rawOcrText, tokens);
    if (heuristic != null) {
      debugPrint('[ID] heuristic fallback result=${heuristic.displayName}');
      return IdentificationResult(
        medicine: heuristic,
        overallScore: 0.35,
        nameScore: 0.35,
        dosageScore: 0.2,
        brandScore: 0.2,
        rawOcrText: rawOcrText,
        extractedTokens: tokens,
        source: 'OCR Heuristic',
      );
    }

    debugPrint('[ID] FINAL: failed (all tiers returned null/rejected)');

    return IdentificationResult.empty();
  }

  /// Helper to attach source to IdentificationResult
  IdentificationResult _attachSource(IdentificationResult result, String? source) {
    return IdentificationResult(
      medicine: result.medicine,
      overallScore: result.overallScore,
      nameScore: result.nameScore,
      dosageScore: result.dosageScore,
      brandScore: result.brandScore,
      rawOcrText: result.rawOcrText,
      extractedTokens: result.extractedTokens,
      source: source,
    );
  }

  // ─────────────── Tier Wrappers (track source and return early on high confidence) ──

  Future<IdentificationResult?> _tryTierOneLookup(
      List<String> tokens,
      String raw,
      IdentificationResult? Function(MedicineModel?, String) tryTier) async {
    AppLogger.info('Tier1: starting local cache lookup — tokens=${tokens.length}');
    final result = await _tierOneLookup(tokens, raw);
    AppLogger.info('Tier1: local cache lookup returned — result=${result?.displayName}');
    return tryTier(result, 'Local Cache');
  }

  Future<IdentificationResult?> _tryTierTwoLookup(
      List<String> tokens,
      String raw,
      IdentificationResult? Function(MedicineModel?, String) tryTier) async {
    AppLogger.info('Tier2: starting RTDB lookup — tokens=${tokens.length}');
    final result = await _tierTwoLookup(tokens, raw);
    AppLogger.info('Tier2: RTDB lookup returned — result=${result?.displayName}');
    return tryTier(result, 'Firebase');
  }

  Future<IdentificationResult?> _tryTierThreeLookup(
      List<String> tokens,
      IdentificationResult? Function(MedicineModel?, String) tryTier) async {
    AppLogger.info('Tier3: starting DRAP lookup — tokens=${tokens.length}');
    final result = await _tierThreeLookup(tokens);
    AppLogger.info('Tier3: DRAP lookup returned — result=${result?.displayName}');
    return tryTier(result, 'DRAP');
  }

  Future<IdentificationResult?> _tryTierFourLookup(
      List<String> tokens,
      IdentificationResult? Function(MedicineModel?, String) tryTier) async {
    AppLogger.info('Tier4: starting RxNorm lookup — tokens=${tokens.length}');
    final result = await _tierFourLookup(tokens);
    AppLogger.info('Tier4: RxNorm lookup returned — result=${result?.displayName}');
    return tryTier(result, 'RxNorm');
  }

  Future<IdentificationResult?> _tryTierFiveLookup(
      List<String> tokens,
      IdentificationResult? Function(MedicineModel?, String) tryTier) async {
    AppLogger.info('Tier5: starting OpenFDA lookup — tokens=${tokens.length}');
    final result = await _tierFiveLookup(tokens);
    AppLogger.info('Tier5: OpenFDA lookup returned — result=${result?.displayName}');
    return tryTier(result, 'OpenFDA');
  }

  // ─────────────── Tier 1: SQLite ────────────────────────────────────────────

  Future<MedicineModel?> _tierOneLookup(List<String> tokens, String raw) async {
    // Single-word tokens first — medicine names are almost always one word.
    // Multi-word phrases tried second in case the brand is two words.
    final singleWord = tokens.where(_isUsefulLookupToken).where((t) => !t.contains(' ')).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final multiWord = tokens.where(_isUsefulLookupToken).where((t) => t.contains(' ')).toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final token in [...singleWord, ...multiWord]) {
      if (token.length < 3) continue;
      final result = await _local.searchLocal(token);
      if (result != null) return result;
    }

    // Last resort: individual words from the first OCR line
    final firstLineWords = raw
        .split('\n')
        .first
        .toLowerCase()
        .split(RegExp(r'[\s,/\-\(\)\[\]\|:;]+'))
        .where(_isUsefulLookupToken)
        .toList();
    for (final word in firstLineWords) {
      if (tokens.contains(word)) continue; // already tried above
      final result = await _local.searchLocal(word);
      if (result != null) return result;
    }
    return null;
  }

  // ─────────────── Tier 2: Firebase RTDB ────────────────────────────────────

  Future<MedicineModel?> _tierTwoLookup(List<String> tokens, String raw) async {
    final singleWord = tokens.where(_isUsefulLookupToken).where((t) => !t.contains(' ')).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final multiWord = tokens.where(_isUsefulLookupToken).where((t) => t.contains(' ')).toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final token in [...singleWord, ...multiWord].take(8)) {
      if (token.length < 3) continue;
      final results = await _rtdb.searchMedicines(token);
      if (results.isNotEmpty) {
        await _local.upsertMedicine(results.first);
        return results.first;
      }
    }
    return null;
  }

  // ─────────────── Tier 3: DRAP ──────────────────────────────────────────────

  Future<MedicineModel?> _tierThreeLookup(List<String> tokens) async {
    final candidates = tokens
      .where(_isUsefulLookupToken)
      .where((t) => !t.contains(' '))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final token in candidates.take(4)) {
      try {
        final result = await _drap.searchByBrand(token) ??
            await _drap.searchByGeneric(token);
        if (result != null) {
          await _local.upsertMedicine(result);
          await _rtdb.cacheMedicine(result);
          return result;
        }
      } catch (e) {
        AppLogger.warning('DRAP tier failed for "$token"', error: e);
      }
    }
    return null;
  }

  // ─────────────── Tier 4: RxNorm ────────────────────────────────────────────

  Future<MedicineModel?> _tierFourLookup(List<String> tokens) async {
    final candidates = tokens
      .where(_isUsefulLookupToken)
      .where((t) => !t.contains(' '))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final token in candidates.take(4)) {
      try {
        final result = await _rxnorm.searchMedicine(token);
        if (result != null) {
          await _local.upsertMedicine(result);
          await _rtdb.cacheMedicine(result);
          return result;
        }
      } catch (e) {
        AppLogger.warning('RxNorm tier failed for "$token"', error: e);
      }
    }
    return null;
  }

  // ─────────────── Tier 5: OpenFDA ───────────────────────────────────────────

  Future<MedicineModel?> _tierFiveLookup(List<String> tokens) async {
    final candidates = tokens
      .where(_isUsefulLookupToken)
      .where((t) => !t.contains(' '))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final token in candidates.take(4)) {
      try {
        final result = await _fda.searchMedicine(token);
        if (result != null) {
          await _local.upsertMedicine(result);
          await _rtdb.cacheMedicine(result);
          return result;
        }
      } catch (e) {
        AppLogger.warning('OpenFDA tier failed for "$token"', error: e);
      }
    }
    return null;
  }

  // ─────────────── Confidence scoring ────────────────────────────────────────

  IdentificationResult _scoreResult({
    required MedicineModel medicine,
    required String rawOcrText,
    required List<String> tokens,
  }) {
    final text = rawOcrText.toLowerCase();
    final brandScore = _fuzzyScore(medicine.brandName.toLowerCase(), text, tokens);
    final genericScore =
        _fuzzyScore(medicine.genericName.toLowerCase(), text, tokens);
    final nameScore = brandScore > genericScore ? brandScore : genericScore;

    double dosageScore;
    if (medicine.strength.isNotEmpty) {
      final s = medicine.strength.toLowerCase();
      dosageScore = text.contains(s)
          ? 1.0
          : tokens.any((t) => t.contains(s))
              ? 0.7
              : 0.0;
    } else {
      dosageScore = 0.5;
    }

    double brandMfgScore;
    if (medicine.manufacturer.isNotEmpty) {
      brandMfgScore =
          text.contains(medicine.manufacturer.toLowerCase()) ? 1.0 : 0.3;
    } else {
      brandMfgScore = 0.5;
    }

    final overall =
        nameScore * 0.55 + dosageScore * 0.25 + brandMfgScore * 0.20;

    return IdentificationResult(
      medicine: medicine,
      overallScore: overall.clamp(0.0, 1.0),
      nameScore: nameScore.clamp(0.0, 1.0),
      dosageScore: dosageScore.clamp(0.0, 1.0),
      brandScore: brandMfgScore.clamp(0.0, 1.0),
      rawOcrText: rawOcrText,
      extractedTokens: tokens,
    );
  }

  double _fuzzyScore(String target, String fullText, List<String> tokens) {
    if (target.isEmpty) return 0.0;
    final shortTarget = target.replaceAll(RegExp(r'[^a-z0-9]'), '').length <= 4;
    if (!shortTarget && fullText.contains(target)) return 1.0;
    if (tokens.any((t) => t == target)) return 0.95;
    final words = target.split(RegExp(r'\s+'));
    if (!shortTarget && words.every((w) => tokens.any((t) => t.contains(w)))) return 0.85;
    double best = 0.0;
    for (final token in tokens) {
      final sim = _levenshteinSimilarity(target, token);
      if (sim > best) best = sim;
    }
    return best;
  }

  bool _hasDirectNameEvidence(
    MedicineModel medicine,
    List<String> tokens,
    String rawText,
  ) {
    final normalizedTokens = tokens.map((t) => t.toLowerCase().trim()).toSet();
    final raw = rawText.toLowerCase();

    bool matchesName(String value) {
      final parts = value
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9]+'))
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isEmpty) return false;
      final exactHits = parts.where(normalizedTokens.contains).length;
      if (exactHits > 0) return true;
      if (parts.length == 1 && parts.first.length >= 5) {
        return raw.contains(' ${parts.first} ') ||
            raw.startsWith('${parts.first} ') ||
            raw.endsWith(' ${parts.first}') ||
            raw == parts.first;
      }
      return false;
    }

    return matchesName(medicine.brandName) || matchesName(medicine.genericName);
  }

  bool _isUsefulLookupToken(String token) {
    final t = token.trim().toLowerCase();
    if (t.length < 3) return false;
    if (_noiseTokens.contains(t)) return false;
    final hasLetter = RegExp(r'[a-z]').hasMatch(t);
    final hasDigit = RegExp(r'\d').hasMatch(t);
    // Drop noisy OCR blobs like "7hzXxPBmJ18wMziub" while keeping short
    // medicine-like tokens such as "b12".
    if (hasLetter && hasDigit && t.length > 4) return false;
    if (RegExp(r'^\d+(?:\.\d+)?$').hasMatch(t)) return false;
    if (RegExp(r'^\d+(?:\.\d+)?(mg|mcg|g|ml|iu|mmol)$').hasMatch(t)) {
      return false;
    }
    return hasLetter;
  }

  MedicineModel? _buildOcrHeuristic(String rawOcrText, List<String> tokens) {
    final useful = tokens.where(_isUsefulLookupToken).toList();
    if (useful.length < 2) return null;

    final candidates = [
      ...rawOcrText
          .split(RegExp(r'[\r\n]+'))
          .map((line) => line.toLowerCase())
          .expand((line) => line.split(RegExp(r'[^a-z0-9]+'))),
      ...useful,
    ].where(_isUsefulLookupToken).toList();

    if (candidates.isEmpty) return null;

    final picked = candidates.firstWhere(
      (token) => token.length >= 5 && RegExp(r'^[a-z]+$').hasMatch(token) && RegExp(r'[aeiou]').hasMatch(token),
      orElse: () => candidates.first,
    );

    if (picked.length < 5 || !RegExp(r'^[a-z]+$').hasMatch(picked)) {
      return null;
    }
    final guessedName = _toDisplayCase(picked);

    return MedicineModel(
      id: 'ocr_guess_${DateTime.now().millisecondsSinceEpoch}',
      brandName: guessedName,
      genericName: '',
      searchKeywords: picked,
      source: 'OCR Heuristic',
    );
  }

  String _toDisplayCase(String raw) {
    if (raw.isEmpty) return raw;
    if (raw.length == 1) return raw.toUpperCase();
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  double _levenshteinSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final maxLen = a.length > b.length ? a.length : b.length;
    return 1.0 - _levenshtein(a, b) / maxLen;
  }

  int _levenshtein(String a, String b) {
    final m = a.length, n = b.length;
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
