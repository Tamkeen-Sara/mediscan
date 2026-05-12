import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medicine_model.dart';
import '../utils/app_logger.dart';

/// Free NIH RxNav / RxNorm API — no API key required.
/// Docs: https://rxnav.nlm.nih.gov/RxNormAPIs.html
///
/// Used as a Tier 4 fallback when the local DB, Firebase, and DRAP all miss.
/// Primarily covers generic/international drug names; Pakistani brand names
/// rarely appear here, but generic ingredient names almost always do.
class RxNormService {
  static RxNormService? _instance;
  static RxNormService get instance => _instance ??= RxNormService._();
  RxNormService._();

  static const _base = 'https://rxnav.nlm.nih.gov/REST';
  static const _timeout = Duration(seconds: 8);

  Future<MedicineModel?> searchMedicine(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    try {
      AppLogger.info('RxNorm search invoked — q=$q');
      // Step 1: find RxCUI (concept identifier) for the drug name
      final rxcui = await _getRxcui(q);
      AppLogger.info('RxNorm _getRxcui returned rxcui=$rxcui for q=$q');
      if (rxcui == null) return null;

      // Step 2: fetch the full drug properties for that RxCUI
      return await _getDrugProperties(rxcui, q);
    } catch (e, st) {
      AppLogger.error('RxNorm search failed for "$q"', error: e, stackTrace: st);
      return null;
    }
  }

  Future<String?> _getRxcui(String name) async {
    try {
      AppLogger.info('RxNorm _getRxcui lookup — name=$name');
      final uri = Uri.parse('$_base/rxcui.json')
          .replace(queryParameters: {'name': name, 'search': '1'});
      final res =
          await http.get(uri).timeout(_timeout);
      AppLogger.info('RxNorm rxcui HTTP status ${res.statusCode} for name=$name');
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final idGroup = body['idGroup'] as Map<String, dynamic>?;
      final rxnormId = idGroup?['rxnormId'];
      if (rxnormId is List && rxnormId.isNotEmpty) {
        return rxnormId.first.toString();
      }
      return null;
    } on TimeoutException {
      AppLogger.warning('RxNorm rxcui lookup timed out for "$name"');
      return null;
    }
  }

  Future<MedicineModel?> _getDrugProperties(
      String rxcui, String originalQuery) async {
    try {
      final uri =
          Uri.parse('$_base/rxcui/$rxcui/properties.json');
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final props =
          (body['properties'] as Map<String, dynamic>?) ?? {};

      final name = props['name']?.toString() ?? originalQuery;
      final synonym = props['synonym']?.toString() ?? '';
      final tty = props['tty']?.toString() ?? '';  // term type: IN, BN, SBD…

      // tty 'IN' = ingredient (generic), 'BN' = brand name
      final brandName = tty == 'BN' ? name : synonym;
      final genericName = tty == 'IN' ? name : (synonym.isNotEmpty ? synonym : name);

      return MedicineModel(
        id: 'rxnorm_$rxcui',
        brandName: brandName.isNotEmpty ? brandName : genericName,
        genericName: genericName,
        searchKeywords: '$name $synonym'.toLowerCase().trim(),
      );
    } on TimeoutException {
      AppLogger.warning('RxNorm properties timed out for rxcui $rxcui');
      return null;
    }
  }
}
