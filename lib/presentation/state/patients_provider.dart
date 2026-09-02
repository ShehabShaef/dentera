import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';

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

/// Provides the filtered list of patients based on search query and category filter.
final filteredPatientListProvider = Provider<AsyncValue<List<Patient>>>((ref) {
  final patientListAsync = ref.watch(patientListProvider);
  final query = ref.watch(patientSearchQueryProvider).trim().toLowerCase();

  return patientListAsync.whenData((patients) {
    if (query.isEmpty) {
      return patients;
    }
    return patients.where((patient) {
      final nameMatches = patient.name.toLowerCase().contains(query);
      final phoneMatches = patient.phoneNumber?.toLowerCase().contains(query) ?? false;
      final idMatches = patient.id.toLowerCase().contains(query);
      return nameMatches || phoneMatches || idMatches;
    }).toList();
  });
});
