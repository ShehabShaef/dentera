import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../../widgets/widgets.dart';
import 'clinic_details_screen.dart';
import 'widgets/widgets.dart';

/// Clinics & Requirements tracking screen for departmental quotas wired to Riverpod SQLite state.
///
/// Dynamically builds clinical department lists and procedural quota progress strictly from
/// [clinicListProvider] and [allRequirementsProvider], handling empty states natively without
/// visual mock fallbacks.
///
/// ### Modal Invocation & Quota Administration:
/// Tapping the floating action button triggers [AddClinicModal.show], enabling students
/// to register custom departments with specialized academic year quotas and theme colors.
/// All additions persist to the local SQLite database and automatically refresh [clinicListProvider].
class ClinicsScreen extends ConsumerStatefulWidget {
  const ClinicsScreen({super.key});

  @override
  ConsumerState<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends ConsumerState<ClinicsScreen> {
  String _selectedCategory = 'All';

  static const List<String> _categories = <String>[
    'All',
    'Prosthodontics',
    'Operative',
    'Endodontics',
    'Oral Surgery',
    'Periodontics',
    'Orthodontics',
  ];

  void _toggleClinicSelection(String id) {
    final current = ref.read(selectedClinicIdsProvider);
    if (current.contains(id)) {
      ref.read(selectedClinicIdsProvider.notifier).state = current.difference({id});
    } else {
      ref.read(selectedClinicIdsProvider.notifier).state = {...current, id};
    }
  }

  Future<void> _confirmBatchDeleteClinics(Set<String> selectedIds) async {
    if (selectedIds.isEmpty) return;

    final count = selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Selected Clinics?'),
        content: Text(
          'Deleting $count clinic${count > 1 ? 's' : ''} will permanently remove all associated requirements, clinical case records, and scheduled appointments due to cascade deletion.\n\nThis action cannot be undone. Are you sure you want to proceed?',
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
      final repository = ref.read(clinicRepositoryProvider);
      await repository.deleteClinics(selectedIds.toList());

      ref.read(clinicSelectionModeProvider.notifier).state = false;
      ref.read(selectedClinicIdsProvider.notifier).state = <String>{};

      ref.invalidate(clinicListProvider);
      ref.invalidate(allRequirementsProvider);
      ref.invalidate(allCasesProvider);
      ref.invalidate(upcomingAppointmentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully deleted $count clinic${count > 1 ? 's' : ''}.',
            ),
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('Failed to delete clinics in batch', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete clinics: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicsAsync = ref.watch(clinicListProvider);
    final allReqsAsync = ref.watch(allRequirementsProvider);
    final isSelectionMode = ref.watch(clinicSelectionModeProvider);
    final selectedIds = ref.watch(selectedClinicIdsProvider);
    final sortOption = ref.watch(clinicSortOptionProvider);

    final clinicsList = clinicsAsync.valueOrNull ?? <Clinic>[];
    final visibleClinics = clinicsList.where((c) {
      if (_selectedCategory == 'All') return true;
      return c.name.toLowerCase().contains(_selectedCategory.toLowerCase());
    }).toList();
    final visibleClinicIds = visibleClinics.map((c) => c.id).toSet();
    final isAllSelected = visibleClinicIds.isNotEmpty && selectedIds.containsAll(visibleClinicIds);

    final PreferredSizeWidget appBar = isSelectionMode
        ? AppBar(
            leadingWidth: 80,
            leading: TextButton(
              onPressed: () {
                ref.read(clinicSelectionModeProvider.notifier).state = false;
                ref.read(selectedClinicIdsProvider.notifier).state = <String>{};
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
                    ref.read(selectedClinicIdsProvider.notifier).state = <String>{};
                  } else {
                    ref.read(selectedClinicIdsProvider.notifier).state = {
                      ...selectedIds,
                      ...visibleClinicIds,
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
                      : () => _confirmBatchDeleteClinics(selectedIds),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text('Delete (${selectedIds.length})'),
                ),
              ),
            ],
          )
        : AppBar(
            title: Text(
              'Clinics & Requirements',
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
                    SortClinicsModal.show(context);
                  } else if (value == 'delete') {
                    ref.read(clinicSelectionModeProvider.notifier).state = true;
                    ref.read(selectedClinicIdsProvider.notifier).state = <String>{};
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'sort',
                    child: Row(
                      children: [
                        Icon(Icons.sort_rounded, size: 20, color: AppColors.primary),
                        SizedBox(width: 12),
                        Text('Sort Clinics'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Delete Clinics'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. Horizontal Category Filter Bar
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.secondaryContainer
                                  : AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.secondaryContainer
                                    : AppColors.outlineVariant.withValues(alpha: 0.5),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: Text(
                              category,
                              style: AppTextStyles.caption.copyWith(
                                color: isSelected
                                    ? AppColors.onSecondaryContainer
                                    : AppColors.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Clinics Grid/List from Riverpod SQLite State
                  clinicsAsync.when(
                    data: (clinics) {
                      if (clinics.isEmpty) {
                        AppLogger.debug('ClinicsScreen rendered zero state: SQLite returned 0 records for academic year');
                        return _buildZeroState();
                      }

                      final List<Map<String, dynamic>> dataset = clinics.map((c) {
                        final reqs = allReqsAsync.maybeWhen(
                          data: (list) => list.where((r) => r.clinicId == c.id).toList(),
                          orElse: () => const <Requirement>[],
                        );
                        return <String, dynamic>{
                          'clinic': c,
                          'requirements': reqs,
                        };
                      }).toList();

                      final filteredData = _selectedCategory == 'All'
                          ? dataset
                          : dataset.where((entry) {
                              final Clinic clinic = entry['clinic'] as Clinic;
                              return clinic.name
                                  .toLowerCase()
                                  .contains(_selectedCategory.toLowerCase());
                            }).toList();

                      // Apply sorting based on active sort option
                      switch (sortOption) {
                        case ClinicSortOption.name:
                          filteredData.sort((a, b) {
                            final Clinic ca = a['clinic'] as Clinic;
                            final Clinic cb = b['clinic'] as Clinic;
                            return ca.name.toLowerCase().compareTo(cb.name.toLowerCase());
                          });
                          break;
                        case ClinicSortOption.academicYear:
                          filteredData.sort((a, b) {
                            final Clinic ca = a['clinic'] as Clinic;
                            final Clinic cb = b['clinic'] as Clinic;
                            final cmp = ca.academicYear.compareTo(cb.academicYear);
                            return cmp != 0 ? cmp : ca.name.toLowerCase().compareTo(cb.name.toLowerCase());
                          });
                          break;
                        case ClinicSortOption.quotaProgress:
                          filteredData.sort((a, b) {
                            final List<Requirement> reqsA = a['requirements'] as List<Requirement>;
                            final List<Requirement> reqsB = b['requirements'] as List<Requirement>;
                            final targetA = reqsA.fold(0, (sum, r) => sum + r.targetCount);
                            final compA = reqsA.fold(0, (sum, r) => sum + r.completedCount);
                            final pctA = targetA == 0 ? 0.0 : compA / targetA;

                            final targetB = reqsB.fold(0, (sum, r) => sum + r.targetCount);
                            final compB = reqsB.fold(0, (sum, r) => sum + r.completedCount);
                            final pctB = targetB == 0 ? 0.0 : compB / targetB;

                            final cmp = pctB.compareTo(pctA);
                            if (cmp != 0) return cmp;
                            final Clinic ca = a['clinic'] as Clinic;
                            final Clinic cb = b['clinic'] as Clinic;
                            return ca.name.toLowerCase().compareTo(cb.name.toLowerCase());
                          });
                          break;
                      }

                      if (filteredData.isEmpty) {
                        return _buildEmptyFilterState();
                      }

                      return _buildClinicsGridOrList(filteredData, isSelectionMode, selectedIds);
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                    error: (error, stackTrace) => DenteraErrorWidget(
                      error: error,
                      stackTrace: stackTrace,
                      title: 'Failed to load clinics',
                      message: 'Could not retrieve departmental clinics from local database.',
                      onRetry: () => ref.invalidate(clinicListProvider),
                    ),
                  ),
                  const SizedBox(height: 80), // Padding for Floating Action Button
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
              heroTag: 'fab_clinics',
              onPressed: () {
                AppLogger.info('Opened AddClinicModal from ClinicsScreen');
                AddClinicModal.show(context);
              },
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.add_chart_rounded,
                size: 26,
              ),
            ),
    );
  }

  /// Builds the standardized zero state display when the SQLite repository returns no clinics.
  ///
  /// The Riverpod consumer for [clinicListProvider] explicitly falls back to the
  /// [DenteraEmptyState] widget when the SQLite database query returns an empty list
  /// for the selected academic year. This guides the student to register their clinical
  /// departments and track their requirements.
  Widget _buildZeroState() {
    return DenteraEmptyState(
      icon: Icons.account_balance_outlined,
      title: 'No clinics added yet',
      subtitle: 'Register your clinical departments to track quotas and case progress.',
      actionButton: PrimaryButton(
        isFullWidth: false,
        text: 'Add Dental Clinic',
        icon: const Icon(
          Icons.add_chart_rounded,
          color: AppColors.onPrimary,
          size: 18,
        ),
        onPressed: () {
          AppLogger.info('Opened AddClinicModal from zero state in ClinicsScreen');
          AddClinicModal.show(context);
        },
      ),
    );
  }

  /// Builds the standardized zero state display when a category filter yields zero clinics.
  Widget _buildEmptyFilterState() {
    return DenteraEmptyState(
      icon: Icons.search_off_rounded,
      title: 'No clinics found in "$_selectedCategory"',
      subtitle: 'Try selecting "All" or a different clinical category.',
    );
  }

  Widget _buildClinicsGridOrList(
    List<Map<String, dynamic>> data,
    bool isSelectionMode,
    Set<String> selectedIds,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        if (isMobile) {
          return Column(
            children: data.map((entry) {
              final Clinic clinic = entry['clinic'] as Clinic;
              final List<Requirement> reqs = entry['requirements'] as List<Requirement>;
              final isSelected = selectedIds.contains(clinic.id);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: CircularCheckbox(
                          isSelected: isSelected,
                          onChanged: (_) => _toggleClinicSelection(clinic.id),
                        ),
                      ),
                    Expanded(
                      child: ClinicSummaryCard(
                        clinic: clinic,
                        requirements: reqs,
                        onTap: () {
                          if (isSelectionMode) {
                            _toggleClinicSelection(clinic.id);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => ClinicDetailsScreen(clinic: clinic),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 280,
          ),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final entry = data[index];
            final Clinic clinic = entry['clinic'] as Clinic;
            final List<Requirement> reqs = entry['requirements'] as List<Requirement>;
            final isSelected = selectedIds.contains(clinic.id);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CircularCheckbox(
                      isSelected: isSelected,
                      onChanged: (_) => _toggleClinicSelection(clinic.id),
                    ),
                  ),
                Expanded(
                  child: ClinicSummaryCard(
                    clinic: clinic,
                    requirements: reqs,
                    onTap: () {
                      if (isSelectionMode) {
                        _toggleClinicSelection(clinic.id);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => ClinicDetailsScreen(clinic: clinic),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
