import 'dart:convert';
import '../utils/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/medicine_model.dart';

class OpenFdaService {
  static OpenFdaService? _instance;
  static OpenFdaService get instance => _instance ??= OpenFdaService._();
  OpenFdaService._();

  static const String _baseUrl = 'https://api.fda.gov/drug/label.json';

  String get _apiKey => dotenv.env['OPENFDA_API_KEY'] ?? '';

  Future<MedicineModel?> searchMedicine(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      AppLogger.info('OpenFDA search invoked — q=$query');
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'search':
            'openfda.brand_name:"$query" OR openfda.generic_name:"$query"',
        'limit': '1',
        if (_apiKey.isNotEmpty) 'api_key': _apiKey,
      });

      AppLogger.info('OpenFDA URI: ${uri.toString()}');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      AppLogger.info('OpenFDA HTTP status ${response.statusCode} for q=$query');
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      return _parseFdaLabel(results.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  MedicineModel? _parseFdaLabel(Map<String, dynamic> label) {
    try {
      final openfda = label['openfda'] as Map<String, dynamic>? ?? {};

      String first(dynamic val) {
        if (val is List && val.isNotEmpty) return val.first.toString();
        if (val is String) return val;
        return '';
      }

      List<String> toList(dynamic val) {
        if (val is List) return val.map((e) => e.toString()).toList();
        if (val is String && val.isNotEmpty) return [val];
        return [];
      }

      String joinList(dynamic val) {
        if (val is List) return val.join(' ').trim();
        if (val is String) return val.trim();
        return '';
      }

      final brandName = first(openfda['brand_name']);
      final genericName = first(openfda['generic_name']);
      if (brandName.isEmpty && genericName.isEmpty) return null;

      final manufacturer = first(openfda['manufacturer_name']);
      final rxcui = first(openfda['rxcui']);
      final id = rxcui.isNotEmpty
          ? 'fda_${rxcui.replaceAll(' ', '_')}'
          : 'fda_${DateTime.now().millisecondsSinceEpoch}';

      final warningsList = toList(label['warnings']);
      final sideEffectsList = toList(label['adverse_reactions']);
      final dosageText = joinList(label['dosage_and_administration']);
      final storage = joinList(label['storage_and_handling']);
      final pregnancy = joinList(label['pregnancy']);
      final description = joinList(label['description']);
      final indications = joinList(label['indications_and_usage']);
      final pharmaClass =
          (openfda['pharm_class_epc'] as List<dynamic>?)?.join(', ') ?? '';
      final keywords = [brandName.toLowerCase(), genericName.toLowerCase()]
          .where((s) => s.isNotEmpty)
          .join(' ');

      return MedicineModel(
        id: id,
        brandName: brandName.isNotEmpty ? brandName : genericName,
        genericName: genericName.isNotEmpty ? genericName : brandName,
        manufacturer: manufacturer,
        category: pharmaClass,
        dosageForm: first(openfda['dosage_form']),
        strength: first(openfda['strength']),
        dosageAdults: dosageText,
        storageInstructions: storage,
        summaryEn: indications.isNotEmpty ? indications : description,
        warningsPlain: warningsList,
        sideEffectsPlain: sideEffectsList,
        pregnancySafetyPlain: pregnancy,
        warnings: warningsList,
        sideEffects: sideEffectsList,
        contraindications: toList(label['contraindications']),
        drugInteractions: toList(label['drug_interactions']),
        searchKeywords: keywords,
      );
    } catch (_) {
      return null;
    }
  }
}
