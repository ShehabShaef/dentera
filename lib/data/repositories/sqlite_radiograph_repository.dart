import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../../core/error/exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/radiograph_repository.dart';
import '../database/app_database.dart';

/// SQLite implementation of [RadiographRepository].
class SqliteRadiographRepository implements RadiographRepository {
  SqliteRadiographRepository([AppDatabase? database])
      : _dbManager = database ?? AppDatabase.instance;

  final AppDatabase _dbManager;
  static const String _tableName = 'patient_radiographs';

  @override
  Future<void> addRadiograph(PatientRadiograph radiograph) async {
    try {
      final db = await _dbManager.database;
      await db.insert(
        _tableName,
        radiograph.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.info(
        '[SqliteRadiographRepository] Inserted radiograph: ${radiograph.id} for patient: ${radiograph.patientId} (${radiograph.type})',
      );
    } catch (e) {
      AppLogger.error(
        '[SqliteRadiographRepository] Failed to insert radiograph: ${radiograph.id}',
        e,
      );
      throw LocalDatabaseException('Failed to insert radiograph: ${radiograph.id}', e);
    }
  }

  @override
  Future<void> updateRadiograph(PatientRadiograph radiograph) async {
    try {
      final db = await _dbManager.database;
      final count = await db.update(
        _tableName,
        radiograph.toMap(),
        where: 'id = ?',
        whereArgs: <Object>[radiograph.id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Radiograph not found with id: ${radiograph.id}');
      }
      AppLogger.info(
        '[SqliteRadiographRepository] Updated radiograph: ${radiograph.id}',
      );
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      AppLogger.error(
        '[SqliteRadiographRepository] Failed to update radiograph: ${radiograph.id}',
        e,
      );
      throw LocalDatabaseException('Failed to update radiograph: ${radiograph.id}', e);
    }
  }

  @override
  Future<void> deleteRadiograph(String id) async {
    try {
      final db = await _dbManager.database;

      // 1. Fetch file path to cleanly purge from disk before DB deletion
      final existing = await db.query(
        _tableName,
        columns: <String>['filePath'],
        where: 'id = ?',
        whereArgs: <Object>[id],
        limit: 1,
      );

      String? filePath;
      if (existing.isNotEmpty) {
        filePath = existing.first['filePath'] as String?;
      }

      // 2. Delete database row
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Radiograph not found with id: $id');
      }

      // 3. Remove physical image file from disk to prevent storage leaks
      if (filePath != null && filePath.isNotEmpty) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
            AppLogger.info('[SqliteRadiographRepository] Deleted radiograph file: $filePath');
          }
        } catch (e) {
          AppLogger.warning('[SqliteRadiographRepository] Could not delete file: $filePath ($e)');
        }
      }

      AppLogger.info('[SqliteRadiographRepository] Deleted radiograph: $id');
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      AppLogger.error('[SqliteRadiographRepository] Failed to delete radiograph: $id', e);
      throw LocalDatabaseException('Failed to delete radiograph: $id', e);
    }
  }

  @override
  Future<PatientRadiograph?> getRadiographById(String id) async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: <Object>[id],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return PatientRadiograph.fromMap(results.first);
    } catch (e) {
      AppLogger.error('[SqliteRadiographRepository] Failed to get radiograph by id: $id', e);
      throw LocalDatabaseException('Failed to get radiograph by id: $id', e);
    }
  }

  @override
  Future<List<PatientRadiograph>> getRadiographsByPatient(String patientId) async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        where: 'patientId = ?',
        whereArgs: <Object>[patientId],
        orderBy: 'captureDate DESC, createdAt DESC',
      );
      return results.map((map) => PatientRadiograph.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error(
        '[SqliteRadiographRepository] Failed to query radiographs for patient: $patientId',
        e,
      );
      throw LocalDatabaseException(
        'Failed to query radiographs for patient: $patientId',
        e,
      );
    }
  }

  @override
  Future<List<PatientRadiograph>> getAllRadiographs() async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        orderBy: 'captureDate DESC, createdAt DESC',
      );
      return results.map((map) => PatientRadiograph.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('[SqliteRadiographRepository] Failed to query all radiographs', e);
      throw LocalDatabaseException('Failed to query all radiographs', e);
    }
  }
}
