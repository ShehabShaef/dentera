import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';
import 'cases_provider.dart';
import 'clinics_provider.dart';
import 'requirements_provider.dart';

/// Provides the full list of patients directly from the SQLite database.
///
/// **Error Propagation Architecture:**
/// Previously, a local `try/catch` block caught database exceptions and silently returned
/// an empty list (`<Patient>[]`). Swallowing errors locally masked underlying SQLite failures
/// (such as lock contention or disk I/O errors) as valid empty rosters, preventing the UI
/// from alerting clinical users and bypassing error-recovery mechanisms.
///
/// Exceptions thrown by [PatientRepository.getAllPatients] are now allowed to propagate
/// unhindered. Riverpod's [FutureProvider] automatically captures any thrown exception and
/// transitions into an [AsyncError] state. This enables:
/// 1. [AppProviderObserver] to intercept the error and record detailed stack traces.
/// 2. UI screens to gracefully present dedicated error state widgets with user retry options.
final patientListProvider = FutureProvider<List<Patient>>((ref) async {
  final repository = ref.watch(patientRepositoryProvider);
  return await repository.getAllPatients();
});

/// Tracks the active search query text for filtering patients.
final patientSearchQueryProvider = StateProvider<String>((ref) => '');

/// Tracks the active category/status filter for the patients list.
final patientFilterCategoryProvider = StateProvider<String>((ref) => 'All');

/// Sorting criteria for the clinical patient roster.
enum PatientSortOption {
  name,
  dateAdded,
  activeCaseCount,
}

/// Tracks the active sorting preference for the patient roster.
final patientSortOptionProvider =
    StateProvider<PatientSortOption>((ref) => PatientSortOption.dateAdded);

