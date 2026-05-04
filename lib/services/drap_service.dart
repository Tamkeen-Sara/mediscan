import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/medicine_model.dart';
import '../utils/app_logger.dart';

/// Queries the Drug Regulatory Authority of Pakistan (DRAP) drug register.
///
/// DRAP portal: https://apps.dra.gov.pk/drug_register/
/// No official JSON API exists — we GET their search page and parse the HTML
/// table. The portal is a government website: it can be slow or temporarily
/// unavailable, so a short timeout is enforced and failures are non-fatal.
class DrapService {
  static DrapService? _instance;
  static DrapService get instance => _instance ??= DrapService._();
  DrapService._();

  static const _timeout = Duration(seconds: 6);
  static const _baseUrl = 'https://apps.dra.gov.pk/drug_register/index.php';

  Future<MedicineModel?> searchByBrand(String query) =>
      _search(query, byGeneric: false);

  Future<MedicineModel?> searchByGeneric(String query) =>
      _search(query, byGeneric: true);

  Future<MedicineModel?> _search(String query,
      {required bool byGeneric}) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        byGeneric ? 'generic_name' : 'brand_name': q,
        'search': '1',
      });
      final response = await http
          .get(uri, headers: {'Accept': 'text/html'})
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      return _parseHtml(response.body);
    } on TimeoutException {
      AppLogger.warning('DRAP timed out for "$q"');
      return null;
    } catch (e, st) {
      AppLogger.error('DRAP search failed for "$q"', error: e, stackTrace: st);
      return null;
    }
  }

  /// Extracts the first result row from DRAP's HTML table.
  /// Columns: Reg No | Brand Name | Generic | Manufacturer | Form | Strength
  MedicineModel? _parseHtml(String html) {
    try {
      final rowRegex = RegExp(
        r'<tr[^>]*>\s*'
        r'<td[^>]*>(.*?)</td>\s*'
        r'<td[^>]*>(.*?)</td>\s*'
        r'<td[^>]*>(.*?)</td>\s*'
        r'<td[^>]*>(.*?)</td>\s*'
        r'<td[^>]*>(.*?)</td>\s*'
        r'<td[^>]*>(.*?)</td>',
        caseSensitive: false,
        dotAll: true,
      );

      for (final m in rowRegex.allMatches(html)) {
        final brand = _stripTags(m.group(2) ?? '').trim();
        final generic = _stripTags(m.group(3) ?? '').trim();
        // Skip header rows
        if (brand.isEmpty || brand.toLowerCase() == 'brand name') continue;

        final regNo = _stripTags(m.group(1) ?? '').trim();
        final mfr = _stripTags(m.group(4) ?? '').trim();
        final form = _stripTags(m.group(5) ?? '').trim();
        final strength = _stripTags(m.group(6) ?? '').trim();

        final slug = regNo.replaceAll(RegExp('[^a-zA-Z0-9]'), '_').toLowerCase();
        final id = slug.isNotEmpty
            ? 'drap_$slug'
            : 'drap_${brand.toLowerCase().replaceAll(' ', '_')}';

        return MedicineModel(
          id: id,
          brandName: brand,
          genericName: generic,
          manufacturer: mfr,
          dosageForm: form,
          strength: strength,
          searchKeywords:
              '$brand $generic $mfr $form $strength'.toLowerCase(),
        );
      }
      return null;
    } catch (e, st) {
      AppLogger.error('DRAP HTML parse error', error: e, stackTrace: st);
      return null;
    }
  }

  String _stripTags(String html) =>
      html.replaceAll(RegExp(r'<[^>]+>'), '').trim();
}
