import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';

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
