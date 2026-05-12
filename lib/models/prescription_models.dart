class PrescriptionEntry {
  final String rawName;
  final String dosageText;
  final String frequencyText;
  final String notes;
  final String explanationEn;
  final String explanationUr;

  const PrescriptionEntry({
    required this.rawName,
    this.dosageText = '',
    this.frequencyText = '',
    this.notes = '',
    this.explanationEn = '',
    this.explanationUr = '',
  });

  PrescriptionEntry copyWith({
    String? rawName,
    String? dosageText,
    String? frequencyText,
    String? notes,
    String? explanationEn,
    String? explanationUr,
  }) {
    return PrescriptionEntry(
      rawName: rawName ?? this.rawName,
      dosageText: dosageText ?? this.dosageText,
      frequencyText: frequencyText ?? this.frequencyText,
      notes: notes ?? this.notes,
      explanationEn: explanationEn ?? this.explanationEn,
      explanationUr: explanationUr ?? this.explanationUr,
    );
  }
}

class PrescriptionReminder {
  final String id;
  final String medicineName;
  final List<String> times24h;
  final String dosageText;
  final bool isActive;

  const PrescriptionReminder({
    required this.id,
    required this.medicineName,
    required this.times24h,
    this.dosageText = '',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicineName': medicineName,
        'times24h': times24h,
        'dosageText': dosageText,
        'isActive': isActive,
      };

  factory PrescriptionReminder.fromJson(Map<String, dynamic> json) {
    final rawTimes = (json['times24h'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    return PrescriptionReminder(
      id: json['id']?.toString() ?? '',
      medicineName: json['medicineName']?.toString() ?? '',
      times24h: rawTimes,
      dosageText: json['dosageText']?.toString() ?? '',
      isActive: json['isActive'] == true,
    );
  }
}

class PrescriptionAnalysisResult {
  final String rawOcrText;
  final List<PrescriptionEntry> entries;
  final List<String> interactionWarnings;

  const PrescriptionAnalysisResult({
    required this.rawOcrText,
    required this.entries,
    required this.interactionWarnings,
  });
}
