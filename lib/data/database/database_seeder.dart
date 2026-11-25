import 'package:sqflite/sqflite.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/entities.dart';

/// Structured payload of rich sample clinical records isolated strictly to Guest Mode.
class GuestDemoDataset {
  const GuestDemoDataset({
    required this.clinics,
    required this.requirements,
    required this.patients,
    required this.caseRecords,
    required this.appointments,
    required this.caseVisits,
    required this.treatmentPlans,
  });

  final List<Clinic> clinics;
  final List<Requirement> requirements;
  final List<Patient> patients;
  final List<CaseRecord> caseRecords;
  final List<Appointment> appointments;
  final List<CaseVisit> caseVisits;
  final List<TreatmentPlan> treatmentPlans;
}

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

  /// Ensures a real registered user (`isGuest == false`) starts with clean structural
  /// clinics and requirement quotas (`completedCount: 0`) and ZERO clinical records
  /// (0 patients, 0 case records, 0 appointments).
  ///
  /// - If the `clinics` table is empty (e.g., after a database reset), populates the
  ///   structural [defaultClinics] and [defaultRequirements] with `academicYear` applied.
  /// - Never inserts sample patients, cases, visits, treatment plans, or appointments.
  static Future<void> seedRealUserBaseline(
    Database db, {
    String? academicYear,
  }) async {
    AppLogger.info(
      '[DatabaseSeeder] Ensuring clean real-user baseline (zero sample clinical records)...',
    );
    try {
      await db.transaction((txn) async {
        final clinicCountResult = await txn.rawQuery('SELECT COUNT(*) AS cnt FROM clinics;');
        final clinicCount = (clinicCountResult.first['cnt'] as int?) ?? 0;

        final effectiveYear =
            (academicYear != null && academicYear.trim().isNotEmpty) ? academicYear.trim() : '5th Year';

        if (clinicCount == 0) {
          final batch = txn.batch();
          for (final clinic in defaultClinics) {
            batch.insert(
              'clinics',
              {
                ...clinic,
                'academicYear': effectiveYear,
              },
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
          AppLogger.info(
            '[DatabaseSeeder] Real-user baseline initialized: ${defaultClinics.length} clinics '
            'and ${defaultRequirements.length} requirements ($effectiveYear), 0 patients/cases/appointments.',
          );
        } else if (academicYear != null && academicYear.trim().isNotEmpty) {
          // Only update structural academicYear if no patient or case records have been created yet.
          final patientCnt = ((await txn.rawQuery('SELECT COUNT(*) AS cnt FROM patients;')).first['cnt'] as int?) ?? 0;
          final caseCnt = ((await txn.rawQuery('SELECT COUNT(*) AS cnt FROM case_records;')).first['cnt'] as int?) ?? 0;
          if (patientCnt == 0 && caseCnt == 0) {
            await txn.rawUpdate(
              'UPDATE clinics SET academicYear = ?;',
              <Object>[effectiveYear],
            );
          }
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        '[DatabaseSeeder] Failed while ensuring real-user baseline: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Generates a deterministic, rich showcase dataset tailored strictly for Guest Mode
  /// and watermarked Demo Report exports.
  ///
  /// Includes:
  /// - 6 academic dental clinics and 16 requirements with synced `completedCount` values
  /// - 6 realistic dental patients with complete medical/dental anamnesis
  /// - 12 case records spanning `Evaluated`, `Completed`, `In Progress`, and Overdue/Delayed (>= 14 days)
  /// - 7 appointments covering past/completed, today earlier & imminent, tomorrow, and upcoming
  /// - Multi-visit timelines and phased treatment plans
  static GuestDemoDataset buildGuestDemoDataset({DateTime? referenceNow}) {
    final now = referenceNow ?? DateTime.now();
    final todayBase = DateTime(now.year, now.month, now.day);

    // Clamp imminent appointment inside the current calendar day while keeping it upcoming.
    final DateTime todayImminent = now.hour < 22
        ? now.add(const Duration(minutes: 45))
        : DateTime(now.year, now.month, now.day, 23, 55);
    final DateTime todayEarlier = now.hour >= 10
        ? DateTime(now.year, now.month, now.day, 8, 30)
        : todayBase.add(const Duration(hours: 1));

    final clinics = defaultClinics.map((m) => Clinic.fromMap(m)).toList();

    final patients = <Patient>[
      Patient(
        id: 'demo-pat-1',
        name: 'Layla Al-Harbi',
        age: 28,
        gender: 'Female',
        phoneNumber: '+967 771 234 567',
        medicalHistory: 'Mild seasonal allergic rhinitis; no drug allergies.',
        chiefComplaint: 'Throbbing pain in lower right molar worsening with hot liquids',
        historyOfChiefComplaint: 'Onset 5 days ago; nocturnal lingering pain requiring analgesics.',
        dentalHistory: 'Occlusal amalgam restoration placed on #46 four years ago.',
        medications: 'Loratadine 10mg PRN',
        diagnosticAids: 'Periapical radiograph #46 showing deep distal caries & widening PDL',
        createdAt: now.subtract(const Duration(days: 22)),
      ),
      Patient(
        id: 'demo-pat-2',
        name: 'Omar Bin Saeed',
        age: 62,
        gender: 'Male',
        phoneNumber: '+967 773 891 024',
        medicalHistory: 'Controlled Type 2 Diabetes (HbA1c 6.8%), mild hypertension',
        chiefComplaint: 'Difficulty chewing after multiple posterior extractions; requests dentures',
        historyOfChiefComplaint: 'Fully healed edentulous maxillary arch & Kennedy Class II mandible.',
        dentalHistory: 'Atraumatic serial extractions completed 4 months prior without complications.',
        medications: 'Metformin 500mg BID, Amlodipine 5mg OD',
        diagnosticAids: 'Diagnostic study casts & panoramic radiograph',
        createdAt: now.subtract(const Duration(days: 31)),
      ),
      Patient(
        id: 'demo-pat-3',
        name: 'Nadia Al-Mansoor',
        age: 34,
        gender: 'Female',
        phoneNumber: '+967 770 442 819',
        medicalHistory: 'ASA I — No significant systemic disease',
        chiefComplaint: 'Food impaction and cold sensitivity in upper left premolar',
        historyOfChiefComplaint: 'Intermittent thermal sensitivity for 3 weeks.',
        dentalHistory: 'Routine prophylaxis performed last year.',
        medications: 'None',
        diagnosticAids: 'Bitewing radiograph revealing MO dentin caries on #24 & occlusal #26',
        createdAt: now.subtract(const Duration(days: 23)),
      ),
      Patient(
        id: 'demo-pat-4',
        name: 'Tariq Al-Qasimi',
        age: 45,
        gender: 'Male',
        phoneNumber: '+967 775 619 330',
        medicalHistory: 'Penicillin allergy (urticaria documented)',
        chiefComplaint: 'Gingival bleeding on brushing and heavy lower anterior calculus',
        historyOfChiefComplaint: 'Progressive bleeding over 6 months without spontaneous pain.',
        dentalHistory: 'No professional scaling in the last 4 years.',
        medications: 'None',
        diagnosticAids: 'Periodontal charting & full-mouth periapical survey',
        createdAt: now.subtract(const Duration(days: 16)),
      ),
      Patient(
        id: 'demo-pat-5',
        name: 'Youssef Kareem',
        age: 8,
        gender: 'Male',
        phoneNumber: '+967 772 908 112',
        medicalHistory: 'ASA I — Healthy pediatric patient, mild dental anxiety',
        chiefComplaint: 'Pain while chewing sweets on lower left primary molar #75',
        historyOfChiefComplaint: 'Spontaneous discomfort absent; provoked pain subsides in seconds.',
        dentalHistory: 'Cooperative with tell-show-do technique during prior exam.',
        medications: 'None',
        diagnosticAids: 'Periapical radiograph #75 showing carious pulp exposure & intact furcation',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      Patient(
        id: 'demo-pat-6',
        name: 'Salma Al-Dossary',
        age: 23,
        gender: 'Female',
        phoneNumber: '+967 774 510 982',
        medicalHistory: 'Mild iron deficiency anemia; stable vitals',
        chiefComplaint: 'Recurrent pericoronitis and non-restorable lower left #38',
        historyOfChiefComplaint: 'Two episodes of mild trismus resolved after saline irrigation.',
        dentalHistory: 'Completed Class I composite on #16 successfully last month.',
        medications: 'Ferrous sulfate 325mg OD',
        diagnosticAids: 'OPG showing vertical bone height and favorable root morphology',
        createdAt: now.subtract(const Duration(days: 26)),
      ),
    ];

    final cases = <CaseRecord>[
      CaseRecord(
        id: 'demo-case-1',
        patientId: 'demo-pat-1',
        requirementId: 'req-endo-molar',
        status: 'Evaluated',
        notes: 'Tooth #46 3-canal RCT obturated with AH Plus & gutta-percha. Faculty graded A.',
        dateStarted: now.subtract(const Duration(days: 20)),
        dateCompleted: now.subtract(const Duration(days: 6)),
      ),
      // Overdue / Delayed (> 14 days In Progress without completion)
      CaseRecord(
        id: 'demo-case-2',
        patientId: 'demo-pat-2',
        requirementId: 'req-prosth-cd',
        status: 'In Progress',
        notes: 'Final borders molded; pending jaw relation & facebow transfer (overdue >14 days).',
        dateStarted: now.subtract(const Duration(days: 18)),
        dateCompleted: null,
      ),
      CaseRecord(
        id: 'demo-case-3',
        patientId: 'demo-pat-2',
        requirementId: 'req-prosth-rpd',
        status: 'Completed',
        notes: 'Kennedy Class II mandibular RPD inserted with balanced centric occlusion.',
        dateStarted: now.subtract(const Duration(days: 30)),
        dateCompleted: now.subtract(const Duration(days: 12)),
      ),
      CaseRecord(
        id: 'demo-case-4',
        patientId: 'demo-pat-3',
        requirementId: 'req-op-class1',
        status: 'Completed',
        notes: 'Tooth #26 Class I nanohybrid composite (shade A2) bonded and polished.',
        dateStarted: now.subtract(const Duration(days: 15)),
        dateCompleted: now.subtract(const Duration(days: 10)),
      ),
      // Overdue / Delayed (> 14 days In Progress without completion)
      CaseRecord(
        id: 'demo-case-5',
        patientId: 'demo-pat-3',
        requirementId: 'req-op-class2',
        status: 'In Progress',
        notes: 'Tooth #24 MO preparation temporized with IRM; pending final amalgam restoration.',
        dateStarted: now.subtract(const Duration(days: 21)),
        dateCompleted: null,
      ),
      CaseRecord(
        id: 'demo-case-6',
        patientId: 'demo-pat-4',
        requirementId: 'req-perio-srp',
        status: 'Evaluated',
        notes: 'Full-mouth ultrasonic scaling & polishing completed; plaque score dropped 65% -> 18%.',
        dateStarted: now.subtract(const Duration(days: 14)),
        dateCompleted: now.subtract(const Duration(days: 7)),
      ),
      CaseRecord(
        id: 'demo-case-7',
        patientId: 'demo-pat-4',
        requirementId: 'req-perio-srp',
        status: 'In Progress',
        notes: '6-week periodontal re-evaluation & lower anterior calculus touch-up ongoing.',
        dateStarted: now.subtract(const Duration(days: 2)),
        dateCompleted: null,
      ),
      CaseRecord(
        id: 'demo-case-8',
        patientId: 'demo-pat-5',
        requirementId: 'req-peds-pulpotomy',
        status: 'Completed',
        notes: 'Tooth #75 vital pulpotomy completed with reinforced ZOE base & cotton isolation.',
        dateStarted: now.subtract(const Duration(days: 11)),
        dateCompleted: now.subtract(const Duration(days: 5)),
      ),
      CaseRecord(
        id: 'demo-case-9',
        patientId: 'demo-pat-5',
        requirementId: 'req-peds-ssc',
        status: 'In Progress',
        notes: 'Pre-crimped stainless steel crown size #4 selected; awaiting cementation visit.',
        dateStarted: now.subtract(const Duration(days: 3)),
        dateCompleted: null,
      ),
      CaseRecord(
        id: 'demo-case-10',
        patientId: 'demo-pat-6',
        requirementId: 'req-surg-simple',
        status: 'Completed',
        notes: 'Atraumatic simple extraction of #38 under 2% lidocaine w/ 1:100k epinephrine.',
        dateStarted: now.subtract(const Duration(days: 9)),
        dateCompleted: now.subtract(const Duration(days: 8)),
      ),
      CaseRecord(
        id: 'demo-case-11',
        patientId: 'demo-pat-6',
        requirementId: 'req-op-class1',
        status: 'Completed',
        notes: 'Tooth #16 preventive Class I resin composite restoration completed.',
        dateStarted: now.subtract(const Duration(days: 25)),
        dateCompleted: now.subtract(const Duration(days: 20)),
      ),
      CaseRecord(
        id: 'demo-case-12',
        patientId: 'demo-pat-1',
        requirementId: 'req-endo-anterior',
        status: 'In Progress',
        notes: 'Tooth #11 working length 21.5mm; biomechanical preparation & Ca(OH)2 dressing.',
        dateStarted: now.subtract(const Duration(days: 4)),
        dateCompleted: null,
      ),
    ];

    // Synchronize completedCount per requirement accurately from Completed/Evaluated cases.
    final completionCounts = <String, int>{};
    for (final c in cases) {
      final s = c.status.trim().toLowerCase();
      if (s == 'completed' || s == 'evaluated') {
        completionCounts[c.requirementId] = (completionCounts[c.requirementId] ?? 0) + 1;
      }
    }

    final requirements = defaultRequirements.map((m) {
      final base = Requirement.fromMap(m);
      return base.copyWith(completedCount: completionCounts[base.id] ?? 0);
    }).toList();

    final appointments = <Appointment>[
      // Past / Completed appointments
      Appointment(
        id: 'demo-apt-1',
        patientId: 'demo-pat-3',
        clinicId: 'clinic-operative',
        scheduledDate: DateTime(now.year, now.month, now.day - 5, 10, 0),
        status: 'Completed',
        procedureDescription: 'Class I composite restoration & occlusal check on #26',
        patientName: 'Nadia Al-Mansoor',
      ),
      Appointment(
        id: 'demo-apt-2',
        patientId: 'demo-pat-1',
        clinicId: 'clinic-endo',
        scheduledDate: DateTime(now.year, now.month, now.day - 2, 11, 30),
        status: 'Completed',
        procedureDescription: 'Final warm vertical obturation & radiograph on #46',
        patientName: 'Layla Al-Harbi',
      ),
      // Today (Earlier Completed + Imminent Scheduled)
      Appointment(
        id: 'demo-apt-3',
        patientId: 'demo-pat-4',
        clinicId: 'clinic-perio',
        scheduledDate: todayEarlier,
        status: 'Completed',
        procedureDescription: 'Ultrasonic scaling & periodontal re-evaluation (Q1-Q2)',
        patientName: 'Tariq Al-Qasimi',
      ),
      Appointment(
        id: 'demo-apt-4',
        patientId: 'demo-pat-1',
        clinicId: 'clinic-endo',
        scheduledDate: todayImminent,
        status: 'Scheduled',
        procedureDescription: 'Anterior #11 master cone fit & lateral compaction obturation',
        patientName: 'Layla Al-Harbi',
      ),
      // Tomorrow appointments
      Appointment(
        id: 'demo-apt-5',
        patientId: 'demo-pat-2',
        clinicId: 'clinic-prosth',
        scheduledDate: DateTime(now.year, now.month, now.day + 1, 10, 30),
        status: 'Scheduled',
        procedureDescription: 'Maxillary & mandibular jaw relation record with occlusion rims',
        patientName: 'Omar Bin Saeed',
      ),
      Appointment(
        id: 'demo-apt-6',
        patientId: 'demo-pat-5',
        clinicId: 'clinic-pediatric',
        scheduledDate: DateTime(now.year, now.month, now.day + 1, 14, 0),
        status: 'Confirmed',
        procedureDescription: 'Stainless steel crown #75 try-in & GIC cementation',
        patientName: 'Youssef Kareem',
      ),
      // Future upcoming appointment
      Appointment(
        id: 'demo-apt-7',
        patientId: 'demo-pat-3',
        clinicId: 'clinic-operative',
        scheduledDate: DateTime(now.year, now.month, now.day + 4, 9, 30),
        status: 'Scheduled',
        procedureDescription: 'Tooth #24 Class II amalgam placement & burnishing',
        patientName: 'Nadia Al-Mansoor',
      ),
    ];

    final caseVisits = <CaseVisit>[
      CaseVisit(
        id: 'demo-visit-1',
        caseRecordId: 'demo-case-2',
        visitNumber: 1,
        title: 'Primary Alginate Impressions & Study Cast',
        status: 'Completed',
        notes: 'Diagnostic casts poured cleanly.',
        dateCompleted: now.subtract(const Duration(days: 17)),
      ),
      CaseVisit(
        id: 'demo-visit-2',
        caseRecordId: 'demo-case-2',
        visitNumber: 2,
        title: 'Border Molding & ZOE Secondary Impression',
        status: 'Completed',
        notes: 'Good posterior palatal seal captured.',
        dateCompleted: now.subtract(const Duration(days: 14)),
      ),
      CaseVisit(
        id: 'demo-visit-3',
        caseRecordId: 'demo-case-2',
        visitNumber: 3,
        title: 'Jaw Relation Record & Tooth Selection',
        status: 'Pending',
        dateScheduled: DateTime(now.year, now.month, now.day + 1, 10, 30),
      ),
      CaseVisit(
        id: 'demo-visit-4',
        caseRecordId: 'demo-case-12',
        visitNumber: 1,
        title: 'Access Opening & Working Length Determination',
        status: 'Completed',
        notes: 'WL = 21.5mm verified by apex locator & PA X-ray.',
        dateCompleted: now.subtract(const Duration(days: 3)),
      ),
      CaseVisit(
        id: 'demo-visit-5',
        caseRecordId: 'demo-case-12',
        visitNumber: 2,
        title: 'Master Cone Fit & Final Obturation',
        status: 'Pending',
        dateScheduled: todayImminent,
      ),
    ];

    final treatmentPlans = <TreatmentPlan>[
      TreatmentPlan(
        id: 'demo-tp-1',
        patientId: 'demo-pat-1',
        phase: 1,
        title: 'Pulpectomy & Pain Control (#46, #11)',
        status: 'In Progress',
        targetClinicId: 'clinic-endo',
        notes: '#46 completed; #11 obturation scheduled today.',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      TreatmentPlan(
        id: 'demo-tp-2',
        patientId: 'demo-pat-1',
        phase: 2,
        title: 'Post-Endodontic Coronal Core & Seal',
        status: 'Proposed',
        targetClinicId: 'clinic-operative',
        createdAt: now.subtract(const Duration(days: 19)),
      ),
      TreatmentPlan(
        id: 'demo-tp-3',
        patientId: 'demo-pat-2',
        phase: 3,
        title: 'Maxillary Complete Denture & Mandibular RPD Rehabilitation',
        status: 'In Progress',
        targetClinicId: 'clinic-prosth',
        notes: 'Lower RPD delivered; upper CD at jaw relation stage.',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ];

    return GuestDemoDataset(
      clinics: clinics,
      requirements: requirements,
      patients: patients,
      caseRecords: cases,
      appointments: appointments,
      caseVisits: caseVisits,
      treatmentPlans: treatmentPlans,
    );
  }

  /// Populates the local SQLite database with the rich [GuestDemoDataset] for showcase exploration.
  ///
  /// Intended strictly for Guest Mode (`isGuest == true`). Inserts clinics, requirements
  /// with synchronized `completedCount`s, demo patients, demo cases (`Evaluated`, `Completed`,
  /// `In Progress`, and Overdue/Delayed >= 14 days), and appointments spanning past, today,
  /// tomorrow, and future dates inside an atomic SQLite transaction.
  static Future<void> seedGuestDemoData(
    Database db, {
    DateTime? referenceNow,
  }) async {
    AppLogger.info('[DatabaseSeeder] Seeding rich Guest Mode demo dataset...');
    try {
      final dataset = buildGuestDemoDataset(referenceNow: referenceNow);

      await db.transaction((txn) async {
        // Inspect existing schema dynamically so optional tables/columns degrade gracefully.
        final tablesRows = await txn.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table';",
        );
        final tableNames = tablesRows.map((r) => r['name'] as String).toSet();

        final patientColsRows = await txn.rawQuery('PRAGMA table_info(patients);');
        final patientCols = patientColsRows.map((r) => r['name'] as String).toSet();

        final batch = txn.batch();

        for (final clinic in dataset.clinics) {
          batch.insert(
            'clinics',
            clinic.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (final req in dataset.requirements) {
          batch.insert(
            'requirements',
            req.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (final patient in dataset.patients) {
          final map = patient.toMap();
          if (patientCols.isNotEmpty) {
            map.removeWhere((key, _) => !patientCols.contains(key));
          }
          batch.insert(
            'patients',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (final c in dataset.caseRecords) {
          batch.insert(
            'case_records',
            c.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        if (tableNames.contains('appointments')) {
          for (final apt in dataset.appointments) {
            batch.insert(
              'appointments',
              apt.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        if (tableNames.contains('case_visits')) {
          for (final visit in dataset.caseVisits) {
            batch.insert(
              'case_visits',
              visit.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        if (tableNames.contains('treatment_plans')) {
          for (final plan in dataset.treatmentPlans) {
            batch.insert(
              'treatment_plans',
              plan.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        await batch.commit(noResult: true);
      });

      AppLogger.info(
        '[DatabaseSeeder] Guest demo dataset seeded successfully: '
        '${dataset.clinics.length} clinics, ${dataset.requirements.length} requirements, '
        '${dataset.patients.length} patients, ${dataset.caseRecords.length} cases, '
        '${dataset.appointments.length} appointments.',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '[DatabaseSeeder] Failed to seed Guest Mode demo dataset: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
