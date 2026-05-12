# MediScan — CLAUDE.md

Medicine scanner & AI information app for Pakistani patients.
Scan a medicine label → OCR extracts text → identify medicine → Gemini AI summary.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.3+ / Dart |
| State management | Provider (`ChangeNotifier`) |
| Backend / Auth | Firebase Realtime Database + Firebase Auth |
| AI | Google Generative AI (`gemini-3.1-flash-lite-preview`) |
| OCR | Google ML Kit — Latin script only |
| Local DB | SQLite via `sqflite` (seeded from `assets/database/medicines.json`) |
| Medicine API | OpenFDA (US medicines fallback) |
| Camera | `camera` package for live preview + `image_picker` as fallback |
| Translations | JSON files in `assets/translations/` (not ARB / intl) |
| Env vars | `flutter_dotenv` — loads `.env` as an asset |

---

## Package Name

```
com.example.mediscan
```

Defined in `android/app/build.gradle.kts` → `applicationId` and `namespace`.
The `android/app/google-services.json` must match this exactly.
The file at `android/android/app/google-services.json` is a stale duplicate in the
wrong location — Gradle ignores it. Do not edit it.

---

## Environment Variables

All API keys live in `.env` (included as an asset in `pubspec.yaml`).
Loaded in `main()` via `await dotenv.load(fileName: '.env')` before anything else.

```
GEMINI_API_KEY=...       # From https://aistudio.google.com — must have Generative Language API enabled
OPENFDA_API_KEY=...      # From https://open.fda.gov/apis/authentication/
GOOGLE_TRANSLATE_API_KEY=  # Leave blank — Gemini handles translations, this is unused
```

**Do not use Google Translate API** — it is a paid service. Gemini handles Urdu
translations inline via the summary prompt. The `TranslateService` is a dead
fallback; leave the key empty.

---

## Project Structure

```
lib/
  main.dart                   # Entry point, Provider setup, route table
  config/
    app_theme.dart            # Light + dark MaterialTheme (Material 3)
  constants/
    app_colors.dart           # All colour constants (no magic hex values elsewhere)
    app_dimensions.dart       # Spacing, radius, icon sizes, animation durations
    app_strings.dart          # Translation key constants (use these, never raw strings)
  models/
    medicine_model.dart       # Core data model — brand/generic/dosage/warnings etc.
    identification_result.dart# OCR → identifier result with confidence scores
    scan_history_model.dart
    chat_message.dart
    user_preferences_model.dart
  providers/                  # ChangeNotifier state management
    scan_provider.dart        # Main scan pipeline orchestrator
    chat_provider.dart        # AI chat conversation state
    history_provider.dart
    language_provider.dart    # Locale + RTL, persisted to SharedPreferences
    theme_provider.dart       # ThemeMode, persisted to SharedPreferences
    symptom_checker_provider.dart
  services/
    gemini_service.dart       # Gemini AI — summaries + chat
    ocr_service.dart          # ML Kit Latin OCR
    medicine_identifier.dart  # 3-tier lookup: SQLite → Firebase → OpenFDA
    local_cache_service.dart  # SQLite read/write, seeded on first launch
    realtime_db_service.dart  # Firebase Realtime Database wrapper
    openfda_service.dart      # OpenFDA REST API client
    translation_service.dart  # JSON translation loader (singleton)
    translate_service.dart    # Google Translate API wrapper (UNUSED — key is blank)
    template_response_service.dart  # Offline AI fallback responses
    symptom_match_service.dart
  screens/
    splash/                   # Initialises SQLite, ensures Firebase user exists
    onboarding/
    auth/
      sign_in_screen.dart     # Email + Google + Guest (anonymous) auth
    main/
      main_screen.dart        # Bottom nav: Scanner | History | Chat | Profile
    scanner/
      scanner_screen.dart     # Live camera preview + gallery picker
      processing_screen.dart  # Animated pipeline progress + cancel button
      scan_failed_screen.dart
    results/
      scan_results_screen.dart # Full medicine info, language toggle, AI chat shortcut
      confidence_screen.dart   # Shown for medium-confidence scans
      manual_edit_screen.dart
    history/
    ai_chat/
      ai_chat_screen.dart
    symptom_checker/
    profile/
      profile_screen.dart     # Settings, sign-out, theme/language pickers
  widgets/                    # 18 reusable widgets
assets/
  .env                        # API keys (included as Flutter asset)
  database/
    medicines.json            # Local medicine seed data for SQLite
  translations/
    en.json                   # All English UI strings
    ur.json                   # All Urdu UI strings
  fonts/
    NotoNastaliqUrdu-Regular.ttf
android/
  app/
    google-services.json      # Firebase config — package: com.example.mediscan
    build.gradle.kts          # applicationId + targetSdk 34
```

