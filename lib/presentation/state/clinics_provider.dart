import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';

/// Provides the list of all clinics from SQLite storage.
final clinicListProvider = FutureProvider<List<Clinic>>((ref) async {
  try {
    final repository = ref.watch(clinicRepositoryProvider);
    return await repository.getAllClinics();
  } catch (_) {
    return <Clinic>[];
  }
});

/// Tracks the active clinic category filter on the Clinics screen.
final selectedClinicCategoryProvider = StateProvider<String>((ref) => 'All');
