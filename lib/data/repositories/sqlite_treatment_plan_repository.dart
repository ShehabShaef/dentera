import 'package:sqflite/sqflite.dart';

import '../../core/error/exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/treatment_plan_repository.dart';
import '../database/app_database.dart';

/// SQLite implementation of [TreatmentPlanRepository].
class SqliteTreatmentPlanRepository implements TreatmentPlanRepository {
  SqliteTreatmentPlanRepository([AppDatabase? database])
      : _dbManager = database ?? AppDatabase.instance;

  final AppDatabase _dbManager;
  static const String _tableName = 'treatment_plans';

  @override
  Future<void> addTreatmentPlan(TreatmentPlan plan) async {
    try {
      final db = await _dbManager.database;
      await db.insert(
        _tableName,
        plan.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.info(
        '[SqliteTreatmentPlanRepository] Inserted treatment plan: ${plan.id} for patient: ${plan.patientId} (Phase: ${plan.phase})',
      );
    } catch (e) {
      AppLogger.error(
        '[SqliteTreatmentPlanRepository] Failed to insert treatment plan: ${plan.id}',
        e,
      );
      throw LocalDatabaseException('Failed to insert treatment plan: ${plan.id}', e);
    }
  }

  @override
  Future<void> updateTreatmentPlan(TreatmentPlan plan) async {
    try {
      final db = await _dbManager.database;
      final count = await db.update(
        _tableName,
        plan.toMap(),
        where: 'id = ?',
        whereArgs: <Object>[plan.id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Treatment plan not found with id: ${plan.id}');
      }
      AppLogger.info(
        '[SqliteTreatmentPlanRepository] Updated treatment plan: ${plan.id} (Status: ${plan.status})',
      );
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      AppLogger.error(
        '[SqliteTreatmentPlanRepository] Failed to update treatment plan: ${plan.id}',
        e,
      );
      throw LocalDatabaseException('Failed to update treatment plan: ${plan.id}', e);
    }
  }

  @override
  Future<void> deleteTreatmentPlan(String id) async {
    try {
      final db = await _dbManager.database;
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Treatment plan not found with id: $id');
      }
      AppLogger.info(
        '[SqliteTreatmentPlanRepository] Deleted treatment plan: $id',
      );
    } catch (e) {
      if (e is RecordNotFoundException) rethrow;
      AppLogger.error(
        '[SqliteTreatmentPlanRepository] Failed to delete treatment plan: $id',
        e,
      );
      throw LocalDatabaseException('Failed to delete treatment plan: $id', e);
    }
  }

  @override
  Future<TreatmentPlan?> getTreatmentPlanById(String id) async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: <Object>[id],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return TreatmentPlan.fromMap(results.first);
    } catch (e) {
      throw LocalDatabaseException('Failed to query treatment plan by id: $id', e);
    }
  }

  @override
  Future<List<TreatmentPlan>> getTreatmentPlansByPatient(String patientId) async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        where: 'patientId = ?',
        whereArgs: <Object>[patientId],
        orderBy: 'phase ASC, createdAt ASC',
      );
      return results.map((map) => TreatmentPlan.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query treatment plans for patient: $patientId', e);
    }
  }

  @override
  Future<List<TreatmentPlan>> getAllTreatmentPlans() async {
    try {
      final db = await _dbManager.database;
      final results = await db.query(
        _tableName,
        orderBy: 'phase ASC, createdAt ASC',
      );
      return results.map((map) => TreatmentPlan.fromMap(map)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to query all treatment plans', e);
    }
  }
}
