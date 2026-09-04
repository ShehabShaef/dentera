import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../../widgets/widgets.dart';
import 'patient_case_sheet_screen.dart';
import 'widgets/widgets.dart';

/// Patient roster and management screen wired to Riverpod SQLite state.
class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _filters = <String>[
    'All',
    'Active Cases',
    'Completed',
    'Prosthodontics',
    'Endodontics',
    'Oral Surgery',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPatientsAsync = ref.watch(filteredPatientListProvider);
    final searchQuery = ref.watch(patientSearchQueryProvider);
    final selectedFilter = ref.watch(patientFilterCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Patients',
          style: AppTextStyles.h1Mobile.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Patients',
            onPressed: () => SortPatientsModal.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // 1. Search Bar & Category Filter Strip
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    children: <Widget>[
                      // Search Input Field
                      DenteraSearchBar(
                        hintText: 'Search by name or phone...',
                        controller: _searchController,
                        onChanged: (query) {
                          ref.read(patientSearchQueryProvider.notifier).state = query;
                        },
                        onClear: () {
                          _searchController.clear();
                          ref.read(patientSearchQueryProvider.notifier).state = '';
                        },
                      ),
                      const SizedBox(height: 12),

                      // Status & Department Filter Pills
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final filter = _filters[index];
                            final isSelected = filter == selectedFilter;

                            return InkWell(
                              onTap: () {
                                ref.read(patientFilterCategoryProvider.notifier).state = filter;
                              },
                              borderRadius: BorderRadius.circular(9999),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.secondaryContainer.withValues(alpha: 0.35)
                                      : AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.secondary
                                        : AppColors.outlineVariant.withValues(alpha: 0.5),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  boxShadow: AppColors.cardShadow,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  filter,
                                  style: AppTextStyles.caption.copyWith(
                                    color: isSelected ? AppColors.secondary : AppColors.onSurfaceVariant,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Patient Roster List or Zero State
            Expanded(
              child: filteredPatientsAsync.when(
                data: (patients) {
                  if (patients.isNotEmpty) {
                    return _buildRosterList(patients);
                  }
                  return _buildZeroState(searchQuery, selectedFilter);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
                error: (error, stackTrace) {
                  AppLogger.error(
                    '[PatientsScreen] Failed to load patients: $error',
                    error,
                    stackTrace,
                  );
                  return DenteraErrorState(
                    title: 'Failed to load patients',
                    message: error.toString(),
                    onRetry: () {
                      ref.invalidate(patientListProvider);
                      ref.invalidate(allCasesProvider);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_patients',
        onPressed: () {
          AddPatientModal.show(
            context,
            onPatientAdded: (_) {
              ref.invalidate(patientListProvider);
              ref.invalidate(allCasesProvider);
            },
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.person_add_rounded,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildRosterList(List<Patient> patients) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 88.0),
          physics: const BouncingScrollPhysics(),
          itemCount: patients.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final patient = patients[index];
            return PatientListCard(
              patient: patient,
              subtitle: patient.phoneNumber ?? 'No Phone',
              tags: <String>[
                if (patient.medicalHistory != null) 'Medical Alert',
                'Active',
              ],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => PatientCaseSheetScreen(patient: patient),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildZeroState(String query, String filter) {
    String subtitle;
    if (query.isNotEmpty) {
      subtitle = 'No patient records match "$query".';
    } else if (filter != 'All') {
      subtitle = 'No patients found under "$filter".';
    } else {
      subtitle = 'Add your first patient to start tracking clinical requirements.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 36,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No patients found',
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (query.isEmpty && filter == 'All')
              PrimaryButton(
                isFullWidth: false,
                text: 'Add First Patient',
                icon: const Icon(
                  Icons.add_rounded,
                  color: AppColors.onPrimary,
                  size: 18,
                ),
                onPressed: () {
                  AddPatientModal.show(
                    context,
                    onPatientAdded: (_) {
                      ref.invalidate(patientListProvider);
                      ref.invalidate(allCasesProvider);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
