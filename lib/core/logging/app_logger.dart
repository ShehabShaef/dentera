import 'package:logger/logger.dart';

/// Global underlying [Logger] instance configured with a structured printer
/// for clean and readable console output across offline development.
final Logger _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 100,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// Centralized logging utility for the Dentera application.
///
/// Standardizes log formatting across the offline-first architecture, ensuring
/// clear visibility into SQLite transactions, Riverpod state mutations, and
/// clinical workflow lifecycle events.
class AppLogger {
  AppLogger._();

  /// Logs a debug message for detailed diagnostic information.
  ///
  /// **When to use:**
  /// - Granular SQLite execution traces (e.g., executing `SELECT * FROM patients WHERE id = ?`).
  /// - High-frequency UI rebuild triggers and local cache hits.
  /// - Raw parameter dumps and intermediate state computations.
  ///
  /// Debug messages should not be relied upon in release modes and are intended
  /// strictly for developer troubleshooting during active offline session development.
  static void debug(
    dynamic message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Logs an informational message representing significant business milestones.
  ///
  /// **When to use:**
  /// - Successful database record mutations (e.g., "Patient Jane Doe (id: p-1) successfully inserted").
  /// - Key clinical flow transitions (e.g., "Starting complete denture case record").
  /// - Application lifecycle milestones (e.g., "Offline SQLite database schema v1 initialized").
  ///
  /// Unlike [debug], [info] logs represent meaningful domain occurrences that confirm
  /// proper application progression without flooding the console.
  static void info(
    dynamic message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a warning message when an unexpected condition arises that does not halt execution.
  ///
  /// **When to use:**
  /// - Non-fatal recoverable situations (e.g., notification reminder skipped because notifications are disabled).
  /// - Deprecated schema access or fallback to default clinical values.
  /// - High query latency or approaching local storage limits.
  static void warning(
    dynamic message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Logs an error message accompanied by an optional exception and stack trace.
  ///
  /// **When to use:**
  /// - SQLite transaction rollbacks and constraint violations (e.g., foreign key failures).
  /// - Unhandled exceptions in Riverpod providers or asynchronous tasks.
  /// - Critical file system or encryption errors preventing local data persistence.
  static void error(
    dynamic message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
