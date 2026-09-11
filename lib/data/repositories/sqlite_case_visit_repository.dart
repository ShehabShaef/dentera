import 'package:sqflite/sqflite.dart';

import '../../core/error/exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/case_visit_repository.dart';
import '../database/app_database.dart';

/// SQLite implementation of [CaseVisitRepository].
class SqliteCaseVisitRepository implements CaseVisitRepository {
  SqliteCaseVisitRepository([AppDatabase? database])
      : _dbManager = database ?? AppDatabase.instance;

  final AppDatabase _dbManager;
  static const String _tableName = 'case_visits';

  @override
  Future<void> addCaseVisit(CaseVisit caseVisit) async {
    try {
      final db = await _dbManager.database;
      await db.insert(
        _tableName,
        caseVisit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      AppLogger.error(
        '[SqliteCaseVisitRepository] Failed to insert case visit: ${caseVisit.id}',
        e,
      );
      throw LocalDatabaseException('Failed to insert case visit: ${caseVisit.id}', e);
    }
  }

  @override
  Future<void> addCaseVisits(List<CaseVisit> caseVisits) async {
    if (caseVisits.isEmpty) return;
    try {
      final db = await _dbManager.database;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final visit in caseVisits) {
          batch.insert(
            _tableName,
            visit.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      AppLogger.error(
        '[SqliteCaseVisitRepository] Failed to batch insert case visits',
        e,
      );
      throw LocalDatabaseException('Failed to batch insert case visits', e);
    }
  }

  @override
  Future<void> updateCaseVisit(CaseVisit caseVisit) async {
    try {
      final db = await _dbManager.database;
      final count = await db.update(
        _tableName,
        caseVisit.toMap(),
        where: 'id = ?',
        whereArgs: <Object>[caseVisit.id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Case visit not found with id: ${caseVisit.id}');
      }
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      AppLogger.error(
        '[SqliteCaseVisitRepository] Failed to update case visit: ${caseVisit.id}',
        e,
      );
      throw LocalDatabaseException('Failed to update case visit: ${caseVisit.id}', e);
    }
  }

  @override
  Future<void> deleteCaseVisit(String id) async {
    try {
      final db = await _dbManager.database;
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Case visit not found with id: $id');
      }
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      AppLogger.error(
        '[SqliteCaseVisitRepository] Failed to delete case visit: $id',
        e,
      );
      throw LocalDatabaseException('Failed to delete case visit: $id', e);
    }
  }

  @override
  Future<List<CaseVisit>> getVisitsByCaseRecordId(String caseRecordId) async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        where: 'caseRecordId = ?',
        whereArgs: <Object>[caseRecordId],
        orderBy: 'visitNumber ASC',
      );
      return results.map((map) => CaseVisit.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query case visits for case record: $caseRecordId', e);
    }
  }

  @override
  Future<List<CaseVisit>> getAllVisits() async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        orderBy: 'visitNumber ASC',
      );
      return results.map((map) => CaseVisit.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query all case visits', e);
    }
  }
}
