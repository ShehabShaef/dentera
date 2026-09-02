import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import 'clinic_details_screen.dart';
import 'widgets/widgets.dart';

/// Clinics & Requirements tracking screen for departmental quotas wired to Riverpod SQLite state.
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

  static const List<Map<String, dynamic>> _mockClinicsData = [
    {
      'clinic': Clinic(
        id: 'clinic-prosth',
        name: 'Prosthodontics',
        academicYear: '5th Year',
        colorHex: '#003E6F',
      ),
      'requirements': <Requirement>[
        Requirement(
          id: 'req-cd',
          clinicId: 'clinic-prosth',
          title: 'Complete Denture',
          targetCount: 2,
          completedCount: 1,
        ),
        Requirement(
          id: 'req-rpd',
          clinicId: 'clinic-prosth',
          title: 'Metal Denture',
          targetCount: 3,
          completedCount: 2,
        ),
      ],
    },
    {
      'clinic': Clinic(
        id: 'clinic-operative',
        name: 'Operative Dentistry',
        academicYear: '5th Year',
        colorHex: '#006A64',
      ),
      'requirements': <Requirement>[
        Requirement(
          id: 'req-comp',
          clinicId: 'clinic-operative',
          title: 'Class I Composite',
          targetCount: 8,
          completedCount: 4,
        ),
        Requirement(
          id: 'req-amalgam',
          clinicId: 'clinic-operative',
          title: 'Class II Amalgam',
          targetCount: 4,
          completedCount: 1,
        ),
      ],
    },
    {
      'clinic': Clinic(
        id: 'clinic-endo',
        name: 'Endodontics',
        academicYear: '5th Year',
        colorHex: '#1E568C',
      ),
      'requirements': <Requirement>[
        Requirement(
          id: 'req-anterior-rct',
          clinicId: 'clinic-endo',
          title: 'Anterior RCT',
          targetCount: 6,
          completedCount: 4,
        ),
        Requirement(
          id: 'req-molar-rct',
          clinicId: 'clinic-endo',
          title: 'Premolar / Molar RCT',
          targetCount: 4,
          completedCount: 2,
        ),
      ],
    },
    {
      'clinic': Clinic(
        id: 'clinic-surgery',
        name: 'Oral Surgery',
        academicYear: '5th Year',
        colorHex: '#2E3F50',
      ),
      'requirements': <Requirement>[
        Requirement(
          id: 'req-simple-ext',
          clinicId: 'clinic-surgery',
          title: 'Simple Extraction',
          targetCount: 20,
          completedCount: 14,
        ),
        Requirement(
          id: 'req-surg-ext',
          clinicId: 'clinic-surgery',
          title: 'Surgical Extraction',
          targetCount: 4,
          completedCount: 1,
        ),
      ],
    },
    {
      'clinic': Clinic(
        id: 'clinic-perio',
        name: 'Periodontics',
        academicYear: '5th Year',
        colorHex: '#37485A',
      ),
      'requirements': <Requirement>[
        Requirement(
          id: 'req-srp',
          clinicId: 'clinic-perio',
          title: 'Scaling & Root Planing',
          targetCount: 10,
          completedCount: 8,
        ),
        Requirement(
          id: 'req-gingivectomy',
          clinicId: 'clinic-perio',
          title: 'Gingivectomy',
          targetCount: 2,
          completedCount: 1,
        ),
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final clinicsAsync = ref.watch(clinicListProvider);
    final allReqsAsync = ref.watch(allRequirementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Clinics & Requirements',
          style: AppTextStyles.h1Mobile.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Phase 5.5 - Navigate to Profile & Settings
            },
          ),
        ],
      ),
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

                  // 2. Clinics Grid/List from State or Mock
                  clinicsAsync.when(
                    data: (clinics) {
                      final List<Map<String, dynamic>> dataset = clinics.isNotEmpty
                          ? clinics.map((c) {
                              final reqs = allReqsAsync.maybeWhen(
                                data: (list) => list.where((r) => r.clinicId == c.id).toList(),
                                orElse: () => const <Requirement>[],
                              );
                              return <String, dynamic>{
                                'clinic': c,
                                'requirements': reqs,
                              };
                            }).toList()
                          : _mockClinicsData;

                      final filteredData = _selectedCategory == 'All'
                          ? dataset
                          : dataset.where((entry) {
                              final Clinic clinic = entry['clinic'] as Clinic;
                              return clinic.name
                                  .toLowerCase()
                                  .contains(_selectedCategory.toLowerCase());
                            }).toList();

                      return _buildClinicsGridOrList(filteredData);
                    },
                    loading: _buildFilteredMockClinics,
                    error: (_, _) => _buildFilteredMockClinics(),
                  ),
                  const SizedBox(height: 80), // Padding for Floating Action Button
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_clinics',
        onPressed: () {
          // TODO: Phase 6 - Add Custom Requirement/Clinic
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

  Widget _buildFilteredMockClinics() {
    final filtered = _selectedCategory == 'All'
        ? _mockClinicsData
        : _mockClinicsData.where((entry) {
            final Clinic clinic = entry['clinic'] as Clinic;
            return clinic.name.toLowerCase().contains(_selectedCategory.toLowerCase());
          }).toList();
    return _buildClinicsGridOrList(filtered);
  }

  Widget _buildClinicsGridOrList(List<Map<String, dynamic>> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        if (isMobile) {
          return Column(
            children: data.map((entry) {
              final Clinic clinic = entry['clinic'] as Clinic;
              final List<Requirement> reqs = entry['requirements'] as List<Requirement>;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ClinicSummaryCard(
                  clinic: clinic,
                  requirements: reqs,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => ClinicDetailsScreen(clinic: clinic),
                      ),
                    );
                  },
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

            return ClinicSummaryCard(
              clinic: clinic,
              requirements: reqs,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ClinicDetailsScreen(clinic: clinic),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
