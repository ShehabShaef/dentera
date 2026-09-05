import 'exceptions.dart';

/// Thrown when an SQLite operation fails due to database file locking,
/// transaction contention, or busy timeout.
///
/// In an offline-first architecture with concurrent UI read operations and
/// background batch operations, SQLite can occasionally encounter lock contention.
/// Catching this exception allows the UI to present a transient retry prompt
/// rather than terminating the session.
class DatabaseLockedException extends LocalDatabaseException {
  const DatabaseLockedException([
    super.message = 'The local database is currently locked by another operation. Please retry in a moment.',
    super.cause,
  ]);

  @override
  String toString() {
    if (cause != null) {
      return 'DatabaseLockedException: $message (Cause: $cause)';
    }
    return 'DatabaseLockedException: $message';
  }
}

/// Thrown when an SQLite insert, update, or delete mutation fails to persist.
///
/// Indicates constraint violations, schema mismatches, or disk write failures
/// when persisting domain entities (such as Patients, Appointments, or Case Records).
class DataWriteException extends LocalDatabaseException {
  const DataWriteException([
    super.message = 'Failed to write record to local storage.',
    super.cause,
  ]);

  @override
  String toString() {
    if (cause != null) {
      return 'DataWriteException: $message (Cause: $cause)';
    }
    return 'DataWriteException: $message';
  }
}

/// Thrown when attempting an SQLite write operation on a read-only database instance
/// or filesystem location.
class DatabaseReadOnlyException extends LocalDatabaseException {
  const DatabaseReadOnlyException([
    super.message = 'Local database is open in read-only mode.',
    super.cause,
  ]);

  @override
  String toString() {
    if (cause != null) {
      return 'DatabaseReadOnlyException: $message (Cause: $cause)';
    }
    return 'DatabaseReadOnlyException: $message';
  }
}
