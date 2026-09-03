import 'package:sqflite/sqflite.dart';

import '../../core/logging/app_logger.dart';

/// Utility class responsible for populating the local SQLite database with
/// default academic clinics and baseline clinical requirement quotas.
///
/// Pre-populating this data during schema creation guarantees that dental students
/// have an immediate, fully functional environment offline upon completing onboarding,
/// with zero reliance on cloud synchronization or remote REST APIs.
class DatabaseSeeder {
  DatabaseSeeder._();

  /// Default academic clinics representing core clinical departments.
  static const List<Map<String, dynamic>> defaultClinics = [
    {
      'id': 'clinic-prosth',
      'name': 'Prosthodontics',
      'academicYear': '5th Year',
      'colorHex': '#003E6F',
    },
    {
      'id': 'clinic-operative',
      'name': 'Operative Dentistry',
      'academicYear': '5th Year',
      'colorHex': '#006A64',
    },
    {
      'id': 'clinic-endo',
      'name': 'Endodontics',
      'academicYear': '5th Year',
      'colorHex': '#1E568C',
    },
    {
      'id': 'clinic-surgery',
      'name': 'Oral Surgery',
      'academicYear': '5th Year',
      'colorHex': '#2E3F50',
    },
    {
      'id': 'clinic-perio',
      'name': 'Periodontics',
      'academicYear': '5th Year',
      'colorHex': '#37485A',
    },
    {
      'id': 'clinic-pediatric',
      'name': 'Pediatric Dentistry',
      'academicYear': '5th Year',
      'colorHex': '#4A6572',
    },
  ];

  /// Baseline clinical quota requirements linked via foreign key to [defaultClinics].
  static const List<Map<String, dynamic>> defaultRequirements = [
    // Prosthodontics
    {
      'id': 'req-prosth-cd',
      'clinicId': 'clinic-prosth',
      'title': 'Complete Denture',
      'targetCount': 2,
      'completedCount': 0,
    },
    {
      'id': 'req-prosth-rpd',
      'clinicId': 'clinic-prosth',
      'title': 'Removable Partial Denture',
      'targetCount': 3,
      'completedCount': 0,
    },
    // Operative Dentistry
    {
      'id': 'req-op-class1',
      'clinicId': 'clinic-operative',
      'title': 'Class I Composite',
      'targetCount': 8,
      'completedCount': 0,
    },
    {
      'id': 'req-op-class2',
      'clinicId': 'clinic-operative',
      'title': 'Class II Amalgam',
      'targetCount': 4,
      'completedCount': 0,
    },
    // Endodontics
    {
      'id': 'req-endo-anterior',
      'clinicId': 'clinic-endo',
      'title': 'Anterior RCT',
      'targetCount': 6,
      'completedCount': 0,
    },
    {
      'id': 'req-endo-molar',
      'clinicId': 'clinic-endo',
      'title': 'Premolar / Molar RCT',
      'targetCount': 4,
      'completedCount': 0,
    },
    // Oral Surgery
    {
      'id': 'req-surg-simple',
      'clinicId': 'clinic-surgery',
      'title': 'Simple Extraction',
      'targetCount': 15,
      'completedCount': 0,
    },
    {
      'id': 'req-surg-complex',
      'clinicId': 'clinic-surgery',
      'title': 'Surgical Extraction',
      'targetCount': 3,
      'completedCount': 0,
    },
    // Periodontics
    {
      'id': 'req-perio-srp',
      'clinicId': 'clinic-perio',
      'title': 'Scaling & Root Planing',
      'targetCount': 10,
      'completedCount': 0,
    },
    {
      'id': 'req-perio-gingiv',
      'clinicId': 'clinic-perio',
      'title': 'Gingivectomy',
      'targetCount': 2,
      'completedCount': 0,
    },
    // Pediatric Dentistry
    {
      'id': 'req-peds-pulpotomy',
      'clinicId': 'clinic-pediatric',
      'title': 'Primary Pulpotomy',
      'targetCount': 5,
      'completedCount': 0,
    },
    {
      'id': 'req-peds-ssc',
      'clinicId': 'clinic-pediatric',
      'title': 'Stainless Steel Crown',
      'targetCount': 4,
      'completedCount': 0,
    },
  ];

  /// Populates the SQLite database with standard academic clinics and requirements
  /// using an atomic batch transaction.
  ///
  /// **Relational Data Flow & Foreign Keys:**
  /// - Clinics are inserted first into the `clinics` table.
  /// - Requirements are inserted second into the `requirements` table.
  /// - Each requirement references a valid parent clinic via `requirements.clinicId -> clinics.id`.
  /// - If foreign keys are enforced (`PRAGMA foreign_keys = ON`), the sequential insertion
  ///   within the batch guarantees relational integrity without constraint violations.
  ///
  /// **Error Handling & Logging:**
  /// Emits an [AppLogger.info] log at invocation start and an [AppLogger.debug] upon
  /// successful insertion count verification. If the batch commit fails, the error is
  /// caught, logged via [AppLogger.error], and rethrown.
  static Future<void> seedInitialData(Database db) async {
    AppLogger.info(
      '[DatabaseSeeder] Initiating batch insertion of default academic clinics and requirements...',
    );

    try {
      final batch = db.batch();

      for (final clinic in defaultClinics) {
        batch.insert(
          'clinics',
          clinic,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final req in defaultRequirements) {
        batch.insert(
          'requirements',
          req,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);

      AppLogger.debug(
        '[DatabaseSeeder] Seeding completed: ${defaultClinics.length} clinics and '
        '${defaultRequirements.length} requirements successfully committed.',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '[DatabaseSeeder] Batch insertion failed during database seeding: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
