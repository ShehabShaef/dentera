import 'dart:io';

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

      // Clean up physical radiograph image files from disk before cascade triggers
      try {
        final radiographRows = await db.query(
          'patient_radiographs',
          columns: <String>['filePath'],
          where: 'patientId = ?',
          whereArgs: <Object>[id],
        );
        for (final row in radiographRows) {
          final path = row['filePath'] as String?;
          if (path != null && path.isNotEmpty) {
            try {
              final file = File(path);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (e) {
              AppLogger.warning('Could not delete radiograph file on patient deletion: $path ($e)');
            }
          }
        }
      } catch (e) {
        // Table might not exist in isolated test databases or legacy schemas
        AppLogger.debug('Could not query patient_radiographs during patient deletion: $e');
      }

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
  Future<void> deletePatients(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      final db = await _dbManager.database;

      // Clean up physical radiograph image files for all patients being batch deleted
      final placeholders = List.filled(ids.length, '?').join(', ');
      try {
        final radiographRows = await db.query(
          'patient_radiographs',
          columns: <String>['filePath'],
          where: 'patientId IN ($placeholders)',
          whereArgs: ids,
        );
        for (final row in radiographRows) {
          final path = row['filePath'] as String?;
          if (path != null && path.isNotEmpty) {
            try {
              final file = File(path);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (e) {
              AppLogger.warning('Could not delete radiograph file on batch patient deletion: $path ($e)');
            }
          }
        }
      } catch (e) {
        // Table might not exist in isolated test databases or legacy schemas
        AppLogger.debug('Could not query patient_radiographs during batch patient deletion: $e');
      }

      await db.transaction((txn) async {
        await txn.delete(
          _tableName,
          where: 'id IN ($placeholders)',
          whereArgs: ids,
        );
      });
      AppLogger.info('Batch deleted ${ids.length} patients with cascade');
    } catch (e) {
      throw LocalDatabaseException('Failed to delete patients: $ids', e);
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
