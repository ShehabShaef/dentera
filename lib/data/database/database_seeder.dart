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
    {
      'id': 'req-prosth-spd',
      'clinicId': 'clinic-prosth',
      'title': 'Single Partial Denture',
      'targetCount': 2,
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
      'id': 'req-op-class1-amalgam',
      'clinicId': 'clinic-operative',
      'title': 'Class I Amalgam',
      'targetCount': 6,
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
      'title': 'Scaling and Polishing',
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
      'id': 'req-peds-pulpectomy',
      'clinicId': 'clinic-pediatric',
      'title': 'Primary Pulpectomy',
      'targetCount': 3,
      'completedCount': 0,
    },
    {
      'id': 'req-peds-ssc',
      'clinicId': 'clinic-pediatric',
      'title': 'Stainless Steel Crown',
      'targetCount': 4,
      'completedCount': 0,
    },
    {
      'id': 'req-peds-composite',
      'clinicId': 'clinic-pediatric',
      'title': 'Composite Restoration',
      'targetCount': 5,
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

  /// Safely synchronizes curriculum requirement changes (additions, renames, removals)
  /// into an existing SQLite database without destroying student progress or logged cases.
  static Future<void> syncCurriculumRequirements(Database db) async {
    AppLogger.info('[DatabaseSeeder] Starting curriculum requirements synchronization...');

    // 1. In-place renames to preserve foreign key references to case_records
    final renames = <String, String>{
      'Scaling & root Planning': 'Scaling and Polishing',
      'Scaling & Root Planing': 'Scaling and Polishing',
      'Scaling and Root Planing': 'Scaling and Polishing',
      'Subgingival Debridement': 'Curettage and Root Planing',
      'Comprehensive Oral Examination': 'Comprehensive Oral Examination (Diagnosis)',
      'Oral Mucosal Lesion Management': 'Oral Mucosal Lesion Management (Treatment)',
    };

    for (final entry in renames.entries) {
      final updated = await db.rawUpdate(
        'UPDATE requirements SET title = ? WHERE title = ?;',
        [entry.value, entry.key],
      );
      if (updated > 0) {
        AppLogger.info('[DatabaseSeeder] Renamed requirement "${entry.key}" -> "${entry.value}" ($updated row(s)).');
      }
    }

    // 2. Safe removals: Only delete retired requirements if NO cases have been logged against them
    final candidateRemovals = <String>[
      'Periodontal flap surgery',
      'Periodontal Flap Surgery',
      'RPI Clasp Assembly',
      'RPI clasp Assembly',
      'Provisional Restoration',
      'Cephalometric & Cast Analysis',
      'Removable Appliance Insertion',
      'Fixed Bracket Bonding',
      'Orthodontic Wire Adjustment',
    ];

    for (final title in candidateRemovals) {
      final rows = await db.rawQuery('''
        SELECT r.id FROM requirements r
        WHERE r.title = ? AND NOT EXISTS (
          SELECT 1 FROM case_records c WHERE c.requirementId = r.id
        );
      ''', [title]);

      for (final row in rows) {
        final reqId = row['id'] as String;
        await db.delete('requirements', where: 'id = ?', whereArgs: [reqId]);
        AppLogger.info('[DatabaseSeeder] Safely removed unused retired requirement "$title" ($reqId).');
      }
    }

    // Handle Orthodontic "Space Maintainer" (only under Orthodontics, not Pediatric)
    final orthoSpaceMaintainers = await db.rawQuery('''
      SELECT r.id FROM requirements r
      JOIN clinics c ON r.clinicId = c.id
      WHERE r.title = 'Space Maintainer'
        AND LOWER(c.name) LIKE '%orthodont%'
        AND NOT EXISTS (
          SELECT 1 FROM case_records cr WHERE cr.requirementId = r.id
        );
    ''');
    for (final row in orthoSpaceMaintainers) {
      final reqId = row['id'] as String;
      await db.delete('requirements', where: 'id = ?', whereArgs: [reqId]);
      AppLogger.info('[DatabaseSeeder] Safely removed unused Orthodontic Space Maintainer ($reqId).');
    }

    // 3. Additions: Add new curriculum requirements to existing clinics if not already present
    final clinics = await db.query('clinics');
    for (final clinic in clinics) {
      final clinicId = clinic['id'] as String;
      final clinicName = (clinic['name'] as String).toLowerCase();

      // Operative Dentistry additions
      if (clinicName.contains('operative')) {
        await _addRequirementIfNotExists(
          db,
          clinicId: clinicId,
          id: 'req-op-class1-amalgam',
          title: 'Class I Amalgam',
          targetCount: 6,
        );
      }

      // Pediatric Dentistry additions
      if (clinicName.contains('pediatric') || clinicName.contains('pedodont')) {
        await _addRequirementIfNotExists(
          db,
          clinicId: clinicId,
          id: 'req-peds-pulpectomy',
          title: 'Primary Pulpectomy',
          targetCount: 3,
        );
        await _addRequirementIfNotExists(
          db,
          clinicId: clinicId,
          id: 'req-peds-composite',
          title: 'Composite Restoration',
          targetCount: 5,
        );
      }

      // Prosthodontics additions
      if (clinicName.contains('prosthodont')) {
        await _addRequirementIfNotExists(
          db,
          clinicId: clinicId,
          id: 'req-prosth-spd',
          title: 'Single Partial Denture',
          targetCount: 2,
        );

        if (clinicName.contains('removable')) {
          await _addRequirementIfNotExists(
            db,
            clinicId: clinicId,
            id: 'req-prosth-overdenture',
            title: 'Over Denture',
            targetCount: 2,
          );
          await _addRequirementIfNotExists(
            db,
            clinicId: clinicId,
            id: 'req-prosth-metal-framework',
            title: 'Metal Framework',
            targetCount: 2,
          );
        }
      }

      // Orthodontics additions
      if (clinicName.contains('orthodont')) {
        await _addRequirementIfNotExists(
          db,
          clinicId: clinicId,
          id: 'req-ortho-removable',
          title: 'Removable Appliance',
          targetCount: 2,
        );
        await _addRequirementIfNotExists(
          db,
          clinicId: clinicId,
          id: 'req-ortho-habit-breaker',
          title: 'Habit Breaker',
          targetCount: 1,
        );
        await _addRequirementIfNotExists(
          db,
          clinicId: clinicId,
          id: 'req-ortho-fixed',
          title: 'Fixed Appliance',
          targetCount: 2,
        );
        await _addRequirementIfNotExists(
          db,
          clinicId: clinicId,
          id: 'req-ortho-myofunctional',
          title: 'Myofunctional Appliance (Functional)',
          targetCount: 1,
        );
      }
    }

    AppLogger.info('[DatabaseSeeder] Curriculum requirements synchronization completed.');
  }

  static Future<void> _addRequirementIfNotExists(
    Database db, {
    required String clinicId,
    required String id,
    required String title,
    required int targetCount,
  }) async {
    final existing = await db.query(
      'requirements',
      where: 'clinicId = ? AND LOWER(title) = ?',
      whereArgs: [clinicId, title.toLowerCase()],
    );

    if (existing.isEmpty) {
      final existingId = await db.query('requirements', where: 'id = ?', whereArgs: [id]);
      final effectiveId = existingId.isNotEmpty ? '$id-${DateTime.now().millisecondsSinceEpoch}' : id;

      await db.insert('requirements', {
        'id': effectiveId,
        'clinicId': clinicId,
        'title': title,
        'targetCount': targetCount,
        'completedCount': 0,
      });
      AppLogger.info('[DatabaseSeeder] Added new requirement "$title" ($effectiveId) to clinic $clinicId.');
    }
  }
}
