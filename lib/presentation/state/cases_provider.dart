import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';

/// Provides case records logged for a specific patient.
final casesByPatientProvider =
    FutureProvider.family<List<CaseRecord>, String>((ref, patientId) async {
  try {
    final repository = ref.watch(caseRecordRepositoryProvider);
    return await repository.getCaseRecordsByPatientId(patientId);
  } catch (_) {
    return <CaseRecord>[];
  }
});

/// Provides all case records across all patients.
final allCasesProvider = FutureProvider<List<CaseRecord>>((ref) async {
  try {
    final repository = ref.watch(caseRecordRepositoryProvider);
    return await repository.getAllCaseRecords();
  } catch (_) {
    return <CaseRecord>[];
  }
});
