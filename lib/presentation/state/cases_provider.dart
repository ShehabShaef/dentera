import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';
import 'clinics_provider.dart';
import 'requirements_provider.dart';

/// Provides case records logged for a specific patient.
///
/// **Error Propagation Architecture:**
/// Allows SQLite repository exceptions to bubble up to Riverpod as [AsyncError].
final casesByPatientProvider =
    FutureProvider.family<List<CaseRecord>, String>((ref, patientId) async {
  final repository = ref.watch(caseRecordRepositoryProvider);
  return await repository.getCaseRecordsByPatientId(patientId);
});

/// Provides all case records across all patients.
///
/// **Error Propagation Architecture:**
/// Database exceptions propagate directly to Riverpod's [FutureProvider] wrapped in [AsyncError].
final allCasesProvider = FutureProvider<List<CaseRecord>>((ref) async {
  final repository = ref.watch(caseRecordRepositoryProvider);
  return await repository.getAllCaseRecords();
});

/// Provides case records logged for a specific clinical requirement.
///
/// **Error Propagation Architecture:**
/// Database exceptions propagate directly to Riverpod's [FutureProvider.family] wrapped in [AsyncError].
final casesByRequirementProvider =
    FutureProvider.family<List<CaseRecord>, String>((ref, requirementId) async {
  final repository = ref.watch(caseRecordRepositoryProvider);
  return await repository.getCaseRecordsByRequirementId(requirementId);
});

/// Joined data model representing a [CaseRecord] along with its resolved [Requirement] and [Clinic].
class CaseRecordWithRequirement {
  const CaseRecordWithRequirement({
    required this.caseRecord,
    this.requirement,
    this.clinic,
  });

  final CaseRecord caseRecord;
  final Requirement? requirement;
  final Clinic? clinic;

  String get procedureTitle => requirement?.title ?? 'Clinical Procedure';
  String get clinicName => clinic?.name ?? 'Dental Department';
  String get clinicColorHex => clinic?.colorHex ?? '#006A64';
}

/// Provides joined case records and their associated requirement/clinic metadata for a given patient.
final casesWithRequirementsByPatientProvider =
    FutureProvider.family<List<CaseRecordWithRequirement>, String>((ref, patientId) async {
  final cases = await ref.watch(casesByPatientProvider(patientId).future);
  final reqsAsync = await ref.watch(allRequirementsProvider.future);
  final clinicsAsync = await ref.watch(clinicListProvider.future);

  final reqMap = {for (final r in reqsAsync) r.id: r};
  final clinicMap = {for (final c in clinicsAsync) c.id: c};

  return cases.map((c) {
    final req = reqMap[c.requirementId];
    final clinic = req != null ? clinicMap[req.clinicId] : null;
    return CaseRecordWithRequirement(
      caseRecord: c,
      requirement: req,
      clinic: clinic,
    );
  }).toList();
});


