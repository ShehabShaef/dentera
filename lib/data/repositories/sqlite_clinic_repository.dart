import 'package:sqflite/sqflite.dart';

import '../../core/error/exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/clinic_repository.dart';
import '../database/app_database.dart';

/// SQLite implementation of [ClinicRepository].
class SqliteClinicRepository implements ClinicRepository {
  SqliteClinicRepository([AppDatabase? database])
      : _dbManager = database ?? AppDatabase.instance;

  final AppDatabase _dbManager;
  static const String _tableName = 'clinics';

  @override
  Future<List<Clinic>> getAllClinics() async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        orderBy: 'name ASC',
      );
      return results.map((map) => Clinic.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query all clinics', e);
    }
  }

  @override
  Future<Clinic?> getClinicById(String id) async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: <Object>[id],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return Clinic.fromMap(results.first);
    } catch (e) {
      throw LocalDatabaseException('Failed to query clinic by id: $id', e);
    }
  }

  @override
  Future<void> addClinic(Clinic clinic) async {
    try {
      final db = await _dbManager.database;
      await db.insert(
        _tableName,
        clinic.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to insert clinic: ${clinic.id}', e);
    }
  }

  @override
  Future<void> updateClinic(Clinic clinic) async {
    try {
      final db = await _dbManager.database;
      final count = await db.update(
        _tableName,
        clinic.toMap(),
        where: 'id = ?',
        whereArgs: <Object>[clinic.id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Clinic not found with id: ${clinic.id}');
      }
      AppLogger.info('Updated clinic: ${clinic.id}');
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      throw LocalDatabaseException('Failed to update clinic: ${clinic.id}', e);
    }
  }

  @override
  Future<void> deleteClinic(String id) async {
    await deleteClinics(<String>[id]);
  }

  @override
  Future<void> deleteClinics(List<String> ids) async {
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
      AppLogger.info('Batch deleted ${ids.length} clinics with cascade');
    } catch (e) {
      throw LocalDatabaseException('Failed to delete clinics: $ids', e);
    }
  }
}
