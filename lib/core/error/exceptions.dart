/// Custom exception thrown when a database or local storage error occurs.
class LocalDatabaseException implements Exception {
  const LocalDatabaseException(this.message, [this.cause]);

  final String message;
  final dynamic cause;

  @override
  String toString() {
    if (cause != null) {
      return 'LocalDatabaseException: $message (Cause: $cause)';
    }
    return 'LocalDatabaseException: $message';
  }
}

/// Thrown when a requested record is not found in local storage.
class RecordNotFoundException implements Exception {
  const RecordNotFoundException(this.message);

  final String message;

  @override
  String toString() => 'RecordNotFoundException: $message';
}
