enum ScanStatus { highConfidence, mediumConfidence, lowConfidence, failed }

class ScanHistoryModel {
  final String id;
  final String medicineId;
  final String brandName;
  final String genericName;
  final String manufacturer;
  final double confidence;
  final ScanStatus status;
  final DateTime scannedAt;
  final bool isFavourite;
  final String? imagePath;
  final String? rawOcrText;
  final String? notes;

  const ScanHistoryModel({
    required this.id,
    required this.medicineId,
    required this.brandName,
    required this.genericName,
    this.manufacturer = '',
    required this.confidence,
    required this.status,
    required this.scannedAt,
    this.isFavourite = false,
    this.imagePath,
    this.rawOcrText,
    this.notes,
  });

  factory ScanHistoryModel.fromJson(Map<String, dynamic> json) {
    return ScanHistoryModel(
      // Realtime DB push keys are stored under '_key' by watchHistory
      id: json['_key']?.toString() ?? json['id']?.toString() ?? '',
      medicineId: json['medicineId']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      genericName: json['genericName']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      status: _statusFromString(json['status']?.toString()),
      // scannedAt stored as milliseconds epoch int in Realtime DB
      scannedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['scannedAt'] as int?) ??
              DateTime.now().millisecondsSinceEpoch),
      isFavourite: json['isFavourite'] as bool? ?? false,
      imagePath: json['imagePath']?.toString(),
      rawOcrText: json['rawOcrText']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineId': medicineId,
      'brandName': brandName,
      'genericName': genericName,
      'manufacturer': manufacturer,
      'confidence': confidence,
      'status': _statusToString(status),
      // Store as milliseconds integer — Realtime DB has no Timestamp type
      'scannedAt': scannedAt.millisecondsSinceEpoch,
      'isFavourite': isFavourite,
      // imagePath is intentionally excluded: it's a local temp-file path that
      // the OS clears on restart. Persisting it to Firebase would produce
      // permanently broken thumbnails when history is loaded on a fresh launch.
      if (rawOcrText != null) 'rawOcrText': rawOcrText,
      if (notes != null) 'notes': notes,
    };
  }

  ScanHistoryModel copyWith({
    String? id,
    String? medicineId,
    String? brandName,
    String? genericName,
    String? manufacturer,
    double? confidence,
    ScanStatus? status,
    DateTime? scannedAt,
    bool? isFavourite,
    String? imagePath,
    String? rawOcrText,
    String? notes,
  }) {
    return ScanHistoryModel(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      brandName: brandName ?? this.brandName,
      genericName: genericName ?? this.genericName,
      manufacturer: manufacturer ?? this.manufacturer,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      scannedAt: scannedAt ?? this.scannedAt,
      isFavourite: isFavourite ?? this.isFavourite,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      notes: notes ?? this.notes,
    );
  }

  static ScanStatus _statusFromString(String? s) {
    switch (s) {
      case 'highConfidence':
        return ScanStatus.highConfidence;
      case 'mediumConfidence':
        return ScanStatus.mediumConfidence;
      case 'lowConfidence':
        return ScanStatus.lowConfidence;
      default:
        return ScanStatus.failed;
    }
  }

  static String _statusToString(ScanStatus s) {
    switch (s) {
      case ScanStatus.highConfidence:
        return 'highConfidence';
      case ScanStatus.mediumConfidence:
        return 'mediumConfidence';
      case ScanStatus.lowConfidence:
        return 'lowConfidence';
      case ScanStatus.failed:
        return 'failed';
    }
  }

  String get displayName =>
      brandName.isNotEmpty ? brandName : genericName;
}

enum HistoryFilter { all, favourites, today, last7days, last30days }
