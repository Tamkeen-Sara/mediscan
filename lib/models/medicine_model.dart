class MedicineModel {
  final String id;
  final String brandName;
  final String genericName;
  final String manufacturer;
  final String category;
  final String dosageForm;
  final String strength;

  // Dosage
  final String dosageAdults;
  final String dosageChildren;
  final String maxDailyDose;
  final String onsetTime;
  final String storageInstructions;

  // Plain-language awareness fields (Addendum 1)
  final String summaryEn;
  final String summaryUr;
  final List<String> symptomsPlain;
  final List<String>? symptomsPlainUr;
  final List<String> warningsPlain;
  final List<String>? warningsPlainUr;
  final List<String> sideEffectsPlain;
  final List<String>? sideEffectsPlainUr;
  final String pregnancySafetyPlain;
  final String? pregnancySafetyPlainUr;
  final String importantNote;
  final String? importantNoteUr;

  // Safety
  final List<String> warnings;
  final List<String> sideEffects;
  final List<String> contraindications;
  final List<String> drugInteractions;
  final String pregnancyCategory;

  // Prescription status
  final bool requiresPrescription;

  // Search / identification
  final String searchKeywords;
  final List<String> aliases;

  // Gemini cache (stored in Realtime DB after first AI call)
  final String? cachedSummaryEn;
  final String? cachedSummaryUr;
  final List<String>? cachedSuggestedQuestions;
  final List<String>? cachedSuggestedQuestionsUr;

  // OpenFDA reference
  final String? openFdaId;

  // Data source tracking (e.g., "Local Cache", "Firebase", "DRAP", "Gemini")
  final String? source;

  const MedicineModel({
    required this.id,
    required this.brandName,
    required this.genericName,
    this.manufacturer = '',
    this.category = '',
    this.dosageForm = '',
    this.strength = '',
    this.dosageAdults = '',
    this.dosageChildren = '',
    this.maxDailyDose = '',
    this.onsetTime = '',
    this.storageInstructions = '',
    this.summaryEn = '',
    this.summaryUr = '',
    this.symptomsPlain = const [],
    this.symptomsPlainUr,
    this.warningsPlain = const [],
    this.warningsPlainUr,
    this.sideEffectsPlain = const [],
    this.sideEffectsPlainUr,
    this.pregnancySafetyPlain = '',
    this.pregnancySafetyPlainUr,
    this.importantNote = '',
    this.importantNoteUr,
    this.warnings = const [],
    this.sideEffects = const [],
    this.contraindications = const [],
    this.drugInteractions = const [],
    this.pregnancyCategory = '',
    this.requiresPrescription = false,
    this.searchKeywords = '',
    this.aliases = const [],
    this.cachedSummaryEn,
    this.cachedSummaryUr,
    this.cachedSuggestedQuestions,
    this.cachedSuggestedQuestionsUr,
    this.openFdaId,
    this.source,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      genericName: json['genericName']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      dosageForm: json['dosageForm']?.toString() ?? '',
      strength: json['strength']?.toString() ?? '',
      dosageAdults: json['dosageAdults']?.toString() ?? '',
      dosageChildren: json['dosageChildren']?.toString() ?? '',
      maxDailyDose: json['maxDailyDose']?.toString() ?? '',
      onsetTime: json['onsetTime']?.toString() ?? '',
      storageInstructions: json['storageInstructions']?.toString() ?? '',
      summaryEn: json['summaryEn']?.toString() ?? '',
      summaryUr: json['summaryUr']?.toString() ?? '',
      symptomsPlain: _toStringList(json['symptomsPlain']),
      symptomsPlainUr: _toNullableStringList(json['symptomsPlainUr']),
      warningsPlain: _toStringList(json['warningsPlain']),
      warningsPlainUr: _toNullableStringList(json['warningsPlainUr']),
      sideEffectsPlain: _toStringList(json['sideEffectsPlain']),
      sideEffectsPlainUr: _toNullableStringList(json['sideEffectsPlainUr']),
      pregnancySafetyPlain: json['pregnancySafetyPlain']?.toString() ?? '',
      pregnancySafetyPlainUr: json['pregnancySafetyPlainUr']?.toString(),
      importantNote: json['importantNote']?.toString() ?? '',
      importantNoteUr: json['importantNoteUr']?.toString(),
      warnings: _toStringList(json['warnings']),
      sideEffects: _toStringList(json['sideEffects']),
      contraindications: _toStringList(json['contraindications']),
      drugInteractions: _toStringList(json['drugInteractions']),
      pregnancyCategory: json['pregnancyCategory']?.toString() ?? '',
      requiresPrescription: json['requiresPrescription'] == true,
      searchKeywords: json['searchKeywords']?.toString() ?? '',
      aliases: _toStringList(json['aliases']),
      cachedSummaryEn: json['cachedSummaryEn']?.toString(),
      cachedSummaryUr: json['cachedSummaryUr']?.toString(),
      cachedSuggestedQuestions:
          _toNullableStringList(json['cachedSuggestedQuestions']),
      cachedSuggestedQuestionsUr:
          _toNullableStringList(json['cachedSuggestedQuestionsUr']),
      openFdaId: json['openFdaId']?.toString(),
      source: json['source']?.toString(),
    );
  }

  /// Used when reading from OpenFDA API response
  factory MedicineModel.fromOpenFDA(Map<String, dynamic> json, String id) {
    final results = json['results'] as List?;
    if (results == null || results.isEmpty) {
      return MedicineModel(id: id, brandName: '', genericName: '');
    }
    final r = results.first as Map<String, dynamic>;
    final openfda = r['openfda'] as Map<String, dynamic>? ?? {};

    String firstVal(dynamic v) =>
        (v is List && v.isNotEmpty) ? v.first.toString() : '';

    final brand = firstVal(openfda['brand_name']);
    final generic = firstVal(openfda['generic_name']);
    final mfr = firstVal(openfda['manufacturer_name']);
    final route = firstVal(openfda['route']);
    final warnings = _toStringList(r['warnings']);
    final sideEffects = _toStringList(r['adverse_reactions']);
    final dosage = firstVal(r['dosage_and_administration']);
    final storage = firstVal(r['storage_and_handling']);
    final pregnancy = firstVal(r['pregnancy']);

    final keywords =
        '$brand $generic $mfr $route'.toLowerCase().trim();

    return MedicineModel(
      id: id,
      brandName: brand,
      genericName: generic,
      manufacturer: mfr,
      dosageForm: route,
      dosageAdults: dosage,
      storageInstructions: storage,
      warnings: warnings,
      sideEffects: sideEffects,
      pregnancySafetyPlain: pregnancy,
      searchKeywords: keywords,
      openFdaId: id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandName': brandName,
      'genericName': genericName,
      'manufacturer': manufacturer,
      'category': category,
      'dosageForm': dosageForm,
      'strength': strength,
      'dosageAdults': dosageAdults,
      'dosageChildren': dosageChildren,
      'maxDailyDose': maxDailyDose,
      'onsetTime': onsetTime,
      'storageInstructions': storageInstructions,
      'summaryEn': summaryEn,
      'summaryUr': summaryUr,
      'symptomsPlain': symptomsPlain,
      'warningsPlain': warningsPlain,
      'sideEffectsPlain': sideEffectsPlain,
      'pregnancySafetyPlain': pregnancySafetyPlain,
      'importantNote': importantNote,
      'warnings': warnings,
      'sideEffects': sideEffects,
      'contraindications': contraindications,
      'drugInteractions': drugInteractions,
      'pregnancyCategory': pregnancyCategory,
      'requiresPrescription': requiresPrescription,
      'searchKeywords': searchKeywords,
      'aliases': aliases,
      if (symptomsPlainUr != null) 'symptomsPlainUr': symptomsPlainUr,
      if (warningsPlainUr != null) 'warningsPlainUr': warningsPlainUr,
      if (sideEffectsPlainUr != null) 'sideEffectsPlainUr': sideEffectsPlainUr,
      if (pregnancySafetyPlainUr != null)
        'pregnancySafetyPlainUr': pregnancySafetyPlainUr,
      if (importantNoteUr != null) 'importantNoteUr': importantNoteUr,
      if (cachedSummaryEn != null) 'cachedSummaryEn': cachedSummaryEn,
      if (cachedSummaryUr != null) 'cachedSummaryUr': cachedSummaryUr,
      if (cachedSuggestedQuestions != null)
        'cachedSuggestedQuestions': cachedSuggestedQuestions,
      if (cachedSuggestedQuestionsUr != null)
        'cachedSuggestedQuestionsUr': cachedSuggestedQuestionsUr,
      if (openFdaId != null) 'openFdaId': openFdaId,
      if (source != null) 'source': source,
    };
  }

  MedicineModel copyWith({
    String? id,
    String? brandName,
    String? genericName,
    String? manufacturer,
    String? category,
    String? dosageForm,
    String? strength,
    String? dosageAdults,
    String? dosageChildren,
    String? maxDailyDose,
    String? onsetTime,
    String? storageInstructions,
    String? summaryEn,
    String? summaryUr,
    List<String>? symptomsPlain,
    List<String>? symptomsPlainUr,
    List<String>? warningsPlain,
    List<String>? warningsPlainUr,
    List<String>? sideEffectsPlain,
    List<String>? sideEffectsPlainUr,
    String? pregnancySafetyPlain,
    String? pregnancySafetyPlainUr,
    String? importantNote,
    String? importantNoteUr,
    List<String>? warnings,
    List<String>? sideEffects,
    List<String>? contraindications,
    List<String>? drugInteractions,
    String? pregnancyCategory,
    bool? requiresPrescription,
    String? searchKeywords,
    List<String>? aliases,
    String? cachedSummaryEn,
    String? cachedSummaryUr,
    List<String>? cachedSuggestedQuestions,
    List<String>? cachedSuggestedQuestionsUr,
    String? openFdaId,
    String? source,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      brandName: brandName ?? this.brandName,
      genericName: genericName ?? this.genericName,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      dosageForm: dosageForm ?? this.dosageForm,
      strength: strength ?? this.strength,
      dosageAdults: dosageAdults ?? this.dosageAdults,
      dosageChildren: dosageChildren ?? this.dosageChildren,
      maxDailyDose: maxDailyDose ?? this.maxDailyDose,
      onsetTime: onsetTime ?? this.onsetTime,
      storageInstructions: storageInstructions ?? this.storageInstructions,
      summaryEn: summaryEn ?? this.summaryEn,
      summaryUr: summaryUr ?? this.summaryUr,
      symptomsPlain: symptomsPlain ?? this.symptomsPlain,
      symptomsPlainUr: symptomsPlainUr ?? this.symptomsPlainUr,
      warningsPlain: warningsPlain ?? this.warningsPlain,
      warningsPlainUr: warningsPlainUr ?? this.warningsPlainUr,
      sideEffectsPlain: sideEffectsPlain ?? this.sideEffectsPlain,
      sideEffectsPlainUr: sideEffectsPlainUr ?? this.sideEffectsPlainUr,
      pregnancySafetyPlain: pregnancySafetyPlain ?? this.pregnancySafetyPlain,
      pregnancySafetyPlainUr:
          pregnancySafetyPlainUr ?? this.pregnancySafetyPlainUr,
      importantNote: importantNote ?? this.importantNote,
      importantNoteUr: importantNoteUr ?? this.importantNoteUr,
      warnings: warnings ?? this.warnings,
      sideEffects: sideEffects ?? this.sideEffects,
      contraindications: contraindications ?? this.contraindications,
      drugInteractions: drugInteractions ?? this.drugInteractions,
      pregnancyCategory: pregnancyCategory ?? this.pregnancyCategory,
      requiresPrescription: requiresPrescription ?? this.requiresPrescription,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      aliases: aliases ?? this.aliases,
      cachedSummaryEn: cachedSummaryEn ?? this.cachedSummaryEn,
      cachedSummaryUr: cachedSummaryUr ?? this.cachedSummaryUr,
      cachedSuggestedQuestions:
          cachedSuggestedQuestions ?? this.cachedSuggestedQuestions,
      cachedSuggestedQuestionsUr:
          cachedSuggestedQuestionsUr ?? this.cachedSuggestedQuestionsUr,
      openFdaId: openFdaId ?? this.openFdaId,
      source: source ?? this.source,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  static List<String> _toStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    // Legacy: if stored as a single string (old data), wrap in list
    if (v is String && v.isNotEmpty) return [v];
    if (v is Map) return v.values.map((e) => e.toString()).toList();
    return [];
  }

  static List<String>? _toNullableStringList(dynamic v) {
    if (v == null) return null;
    return _toStringList(v);
  }

  bool get isEmpty => id.isEmpty && brandName.isEmpty && genericName.isEmpty;

  String get displayName =>
      brandName.isNotEmpty ? brandName : genericName;
}
