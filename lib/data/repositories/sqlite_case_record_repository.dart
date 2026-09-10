import 'package:sqflite/sqflite.dart';

import '../../core/error/exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/case_record_repository.dart';
import '../database/app_database.dart';

/// SQLite implementation of [CaseRecordRepository].
class SqliteCaseRecordRepository implements CaseRecordRepository {
  SqliteCaseRecordRepository([AppDatabase? database])
      : _dbManager = database ?? AppDatabase.instance;

  final AppDatabase _dbManager;
  static const String _tableName = 'case_records';

  /// Helper to determine if a case record status represents completion or faculty evaluation.
  bool _isCompleted(String status) {
    final s = status.trim().toLowerCase();
    return s == 'completed' || s == 'evaluated';
  }

  @override
  Future<void> addCaseRecord(CaseRecord caseRecord) async {
    try {
      final db = await _dbManager.database;
      await db.transaction((txn) async {
        await txn.insert(
          _tableName,
          caseRecord.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // If the newly created case is already in Completed/Evaluated status, increment quota
        if (_isCompleted(caseRecord.status)) {
          await txn.rawUpdate(
            'UPDATE requirements SET completedCount = completedCount + 1 WHERE id = ?',
            <Object>[caseRecord.requirementId],
          );
          AppLogger.info(
            '[SqliteCaseRecordRepository] Incremented completedCount for requirement: ${caseRecord.requirementId} on case creation (status: "${caseRecord.status}")',
          );
        }
      });
    } catch (e) {
      AppLogger.error(
        '[SqliteCaseRecordRepository] Failed to insert case record: ${caseRecord.id}',
        e,
      );
      throw LocalDatabaseException('Failed to insert case record: ${caseRecord.id}', e);
    }
  }

  @override
  Future<void> updateCaseRecord(CaseRecord caseRecord) async {
    try {
      final db = await _dbManager.database;
      await db.transaction((txn) async {
        // 1. Fetch prior record to inspect previous completion status
        final priorResults = await txn.query(
          _tableName,
          where: 'id = ?',
          whereArgs: <Object>[caseRecord.id],
        );
        if (priorResults.isEmpty) {
          throw RecordNotFoundException('Case record not found with id: ${caseRecord.id}');
        }

        final priorRecord = CaseRecord.fromMap(priorResults.first);
        final priorCompleted = _isCompleted(priorRecord.status);
        final newCompleted = _isCompleted(caseRecord.status);

        // 2. Persist updated case_records row atomically
        final count = await txn.update(
          _tableName,
          caseRecord.toMap(),
          where: 'id = ?',
          whereArgs: <Object>[caseRecord.id],
        );
        if (count == 0) {
          throw RecordNotFoundException('Case record not found with id: ${caseRecord.id}');
        }

        // 3. Synchronize requirement completedCount quota
        if (priorRecord.requirementId == caseRecord.requirementId) {
          if (!priorCompleted && newCompleted) {
            // Newly transitioned to Completed or Evaluated -> increment requirement quota
            await txn.rawUpdate(
              'UPDATE requirements SET completedCount = completedCount + 1 WHERE id = ?',
              <Object>[caseRecord.requirementId],
            );
            AppLogger.info(
              '[SqliteCaseRecordRepository] Atomic quota sync: incremented completedCount for requirement: ${caseRecord.requirementId} (case ${caseRecord.id}: "${priorRecord.status}" -> "${caseRecord.status}")',
            );
          } else if (priorCompleted && !newCompleted) {
            // Transitioned back to In Progress -> decrement requirement quota safely (floor at 0)
            await txn.rawUpdate(
              'UPDATE requirements SET completedCount = MAX(0, completedCount - 1) WHERE id = ?',
              <Object>[caseRecord.requirementId],
            );
            AppLogger.info(
              '[SqliteCaseRecordRepository] Atomic quota sync: decremented completedCount for requirement: ${caseRecord.requirementId} (case ${caseRecord.id}: "${priorRecord.status}" -> "${caseRecord.status}")',
            );
          }
        } else {
          // Edge case: Requirement ID was changed concurrently
          if (priorCompleted) {
            await txn.rawUpdate(
              'UPDATE requirements SET completedCount = MAX(0, completedCount - 1) WHERE id = ?',
              <Object>[priorRecord.requirementId],
            );
          }
          if (newCompleted) {
            await txn.rawUpdate(
              'UPDATE requirements SET completedCount = completedCount + 1 WHERE id = ?',
              <Object>[caseRecord.requirementId],
            );
          }
        }
      });
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      AppLogger.error(
        '[SqliteCaseRecordRepository] Failed to update case record: ${caseRecord.id}',
        e,
      );
      throw LocalDatabaseException('Failed to update case record: ${caseRecord.id}', e);
    }
  }

  @override
  Future<List<CaseRecord>> getCaseRecordsByPatientId(String patientId) async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        where: 'patientId = ?',
        whereArgs: <Object>[patientId],
        orderBy: 'dateStarted DESC',
      );
      return results.map((map) => CaseRecord.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query case records for patient: $patientId', e);
    }
  }

  @override
  Future<List<CaseRecord>> getCaseRecordsByRequirementId(String requirementId) async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        where: 'requirementId = ?',
        whereArgs: <Object>[requirementId],
        orderBy: 'dateStarted DESC',
      );
      return results.map((map) => CaseRecord.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query case records for requirement: $requirementId', e);
    }
  }

  @override
  Future<List<CaseRecord>> getAllCaseRecords() async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        orderBy: 'dateStarted DESC',
      );
      return results.map((map) => CaseRecord.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query all case records', e);
    }
  }

  @override
  Future<void> deleteCaseRecord(String id) async {
    try {
      final db = await _dbManager.database;
      await db.transaction((txn) async {
        final priorResults = await txn.query(
          _tableName,
          where: 'id = ?',
          whereArgs: <Object>[id],
        );
        if (priorResults.isEmpty) {
          throw RecordNotFoundException('Case record not found with id: $id');
        }

        final priorRecord = CaseRecord.fromMap(priorResults.first);
        final priorCompleted = _isCompleted(priorRecord.status);

        final count = await txn.delete(
          _tableName,
          where: 'id = ?',
          whereArgs: <Object>[id],
        );
        if (count == 0) {
          throw RecordNotFoundException('Case record not found with id: $id');
        }

        if (priorCompleted) {
          await txn.rawUpdate(
            'UPDATE requirements SET completedCount = MAX(0, completedCount - 1) WHERE id = ?',
            <Object>[priorRecord.requirementId],
          );
          AppLogger.info(
            '[SqliteCaseRecordRepository] Atomic quota sync: decremented completedCount for requirement: ${priorRecord.requirementId} upon deleting completed case ($id)',
          );
        }
      });
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      AppLogger.error(
        '[SqliteCaseRecordRepository] Failed to delete case record: $id',
        e,
      );
      throw LocalDatabaseException('Failed to delete case record: $id', e);
    }
  }
}
