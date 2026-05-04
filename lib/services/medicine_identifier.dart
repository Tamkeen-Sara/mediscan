import '../models/medicine_model.dart';
import '../models/identification_result.dart';
import '../utils/app_logger.dart';
import 'local_cache_service.dart';
import 'realtime_db_service.dart';
import 'openfda_service.dart';
import 'drap_service.dart';
import 'rxnorm_service.dart';

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

  Future<IdentificationResult> identify({
    required String rawOcrText,
    required List<String> tokens,
  }) async {
    if (rawOcrText.trim().isEmpty && tokens.isEmpty) {
      return IdentificationResult.empty();
    }

    MedicineModel? candidate;

    candidate = await _tierOneLookup(tokens, rawOcrText);
    candidate ??= await _tierTwoLookup(tokens, rawOcrText);
    candidate ??= await _tierThreeLookup(tokens);
    candidate ??= await _tierFourLookup(tokens);
    candidate ??= await _tierFiveLookup(tokens);

    if (candidate == null) return IdentificationResult.empty();

    return _scoreResult(medicine: candidate, rawOcrText: rawOcrText, tokens: tokens);
  }

  // ─────────────── Tier 1: SQLite ────────────────────────────────────────────

  Future<MedicineModel?> _tierOneLookup(
      List<String> tokens, String raw) async {
    // Single-word tokens first — medicine names are almost always one word.
    // Multi-word phrases tried second in case the brand is two words.
    final singleWord = tokens.where((t) => !t.contains(' ')).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final multiWord = tokens.where((t) => t.contains(' ')).toList()
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
        .where((w) => w.length >= 3)
        .toList();
    for (final word in firstLineWords) {
      if (tokens.contains(word)) continue; // already tried above
      final result = await _local.searchLocal(word);
      if (result != null) return result;
    }
    return null;
  }

  // ─────────────── Tier 2: Firebase RTDB ────────────────────────────────────

  Future<MedicineModel?> _tierTwoLookup(
      List<String> tokens, String raw) async {
    final singleWord = tokens.where((t) => !t.contains(' ')).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final multiWord = tokens.where((t) => t.contains(' ')).toList()
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
        .where((t) => !t.contains(' ') && t.length >= 4)
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
        .where((t) => !t.contains(' ') && t.length >= 4)
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
        .where((t) => !t.contains(' ') && t.length >= 4)
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
    final brandScore =
        _fuzzyScore(medicine.brandName.toLowerCase(), text, tokens);
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
    if (fullText.contains(target)) return 1.0;
    if (tokens.any((t) => t == target)) return 0.95;
    final words = target.split(RegExp(r'\s+'));
    if (words.every((w) => tokens.any((t) => t.contains(w)))) return 0.85;
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
