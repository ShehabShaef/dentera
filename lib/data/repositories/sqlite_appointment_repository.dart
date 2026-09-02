import 'package:sqflite/sqflite.dart';

import '../../core/error/exceptions.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../database/app_database.dart';

/// SQLite implementation of [AppointmentRepository].
class SqliteAppointmentRepository implements AppointmentRepository {
  SqliteAppointmentRepository([AppDatabase? database])
      : _dbManager = database ?? AppDatabase.instance;

  final AppDatabase _dbManager;
  static const String _tableName = 'appointments';

  @override
  Future<void> addAppointment(Appointment appointment) async {
    try {
      final db = await _dbManager.database;
      await db.insert(
        _tableName,
        appointment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to insert appointment: ${appointment.id}', e);
    }
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    try {
      final db = await _dbManager.database;
      final count = await db.update(
        _tableName,
        appointment.toMap(),
        where: 'id = ?',
        whereArgs: <Object>[appointment.id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Appointment not found with id: ${appointment.id}');
      }
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      throw LocalDatabaseException('Failed to update appointment: ${appointment.id}', e);
    }
  }

  @override
  Future<void> deleteAppointment(String id) async {
    try {
      final db = await _dbManager.database;
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Appointment not found with id: $id');
      }
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      throw LocalDatabaseException('Failed to delete appointment: $id', e);
    }
  }

  @override
  Future<List<Appointment>> getAppointmentsByDate(DateTime date) async {
    try {
      final db = await _dbManager.database;
      // Extract YYYY-MM-DD prefix for day-level matching
      final dateIso = date.toIso8601String();
      final dayPrefix = dateIso.substring(0, 10);

      final results = await db.query(
        _tableName,
        where: 'scheduledDate LIKE ?',
        whereArgs: <Object>['$dayPrefix%'],
        orderBy: 'scheduledDate ASC',
      );
      return results.map((map) => Appointment.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query appointments for date: $date', e);
    }
  }

  @override
  Future<List<Appointment>> getAppointmentsByPatientId(String patientId) async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        where: 'patientId = ?',
        whereArgs: <Object>[patientId],
        orderBy: 'scheduledDate ASC',
      );
      return results.map((map) => Appointment.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query appointments for patient: $patientId', e);
    }
  }

  @override
  Future<List<Appointment>> getAllAppointments() async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        orderBy: 'scheduledDate ASC',
      );
      return results.map((map) => Appointment.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query all appointments', e);
    }
  }
}
