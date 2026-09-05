import 'package:sqflite/sqflite.dart';

import '../../core/error/exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/patient_repository.dart';
import '../database/app_database.dart';

/// SQLite implementation of [PatientRepository].
class SqlitePatientRepository implements PatientRepository {
  SqlitePatientRepository([AppDatabase? database])
      : _dbManager = database ?? AppDatabase.instance;

  final AppDatabase _dbManager;
  static const String _tableName = 'patients';

  @override
  Future<void> addPatient(Patient patient) async {
    try {
      final db = await _dbManager.database;
      await db.insert(
        _tableName,
        patient.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to insert patient: ${patient.id}', e);
    }
  }

  @override
  Future<void> updatePatient(Patient patient) async {
    try {
      final db = await _dbManager.database;
      final count = await db.update(
        _tableName,
        patient.toMap(),
        where: 'id = ?',
        whereArgs: <Object>[patient.id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Patient not found with id: ${patient.id}');
      }
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      throw LocalDatabaseException('Failed to update patient: ${patient.id}', e);
    }
  }

  @override
  Future<void> deletePatient(String id) async {
    try {
      final db = await _dbManager.database;
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Patient not found with id: $id');
      }
      AppLogger.info('Patient $id deleted; cascade execution triggered for child case records and appointments');
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      throw LocalDatabaseException('Failed to delete patient: $id', e);
    }
  }

  @override
  Future<List<Patient>> getAllPatients() async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        orderBy: 'createdAt DESC',
      );
      return results.map((map) => Patient.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query all patients', e);
    }
  }

  @override
  Future<Patient?> getPatientById(String id) async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: <Object>[id],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return Patient.fromMap(results.first);
    } catch (e) {
      throw LocalDatabaseException('Failed to query patient by id: $id', e);
    }
  }
}
