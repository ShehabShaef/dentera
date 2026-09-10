import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/dental_catalog_repository.dart';

/// Provider for the academic dental catalog repository.
final dentalCatalogRepositoryProvider = Provider<DentalCatalogRepository>((ref) {
  return const DefaultDentalCatalogRepository();
});
