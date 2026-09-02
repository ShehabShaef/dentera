import 'package:sqflite/sqflite.dart';

import '../../core/error/exceptions.dart';
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
}