/// Provides the filtered list of patients based on search query, category, relational clinic cases, and sorting order.
///
/// Filters the master patient roster across multiple clinical criteria:
/// - `'All'`: Returns all patients matching the search query.
/// - `'Active Cases'`: Returns patients possessing at least one in-progress [CaseRecord].
/// - `'Completed'`: Returns patients possessing at least one completed [CaseRecord].
/// - Clinic Department (e.g. `'Prosthodontics'`, `'Endodontics'`): Returns patients with active
///   or logged cases belonging to requirements in the selected clinic department.
///
/// Then sorts according to [patientSortOptionProvider]:
/// - [PatientSortOption.name]: Alphabetical order A to Z.
/// - [PatientSortOption.dateAdded]: Most recently registered first (`createdAt DESC`).
/// - [PatientSortOption.activeCaseCount]: Highest volume of active in-progress cases first.
final filteredPatientListProvider = Provider<AsyncValue<List<Patient>>>((ref) {
  final patientListAsync = ref.watch(patientListProvider);
  final query = ref.watch(patientSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(patientFilterCategoryProvider).trim();
  final sortOption = ref.watch(patientSortOptionProvider);

  // If patient list is still loading or has an error, propagate state directly.
  if (patientListAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (patientListAsync.hasError) {
    return AsyncValue.error(patientListAsync.error!, patientListAsync.stackTrace!);
  }

  final allPatients = patientListAsync.value ?? <Patient>[];

  // 1. Apply search query filter (name, phone, patient ID).
  List<Patient> queriedPatients = allPatients;
  if (query.isNotEmpty) {
    queriedPatients = queriedPatients.where((patient) {
      final nameMatches = patient.name.toLowerCase().contains(query);
      final phoneMatches = patient.phoneNumber?.toLowerCase().contains(query) ?? false;
      final idMatches = patient.id.toLowerCase().contains(query);
      return nameMatches || phoneMatches || idMatches;
    }).toList();
  }

  // 2. Inspect case records only if relational category filtering or activeCaseCount sorting is requested.
  final needsCaseRecords = (category != 'All' && category.isNotEmpty) ||
      sortOption == PatientSortOption.activeCaseCount;

  List<CaseRecord> allCases = const <CaseRecord>[];
  if (needsCaseRecords) {
    final allCasesAsync = ref.watch(allCasesProvider);
    if (allCasesAsync.isLoading) {
      return const AsyncValue.loading();
    }
    if (allCasesAsync.hasError) {
      return AsyncValue.error(allCasesAsync.error!, allCasesAsync.stackTrace!);
    }
    allCases = allCasesAsync.value ?? <CaseRecord>[];
  }

  List<Patient> categoryFiltered = queriedPatients;

  // 3. For relational category filters, inspect logged case records.
  if (category != 'All' && category.isNotEmpty) {
    if (category.toLowerCase() == 'active cases') {
      final activePatientIds = allCases
          .where((c) => c.status.toLowerCase() != 'completed')
          .map((c) => c.patientId)
          .toSet();
      categoryFiltered = categoryFiltered.where((p) => activePatientIds.contains(p.id)).toList();
    } else if (category.toLowerCase() == 'completed') {
      final completedPatientIds = allCases
          .where((c) => c.status.toLowerCase() == 'completed')
          .map((c) => c.patientId)
          .toSet();
      categoryFiltered = categoryFiltered.where((p) => completedPatientIds.contains(p.id)).toList();
    } else {
      // Specific clinical department filter (e.g. 'Prosthodontics', 'Endodontics', 'Oral Surgery')
      final clinicsAsync = ref.watch(clinicListProvider);
      final requirementsAsync = ref.watch(allRequirementsProvider);

      if (clinicsAsync.isLoading || requirementsAsync.isLoading) {
        return const AsyncValue.loading();
      }
      if (clinicsAsync.hasError) {
        return AsyncValue.error(clinicsAsync.error!, clinicsAsync.stackTrace!);
      }
      if (requirementsAsync.hasError) {
        return AsyncValue.error(requirementsAsync.error!, requirementsAsync.stackTrace!);
      }

      final clinics = clinicsAsync.value ?? <Clinic>[];
      final requirements = requirementsAsync.value ?? <Requirement>[];

      // Find clinics matching the selected category name or alias
      final matchingClinics = clinics.where((c) {
        final cName = c.name.toLowerCase();
        final cat = category.toLowerCase();
        return cName == cat || cName.contains(cat) || cat.contains(cName);
      }).toList();

      final matchingClinicIds = matchingClinics.map((c) => c.id).toSet();

      // Fallback heuristic for standard seeded clinic slugs if custom lookup differs
      final normalizedCat = category.toLowerCase();
      if (normalizedCat.contains('prosth')) matchingClinicIds.add('clinic-prosth');
      if (normalizedCat.contains('operat')) matchingClinicIds.add('clinic-operative');
      if (normalizedCat.contains('endo')) matchingClinicIds.add('clinic-endo');
      if (normalizedCat.contains('surg')) matchingClinicIds.add('clinic-surgery');
      if (normalizedCat.contains('perio')) matchingClinicIds.add('clinic-perio');
      if (normalizedCat.contains('ped') || normalizedCat.contains('peds')) {
        matchingClinicIds.add('clinic-pediatric');
      }

      final matchingRequirementIds = requirements
          .where((r) => matchingClinicIds.contains(r.clinicId))
          .map((r) => r.id)
          .toSet();

      final clinicPatientIds = allCases.where((c) {
        if (matchingRequirementIds.contains(c.requirementId)) return true;
        final reqId = c.requirementId.toLowerCase();
        for (final cid in matchingClinicIds) {
          final slug = cid.replaceFirst('clinic-', '');
          if (reqId.contains(slug)) return true;
        }
        return false;
      }).map((c) => c.patientId).toSet();

      categoryFiltered = categoryFiltered.where((p) => clinicPatientIds.contains(p.id)).toList();
    }
  }

  // 4. Apply sorting according to active patientSortOptionProvider
  final sortedPatients = List<Patient>.from(categoryFiltered);
  switch (sortOption) {
    case PatientSortOption.name:
      sortedPatients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case PatientSortOption.dateAdded:
      sortedPatients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case PatientSortOption.activeCaseCount:
      final activeCounts = <String, int>{};
      for (final c in allCases) {
        if (c.status.toLowerCase() != 'completed') {
          activeCounts[c.patientId] = (activeCounts[c.patientId] ?? 0) + 1;
        }
      }
      sortedPatients.sort((a, b) {
        final countA = activeCounts[a.id] ?? 0;
        final countB = activeCounts[b.id] ?? 0;
        final cmp = countB.compareTo(countA);
        return cmp != 0 ? cmp : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      break;
  }

  AppLogger.debug(
    '[filteredPatientListProvider] Category: "$category", Query: "$query", Sort: "$sortOption" -> ${sortedPatients.length} matching patients',
  );

  return AsyncValue.data(sortedPatients);
});

/// Provides a single [Patient] by their unique ID directly from the SQLite database repository.
///
/// Thrown database exceptions automatically propagate into an [AsyncError] state,
/// allowing calling widgets to trigger error recovery UI or handle missing records gracefully.
final patientByIdProvider = FutureProvider.family<Patient?, String>((ref, patientId) async {
  final repository = ref.watch(patientRepositoryProvider);
  return await repository.getPatientById(patientId);
});
