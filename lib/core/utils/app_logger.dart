import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logger. Import this file and use [appLogger] directly.
///
/// Usage:
/// ```dart
/// import 'package:delivery_boy/core/utils/app_logger.dart';
///
/// appLogger.d('debug message');
/// appLogger.i('info message');
/// appLogger.w('warning message');
/// appLogger.e('error message', error: e, stackTrace: s);
/// ```
final appLogger = Logger(
  level: kDebugMode ? Level.debug : Level.warning,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 100,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
