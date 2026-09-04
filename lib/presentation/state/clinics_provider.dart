import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';

/// Provides the list of all clinics from SQLite storage.
///
/// **Error Propagation Architecture:**
/// Previously, a local `try/catch` swallowed database exceptions and returned `<Clinic>[]`.
/// Removing this block allows SQLite errors to propagate naturally to Riverpod's [FutureProvider],
/// which wraps the error in an [AsyncError] state. This allows [AppProviderObserver] to intercept
/// failures and enables UI consumers to present meaningful error states with retry actions.
final clinicListProvider = FutureProvider<List<Clinic>>((ref) async {
  final repository = ref.watch(clinicRepositoryProvider);
  return await repository.getAllClinics();
});

/// Tracks the active clinic category filter on the Clinics screen.
final selectedClinicCategoryProvider = StateProvider<String>((ref) => 'All');
