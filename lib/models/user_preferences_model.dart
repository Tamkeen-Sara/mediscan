class UserPreferencesModel {
  final String languageCode;
  final String themeMode;
  final bool useGeminiAI;
  final bool fallbackToTemplates;
  final bool autoSummariseMedicine;
  final bool showOnboarding;
  final bool notificationsEnabled;

  const UserPreferencesModel({
    this.languageCode = 'en',
    this.themeMode = 'system',
    this.useGeminiAI = true,
    this.fallbackToTemplates = true,
    this.autoSummariseMedicine = true,
    this.showOnboarding = true,
    this.notificationsEnabled = false,
  });

  factory UserPreferencesModel.defaults() =>
      const UserPreferencesModel();

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      languageCode: json['languageCode']?.toString() ?? 'en',
      themeMode: json['themeMode']?.toString() ?? 'system',
      useGeminiAI: json['useGeminiAI'] as bool? ?? true,
      fallbackToTemplates: json['fallbackToTemplates'] as bool? ?? true,
      autoSummariseMedicine:
          json['autoSummariseMedicine'] as bool? ?? true,
      showOnboarding: json['showOnboarding'] as bool? ?? true,
      notificationsEnabled:
          json['notificationsEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'languageCode': languageCode,
      'themeMode': themeMode,
      'useGeminiAI': useGeminiAI,
      'fallbackToTemplates': fallbackToTemplates,
      'autoSummariseMedicine': autoSummariseMedicine,
      'showOnboarding': showOnboarding,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  UserPreferencesModel copyWith({
    String? languageCode,
    String? themeMode,
    bool? useGeminiAI,
    bool? fallbackToTemplates,
    bool? autoSummariseMedicine,
    bool? showOnboarding,
    bool? notificationsEnabled,
  }) {
    return UserPreferencesModel(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      useGeminiAI: useGeminiAI ?? this.useGeminiAI,
      fallbackToTemplates: fallbackToTemplates ?? this.fallbackToTemplates,
      autoSummariseMedicine:
          autoSummariseMedicine ?? this.autoSummariseMedicine,
      showOnboarding: showOnboarding ?? this.showOnboarding,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  bool get isUrdu => languageCode == 'ur';
  bool get isEnglish => languageCode == 'en';
}
