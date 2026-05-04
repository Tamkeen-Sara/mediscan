import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Central logger. In debug builds, writes to the Dart developer log.
/// Replace the error() stub with FirebaseCrashlytics.instance.recordError()
/// once Crashlytics is wired up.
class AppLogger {
  AppLogger._();

  static void info(String message, {String tag = 'MediScan'}) {
    if (kDebugMode) dev.log(message, name: tag);
  }

  static void warning(String message,
      {String tag = 'MediScan', Object? error}) {
    if (kDebugMode) dev.log('⚠ $message', name: tag, error: error);
  }

  static void error(
    String message, {
    String tag = 'MediScan',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      dev.log('✖ $message', name: tag, error: error, stackTrace: stackTrace);
    }
    // TODO: uncomment after adding firebase_crashlytics to pubspec.yaml
    // if (!kDebugMode && error != null) {
    //   FirebaseCrashlytics.instance.recordError(
    //     error, stackTrace,
    //     reason: message,
    //     fatal: false,
    //   );
    // }
  }
}
