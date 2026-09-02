import 'package:sqflite/sqflite.dart';

import '../../core/error/exceptions.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/case_record_repository.dart';
import '../database/app_database.dart';

/// SQLite implementation of [CaseRecordRepository].
class SqliteCaseRecordRepository implements CaseRecordRepository {
  SqliteCaseRecordRepository([AppDatabase? database])
      : _dbManager = database ?? AppDatabase.instance;

  final AppDatabase _dbManager;
  static const String _tableName = 'case_records';

  @override
  Future<void> addCaseRecord(CaseRecord caseRecord) async {
    try {
      final db = await _dbManager.database;
      await db.insert(
        _tableName,
        caseRecord.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to insert case record: ${caseRecord.id}', e);
    }
  }

  @override
  Future<void> updateCaseRecord(CaseRecord caseRecord) async {
    try {
      final db = await _dbManager.database;
      final count = await db.update(
        _tableName,
        caseRecord.toMap(),
        where: 'id = ?',
        whereArgs: <Object>[caseRecord.id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Case record not found with id: ${caseRecord.id}');
      }
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
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
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Case record not found with id: $id');
      }
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      throw LocalDatabaseException('Failed to delete case record: $id', e);
    }
  }
}
