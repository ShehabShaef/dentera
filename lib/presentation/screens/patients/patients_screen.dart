import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../../widgets/widgets.dart';
import 'patient_case_sheet_screen.dart';
import 'widgets/widgets.dart';

/// Patient roster and management screen wired to Riverpod SQLite state.
///
/// Dynamically builds patient list and search/filter states strictly from
/// [filteredPatientListProvider], handling empty lists and zero results natively
/// without visual mock fallbacks.
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

  void _togglePatientSelection(String id) {
    final current = ref.read(selectedPatientIdsProvider);
    if (current.contains(id)) {
      ref.read(selectedPatientIdsProvider.notifier).state = current.difference({id});
    } else {
      ref.read(selectedPatientIdsProvider.notifier).state = {...current, id};
    }
  }

  Future<void> _confirmBatchDeletePatients(Set<String> selectedIds) async {
    if (selectedIds.isEmpty) return;

    final count = selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Selected Patients?'),
        content: Text(
          'Deleting $count patient${count > 1 ? 's' : ''} will permanently remove all associated clinical case records and scheduled appointments due to cascade deletion.\n\nThis action cannot be undone. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repository = ref.read(patientRepositoryProvider);
      await repository.deletePatients(selectedIds.toList());

      ref.read(patientSelectionModeProvider.notifier).state = false;
      ref.read(selectedPatientIdsProvider.notifier).state = <String>{};

      ref.invalidate(patientListProvider);
      ref.invalidate(allCasesProvider);
      ref.invalidate(upcomingAppointmentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully deleted $count patient${count > 1 ? 's' : ''}.',
            ),
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('Failed to delete patients in batch', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete patients: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPatientsAsync = ref.watch(filteredPatientListProvider);
    final searchQuery = ref.watch(patientSearchQueryProvider);
    final selectedFilter = ref.watch(patientFilterCategoryProvider);
    final isSelectionMode = ref.watch(patientSelectionModeProvider);
    final selectedIds = ref.watch(selectedPatientIdsProvider);

    final visiblePatients = filteredPatientsAsync.valueOrNull ?? <Patient>[];
    final visiblePatientIds = visiblePatients.map((p) => p.id).toSet();
    final isAllSelected = visiblePatientIds.isNotEmpty && selectedIds.containsAll(visiblePatientIds);

    final PreferredSizeWidget appBar = isSelectionMode
        ? AppBar(
            leadingWidth: 80,
            leading: TextButton(
              onPressed: () {
                ref.read(patientSelectionModeProvider.notifier).state = false;
                ref.read(selectedPatientIdsProvider.notifier).state = <String>{};
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              '${selectedIds.length} Selected',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (isAllSelected) {
                    ref.read(selectedPatientIdsProvider.notifier).state = <String>{};
                  } else {
                    ref.read(selectedPatientIdsProvider.notifier).state = {
                      ...selectedIds,
                      ...visiblePatientIds,
                    };
                  }
                },
                child: Text(
                  isAllSelected ? 'Deselect All' : 'Select All',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0, left: 4.0),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.onError,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () => _confirmBatchDeletePatients(selectedIds),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text('Delete (${selectedIds.length})'),
                ),
              ),
            ],
          )
        : AppBar(
            title: Text(
              'Patients',
              style: AppTextStyles.h1Mobile.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: <Widget>[
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'More options',
                onSelected: (value) {
                  if (value == 'sort') {
                    SortPatientsModal.show(context);
                  } else if (value == 'delete') {
                    ref.read(patientSelectionModeProvider.notifier).state = true;
                    ref.read(selectedPatientIdsProvider.notifier).state = <String>{};
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'sort',
                    child: Row(
                      children: [
                        Icon(Icons.sort_rounded, size: 20, color: AppColors.primary),
                        SizedBox(width: 12),
                        Text('Sort Patients'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Delete Patients'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // 1. Search Bar & Category Filter Strip
            Container(
              color: Colors.transparent,
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
                                      ? (isDark ? AppDarkColors.primaryTeal.withValues(alpha: 0.18) : AppColors.secondaryContainer.withValues(alpha: 0.35))
                                      : (isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest),
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark ? AppDarkColors.primaryTeal : AppColors.secondary)
                                        : (isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.5)),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  boxShadow: isDark ? AppDarkColors.cardShadow : AppColors.cardShadow,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  filter,
                                  style: AppTextStyles.caption.copyWith(
                                    color: isSelected
                                        ? (isDark ? AppDarkColors.primaryTeal : AppColors.secondary)
                                        : (isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant),
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
                    return _buildRosterList(patients, isSelectionMode, selectedIds);
                  }
                  if (searchQuery.isNotEmpty) {
                    AppLogger.debug(
                      'PatientsScreen rendered zero state: Search query returned 0 matches',
                    );
                  } else {
                    AppLogger.debug(
                      'PatientsScreen rendered zero state: Patient roster is empty',
                    );
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
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
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
              backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor ?? (isDark ? AppDarkColors.primaryTeal : AppColors.primary),
              foregroundColor: Theme.of(context).floatingActionButtonTheme.foregroundColor ?? (isDark ? AppDarkColors.onPrimary : AppColors.onPrimary),
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

  Widget _buildRosterList(
    List<Patient> patients,
    bool isSelectionMode,
    Set<String> selectedIds,
  ) {
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
            final isSelected = selectedIds.contains(patient.id);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: CircularCheckbox(
                      isSelected: isSelected,
                      onChanged: (_) => _togglePatientSelection(patient.id),
                    ),
                  ),
                Expanded(
                  child: PatientListCard(
                    patient: patient,
                    subtitle: patient.phoneNumber ?? 'No Phone',
                    tags: <String>[
                      if (patient.medicalHistory != null) 'Medical Alert',
                      'Active',
                    ],
                    onTap: () {
                      if (isSelectionMode) {
                        _togglePatientSelection(patient.id);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => PatientCaseSheetScreen(patient: patient),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds the standardized zero state display when the patient roster or search query returns empty.
  ///
  /// The Riverpod consumer for [filteredPatientListProvider] explicitly falls back to the
  /// [DenteraEmptyState] widget when the SQLite repository yields no records, either because
  /// no patients have been registered yet or because an active search or category filter
  /// matches zero records. When the roster is entirely empty, an action button is rendered
  /// to guide the student to register their first patient.
  Widget _buildZeroState(String query, String filter) {
    String subtitle;
    IconData icon;
    if (query.isNotEmpty) {
      subtitle = 'No patient records match "$query".';
      icon = Icons.search_off_rounded;
    } else if (filter != 'All') {
      subtitle = 'No patients found under "$filter".';
      icon = Icons.people_outline_rounded;
    } else {
      subtitle = 'Add your first patient to start tracking clinical requirements.';
      icon = Icons.people_outline_rounded;
    }

    final bool isRosterEmpty = query.isEmpty && filter == 'All';

    return DenteraEmptyState(
      icon: icon,
      title: 'No patients found',
      subtitle: subtitle,
      actionButton: isRosterEmpty
          ? PrimaryButton(
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
            )
          : null,
    );
  }
}