---

## Routing

Static routes defined in `main.dart` `routes: {}`.
Dynamic routes use `onGenerateRoute`:

| Route | Screen | Notes |
|---|---|---|
| `/` | SplashScreen | Initialises app |
| `/onboarding` | OnboardingScreen | Shown once (`showOnboarding` pref) |
| `/home` | MainScreen | Bottom nav host |
| `/signin` | SignInScreen | |
| `/processing` | ProcessingScreen | Requires `String` argument (image path) |
| `/results` | ScanResultsScreen | Optional `Map<String,dynamic>` arg (`isInfoMode`) |
| `/confidence` | ConfidenceScreen | Medium-confidence scans |
| `/scan-failed` | ScanFailedScreen | |
| `/manual-edit` | ManualEditScreen | |
| `/chat` | AiChatScreen | |
| `/symptom-checker` | SymptomCheckerScreen | |
| `/saved-medicines` | SavedMedicinesScreen | |
| `/ai-prefs` | AiPreferencesScreen | |
| `/about` | AboutScreen | |
| `/feedback` | FeedbackScreen | |
| `/privacy` | PrivacyScreen | |
| `/share` | ShareAppScreen | |

---

## State Management Rules

- Six `ChangeNotifierProvider`s registered in `main()`.
- `context.watch<P>()` in build methods, `context.read<P>()` in callbacks.
- `ScanProvider` is the pipeline orchestrator — drives `ProcessingScreen` and `ScanResultsScreen`.
- `ScanProvider.processImage()` has an outer try/catch. It always ends with
  `ScanPhase.result` or `ScanPhase.failed` — never stays at `processing`.
- `ChatProvider` is kept alive across navigation (singleton provider).
  Call `chat.initWithContext(medicine)` before pushing `/chat` to set context.

---

## Translation System

**Not** Flutter's `intl`/ARB system. Custom JSON-based singleton.

```dart
// Get translator
final tr = TranslationService.instance.tr;

// Use a key (always use AppStrings constants, never raw strings)
Text(tr(AppStrings.scannerTitle))
```

To add a new string:
1. Add a `static const String myKey = 'my_key';` to `lib/constants/app_strings.dart`
2. Add `"my_key": "English text"` to `assets/translations/en.json`
3. Add `"my_key": "اردو متن"` to `assets/translations/ur.json`

Language change is instant — `LanguageProvider.setLanguage('ur')` reloads translations
and rebuilds the entire tree. RTL layout is applied via `Directionality` in `main.dart`.

---

## Gemini AI

- Model: `gemini-3.1-flash-lite-preview` (defined in `GeminiService._modelId`)
- To change model: edit `lib/services/gemini_service.dart` line ~30.
  Get exact model IDs from https://aistudio.google.com/models
- Key must have **Generative Language API** enabled in Google Cloud Console.
- `GeminiService.lastError` (type `GeminiError?`) exposes the last failure reason:
  - `apiKeyInvalid` — 403, key not activated or wrong project
  - `rateLimited` — 429, daily quota hit
  - `modelUnavailable` — 404, model ID doesn't exist for this key tier
  - `network` — timeout or no internet
