import '../models/medicine_model.dart';

/// Provides offline template responses when Gemini is unavailable.
class TemplateResponseService {
  static TemplateResponseService? _instance;
  static TemplateResponseService get instance =>
      _instance ??= TemplateResponseService._();
  TemplateResponseService._();

  /// Returns a template response in the given language.
  String getResponse({
    required String question,
    required MedicineModel? medicine,
    required String languageCode,
  }) {
    final q = question.toLowerCase();
    final isUrdu = languageCode == 'ur';

    if (medicine == null) {
      return isUrdu
          ? 'براہ کرم پہلے کوئی دوائی اسکین کریں، پھر سوال پوچھیں۔'
          : 'Please scan a medicine first, then ask your question.';
    }

    final name = medicine.displayName;

    // ── Dosage ──────────────────────────────────────────────────────
    if (_matches(q, ['dose', 'dosage', 'how much', 'how many', 'take',
        'خوراک', 'کتنی', 'کتنا'])) {
      if (isUrdu) {
        return '${medicine.displayName} کی خوراک:\n'
            '• بالغ: ${_orDefault(medicine.dosageAdults, 'ڈاکٹر سے پوچھیں')}\n'
            '• بچے: ${_orDefault(medicine.dosageChildren, 'ڈاکٹر سے پوچھیں')}\n'
            '• زیادہ سے زیادہ روزانہ خوراک: ${_orDefault(medicine.maxDailyDose, 'لیبل دیکھیں')}\n\n'
            'یہ عام رہنمائی ہے۔ اپنے ڈاکٹر یا فارماسسٹ سے مشورہ کریں۔';
      }
      return 'Dosage for $name:\n'
          '• Adults: ${_orDefault(medicine.dosageAdults, 'Consult your doctor')}\n'
          '• Children: ${_orDefault(medicine.dosageChildren, 'Consult your doctor')}\n'
          '• Maximum daily dose: ${_orDefault(medicine.maxDailyDose, 'See label')}\n\n'
          'This is general guidance. Always follow your doctor\'s instructions.';
    }

    // ── Side effects ─────────────────────────────────────────────────
    if (_matches(q, ['side effect', 'side-effect', 'reaction', 'adverse',
        'problem', 'harm', 'خطرہ', 'نقصان', 'مضر اثرات'])) {
      final effects = medicine.sideEffectsPlain.isNotEmpty
          ? medicine.sideEffectsPlain
          : medicine.sideEffects.take(5).join(', ');
      if (isUrdu) {
        return '$name کے ممکنہ مضر اثرات:\n$effects\n\n'
            'اگر کوئی شدید علامات محسوس ہوں تو فوری ڈاکٹر سے رجوع کریں۔';
      }
      return 'Possible side effects of $name:\n$effects\n\n'
          'If you experience severe symptoms, contact your doctor immediately.';
    }

    // ── Warnings ─────────────────────────────────────────────────────
    if (_matches(q, ['warning', 'caution', 'avoid', 'dangerous', 'safe',
        'محفوظ', 'احتیاط', 'خبردار', 'خطرناک'])) {
      final warnings = medicine.warningsPlain.isNotEmpty
          ? medicine.warningsPlain
          : medicine.warnings.take(3).join('. ');
      if (isUrdu) {
        return '$name کے بارے میں احتیاطیں:\n$warnings\n\n'
            '${_orDefault(medicine.importantNote, '')}';
      }
      return 'Warnings for $name:\n$warnings\n\n'
          '${_orDefault(medicine.importantNote, '')}';
    }

    // ── Interactions ──────────────────────────────────────────────────
    if (_matches(q, ['interact', 'interaction', 'together', 'combine',
        'mix', 'تعامل', 'ساتھ'])) {
      final interactions = medicine.drugInteractions.isEmpty
          ? (isUrdu ? 'کوئی معلوم تعامل نہیں' : 'No known interactions on record')
          : medicine.drugInteractions.take(5).join(', ');
      if (isUrdu) {
        return '$name کے دوائی تعامل:\n$interactions\n\n'
            'کوئی بھی نئی دوائی شروع کرنے سے پہلے ڈاکٹر کو بتائیں۔';
      }
      return 'Drug interactions for $name:\n$interactions\n\n'
          'Always tell your doctor about all medicines you are taking.';
    }

    // ── Pregnancy / breastfeeding ─────────────────────────────────────
    if (_matches(q, ['pregnant', 'pregnancy', 'breastfeed', 'nursing',
        'baby', 'حمل', 'دودھ پلانا', 'بچہ'])) {
      final preg = medicine.pregnancySafetyPlain.isNotEmpty
          ? medicine.pregnancySafetyPlain
          : (medicine.pregnancyCategory.isNotEmpty
              ? 'Pregnancy category: ${medicine.pregnancyCategory}'
              : (isUrdu ? 'براہ کرم ڈاکٹر سے مشورہ کریں' : 'Please consult your doctor'));
      if (isUrdu) {
        return '$name اور حمل:\n$preg';
      }
      return 'Pregnancy & breastfeeding — $name:\n$preg';
    }

    // ── What is it used for ───────────────────────────────────────────
    if (_matches(q, ['use', 'used for', 'treat', 'treatment', 'help',
        'condition', 'علاج', 'استعمال', 'کیا کرتی ہے'])) {
      final summary = medicine.cachedSummaryEn ?? medicine.summaryEn;
      if (isUrdu) {
        return medicine.cachedSummaryUr?.isNotEmpty == true
            ? medicine.cachedSummaryUr!
            : '$name ان علامات میں مددگار ہے: ${medicine.symptomsPlain.join(', ')}';
      }
      return summary.isNotEmpty
          ? summary
          : '$name is used for: ${medicine.symptomsPlain.join(', ')}.';
    }

    // ── Storage ───────────────────────────────────────────────────────
    if (_matches(q, ['store', 'storage', 'keep', 'refrigerate', 'expire',
        'محفوظ رکھنا', 'رکھیں'])) {
      final storage = _orDefault(medicine.storageInstructions,
          isUrdu ? 'ٹھنڈی اور خشک جگہ رکھیں' : 'Store in a cool, dry place');
      if (isUrdu) {
        return '$name کو محفوظ کرنے کا طریقہ:\n$storage';
      }
      return 'Storage instructions for $name:\n$storage';
    }

    // ── Onset / how long ─────────────────────────────────────────────
    if (_matches(q, ['how long', 'when work', 'when does', 'onset', 'start',
        'کب اثر', 'کتنے وقت میں'])) {
      final onset = _orDefault(medicine.onsetTime,
          isUrdu ? 'عام طور پر 30 سے 60 منٹ میں' : 'Usually within 30–60 minutes');
      if (isUrdu) {
        return '$name کب اثر کرتی ہے:\n$onset';
      }
      return 'When does $name start working:\n$onset';
    }

    // ── Default fallback ──────────────────────────────────────────────
    if (isUrdu) {
      final summary = medicine.cachedSummaryUr ?? medicine.summaryUr;
      return summary.isNotEmpty
          ? '$name کے بارے میں:\n$summary'
          : '$name ایک ${_orDefault(medicine.category, 'دوائی')} ہے جو '
              '${medicine.symptomsPlain.take(3).join(', ')} میں استعمال ہوتی ہے۔\n\n'
              'مزید معلومات کے لیے اپنے ڈاکٹر یا فارماسسٹ سے رجوع کریں۔';
    }
    final summary = medicine.cachedSummaryEn ?? medicine.summaryEn;
    return summary.isNotEmpty
        ? 'About $name:\n$summary'
        : '$name is a ${_orDefault(medicine.category, 'medicine')} used for '
            '${medicine.symptomsPlain.take(3).join(', ')}.\n\n'
            'For more information, consult your doctor or pharmacist.';
  }

  bool _matches(String question, List<String> keywords) =>
      keywords.any((k) => question.contains(k));

  String _orDefault(String? value, String fallback) =>
      (value != null && value.isNotEmpty) ? value : fallback;
}
