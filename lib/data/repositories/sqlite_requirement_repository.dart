import 'package:sqflite/sqflite.dart';

import '../../core/error/exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/requirement_repository.dart';
import '../database/app_database.dart';

/// SQLite implementation of [RequirementRepository].
class SqliteRequirementRepository implements RequirementRepository {
  SqliteRequirementRepository([AppDatabase? database])
      : _dbManager = database ?? AppDatabase.instance;

  final AppDatabase _dbManager;
  static const String _tableName = 'requirements';

  @override
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId) async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        where: 'clinicId = ?',
        whereArgs: <Object>[clinicId],
        orderBy: 'title ASC',
      );
      return results.map((map) => Requirement.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query requirements for clinic: $clinicId', e);
    }
  }

  @override
  Future<List<Requirement>> getAllRequirements() async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        orderBy: 'clinicId ASC, title ASC',
      );
      return results.map((map) => Requirement.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query all requirements', e);
    }
  }

  @override
  Future<void> updateRequirementProgress(String requirementId, int completedCount) async {
    try {
      final db = await _dbManager.database;
      final count = await db.update(
        _tableName,
        <String, dynamic>{'completedCount': completedCount},
        where: 'id = ?',
        whereArgs: <Object>[requirementId],
      );
      if (count == 0) {
        throw RecordNotFoundException('Requirement not found with id: $requirementId');
      }
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      throw LocalDatabaseException('Failed to update requirement progress: $requirementId', e);
    }
  }

  @override
  Future<void> addRequirement(Requirement requirement) async {
    try {
      final db = await _dbManager.database;
      await db.insert(
        _tableName,
        requirement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to insert requirement: ${requirement.id}', e);
    }
  }

  @override
  Future<void> updateRequirement(Requirement requirement) async {
    try {
      final db = await _dbManager.database;
      final count = await db.update(
        _tableName,
        requirement.toMap(),
        where: 'id = ?',
        whereArgs: <Object>[requirement.id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Requirement not found with id: ${requirement.id}');
      }
      AppLogger.info('Updated requirement: ${requirement.id}');
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      throw LocalDatabaseException('Failed to update requirement: ${requirement.id}', e);
    }
  }

  @override
  Future<void> deleteRequirement(String id) async {
    await deleteRequirements(<String>[id]);
  }

  @override
  Future<void> deleteRequirements(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      final db = await _dbManager.database;
      await db.transaction((txn) async {
        final placeholders = List.filled(ids.length, '?').join(', ');
        await txn.delete(
          _tableName,
          where: 'id IN ($placeholders)',
          whereArgs: ids,
        );
      });
      AppLogger.info('Batch deleted ${ids.length} requirements with cascade');
    } catch (e) {
      throw LocalDatabaseException('Failed to delete requirements: $ids', e);
    }
  }
}