- The `OfflineAiBanner` reads `lastError` to show a specific message.

---

## Camera

`ScannerScreen` uses `camera` package for live preview and `image_picker` as fallback:
- Preview resolution: `ResolutionPreset.medium` (reduces buffer drops on mid-range devices)
- `_releaseCamera()` is called **before** navigating to `/processing` — the camera
  must not run during OCR/Gemini to avoid hardware errors.
- If `CameraController` fires an async error, `_camReady` flips to false and
  `image_picker` takes over silently.

---

## Firebase

- **Realtime Database** (not Firestore) — URL: `https://mediscan-c15e6-default-rtdb.asia-southeast1.firebasedatabase.app`
- **Auth**: email/password + Google Sign-In + anonymous (guest)
- After sign-out, the app **automatically creates an anonymous session** so scan
  history and saves keep working. (Handled in `ProfileScreen._signOut`.)
- Splash screen ensures there is always a Firebase user on startup.
- Firebase DB warning in logs about missing index on `scannedAt` is harmless but
  can be fixed by adding `".indexOn": "scannedAt"` to Firebase security rules for
  `users/{uid}/scan_history`.

---

## Medicine Identification Pipeline

```
Image → OcrService (ML Kit, Latin only)
      → MedicineIdentifier.identify()
            Tier 1: SQLite local cache (fastest)
            Tier 2: Firebase Realtime DB search
            Tier 3: OpenFDA REST API
      → confidence scoring (Levenshtein similarity)
      → GeminiService.generateMedicineSummary()
      → RealtimeDatabaseService.saveToHistory()
```

- OCR strips non-Latin characters (`[^\x20-\x7E\xA0-\xFF]`).
  Urdu text on packaging is intentionally ignored — OCR is Latin-script only.
- Confidence thresholds: high ≥ 0.75, medium 0.45–0.75, low < 0.45.
  Medium confidence routes to `/confidence` for user review.

---

## Theme

Global ElevatedButton and OutlinedButton themes set `minimumSize: Size(double.infinity, 48)`.
**Any button inside a Row must override this:**
```dart
ElevatedButton.styleFrom(
  minimumSize: Size.zero,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  // ... other styles
)
```
Failing to do so causes `BoxConstraints forces an infinite width` crash at runtime.

---

## Android Configuration

- `targetSdk`: 34 (Android 14)
- `minSdk`: from `flutter.minSdkVersion` (defined by Flutter SDK)
- Permissions declared: `INTERNET`, `CAMERA`, `READ_EXTERNAL_STORAGE` (≤API 32),
  `READ_MEDIA_IMAGES` (≥API 33)
- Release builds currently use debug signing — add proper signing config before
  publishing to Play Store.

---

## Common Commands

```bash
# Run on connected device
flutter run

# Run with release build
flutter run --release

# Clean build artifacts
flutter clean && flutter pub get

# Build APK
flutter build apk --release

# Check for dependency issues
flutter pub deps

# Analyze code
flutter analyze
```

---

## Known Issues / Gotchas

- **`google_generative_ai: ^0.4.6`** uses the `v1beta` endpoint. Some newer Gemini
  models may only be available on `v1`. If a new model gives 404, try updating the
  package version before changing the model name.
- **OpenFDA** is a US medicine database. Pakistani brand names will mostly miss Tier 3.
  The local `medicines.json` database is the primary source — keep it updated.
- **Anonymous sign-in** must be enabled in Firebase Console → Authentication →
  Sign-in providers. If it's disabled, the splash screen continues without a user
  (graceful degradation).
- **Google Sign-In** requires the SHA-1 certificate fingerprint registered in
  Firebase Console. The current hash `1368d22e3c8d09d29d2bf0530ac13af49d7cea3a`
  is for debug builds. A different hash is needed for release builds.
- **Buffer drops** in camera logs (`slot N is dropped`) on mid-range devices are
  harmless cosmetic warnings from the Android `BufferQueue`. Not a code bug.
