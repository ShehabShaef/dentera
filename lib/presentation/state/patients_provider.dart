import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';
import 'cases_provider.dart';
import 'clinics_provider.dart';
import 'requirements_provider.dart';

/// Provides the full list of patients directly from the SQLite database.
final patientListProvider = FutureProvider<List<Patient>>((ref) async {
  try {
    final repository = ref.watch(patientRepositoryProvider);
    return await repository.getAllPatients();
  } catch (_) {
    return <Patient>[];
  }
});

/// Tracks the active search query text for filtering patients.
final patientSearchQueryProvider = StateProvider<String>((ref) => '');

/// Tracks the active category/status filter for the patients list.
final patientFilterCategoryProvider = StateProvider<String>((ref) => 'All');

/// Provides the filtered list of patients based on search query, category, and relational clinic cases.
///
/// Filters the master patient roster across multiple clinical criteria:
/// - `'All'`: Returns all patients matching the search query.
/// - `'Active Cases'`: Returns patients possessing at least one in-progress [CaseRecord].
/// - `'Completed'`: Returns patients possessing at least one completed [CaseRecord].
/// - Clinic Department (e.g. `'Prosthodontics'`, `'Endodontics'`): Returns patients with active
///   or logged cases belonging to requirements in the selected clinic department.
final filteredPatientListProvider = Provider<AsyncValue<List<Patient>>>((ref) {
  final patientListAsync = ref.watch(patientListProvider);
  final query = ref.watch(patientSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(patientFilterCategoryProvider).trim();

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

  // 2. If 'All', no relational case filtering is necessary.
  if (category == 'All' || category.isEmpty) {
    AppLogger.debug(
      '[filteredPatientListProvider] Category: "$category", Query: "$query" -> ${queriedPatients.length} matching patients',
    );
    return AsyncValue.data(queriedPatients);
  }

  // 3. For relational category filters, inspect logged case records.
  final allCasesAsync = ref.watch(allCasesProvider);
  if (allCasesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (allCasesAsync.hasError) {
    return AsyncValue.error(allCasesAsync.error!, allCasesAsync.stackTrace!);
  }

  final allCases = allCasesAsync.value ?? <CaseRecord>[];

  List<Patient> categoryFiltered = queriedPatients;

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
    if (normalizedCat.contains('ped') || normalizedCat.contains('peds')) matchingClinicIds.add('clinic-pediatric');

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

  AppLogger.debug(
    '[filteredPatientListProvider] Category: "$category", Query: "$query" -> ${categoryFiltered.length} matching patients',
  );

  return AsyncValue.data(categoryFiltered);
});
