import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/services/report_generator_service.dart';
import 'package:dentera/domain/entities/entities.dart';

void main() {
  group('ReportGeneratorService Unit Tests', () {
    const service = ReportGeneratorService();

    final testClinics = <Clinic>[
      Clinic(
        id: 'clinic-endo',
        name: 'Endodontics',
        academicYear: '5th Year',
        colorHex: '#1E568C',
      ),
      Clinic(
        id: 'clinic-surgery',
        name: 'Oral Surgery',
        academicYear: '5th Year',
        colorHex: '#8C1D18',
      ),
    ];

    final testRequirements = <Requirement>[
      Requirement(
        id: 'req-endo-molar',
        clinicId: 'clinic-endo',
        title: 'Molar Root Canal Treatment',
        targetCount: 5,
        completedCount: 3,
      ),
      Requirement(
        id: 'req-surg-ext',
        clinicId: 'clinic-surgery',
        title: 'Simple Extraction',
        targetCount: 10,
        completedCount: 8,
      ),
    ];

    final testPatients = <Patient>[
      Patient(
        id: 'pat-1',
        name: 'Jane Doe',
        phoneNumber: '1234567890',
        gender: 'Female',
        age: 28,
        createdAt: DateTime(2026, 1, 1),
      ),
      Patient(
        id: 'pat-2',
        name: 'John Smith, Jr.',
        phoneNumber: '0987654321',
        gender: 'Male',
        age: 45,
        createdAt: DateTime(2026, 2, 1),
      ),
    ];

    final testCases = <CaseRecord>[
      CaseRecord(
        id: 'case-001',
        patientId: 'pat-1',
        requirementId: 'req-endo-molar',
        status: 'Evaluated',
        dateStarted: DateTime(2026, 3, 1, 10, 0),
        dateCompleted: DateTime(2026, 3, 1, 11, 30),
      ),
      CaseRecord(
        id: 'case-002',
        patientId: 'pat-2',
        requirementId: 'req-surg-ext',
        status: 'Evaluated',
        dateStarted: DateTime(2026, 4, 15, 9, 0),
        dateCompleted: DateTime(2026, 4, 15, 9, 45),
      ),
      CaseRecord(
        id: 'case-003',
        patientId: 'pat-1',
        requirementId: 'req-endo-molar',
        status: 'In Progress',
        dateStarted: DateTime(2026, 5, 20, 14, 0),
        dateCompleted: null,
      ),
    ];

    test('QuotaReportData filters correctly by clinicId and date range', () {
      // 1. Without filters
      final allData = QuotaReportData(
        doctorName: 'Dr. Shehab Shaif',
        university: 'Dental School',
        academicYear: '5th Year',
        generatedDate: DateTime(2026, 9, 1),
        clinics: testClinics,
        requirements: testRequirements,
        cases: testCases,
        patients: testPatients,
      );

      expect(allData.visibleClinics.length, equals(2));
      expect(allData.visibleRequirements.length, equals(2));
      expect(allData.visibleCases.length, equals(3));
      expect(allData.dateRangeLabel, equals('All Time'));

      // 2. Filtered by Endodontics clinic
      final endoData = QuotaReportData(
        doctorName: 'Dr. Shehab Shaif',
        university: 'Dental School',
        academicYear: '5th Year',
        generatedDate: DateTime(2026, 9, 1),
        clinics: testClinics,
        requirements: testRequirements,
        cases: testCases,
        patients: testPatients,
        filterClinicId: 'clinic-endo',
      );

      expect(endoData.visibleClinics.length, equals(1));
      expect(endoData.visibleClinics.first.id, equals('clinic-endo'));
      expect(endoData.visibleRequirements.length, equals(1));
      expect(endoData.visibleRequirements.first.id, equals('req-endo-molar'));
      expect(endoData.visibleCases.length, equals(2));

      // 3. Filtered by date range (March 2026 only)
      final marchData = QuotaReportData(
        doctorName: 'Dr. Shehab Shaif',
        university: 'Dental School',
        academicYear: '5th Year',
        generatedDate: DateTime(2026, 9, 1),
        clinics: testClinics,
        requirements: testRequirements,
        cases: testCases,
        patients: testPatients,
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
      );

      expect(marchData.visibleCases.length, equals(1));
      expect(marchData.visibleCases.first.id, equals('case-001'));
      expect(marchData.dateRangeLabel, equals('2026-03-01 to 2026-03-31'));
    });

    test('generatePdfReport produces valid PDF binary with standard magic bytes', () async {
      final data = QuotaReportData(
        doctorName: 'Dr. Shehab Shaif',
        university: 'University of Sanaa Dental Faculty',
        academicYear: '5th Year',
        generatedDate: DateTime(2026, 9, 1),
        clinics: testClinics,
        requirements: testRequirements,
        cases: testCases,
        patients: testPatients,
      );

      final pdfBytes = await service.generatePdfReport(data);

      expect(pdfBytes, isNotEmpty);
      // PDF standard magic header %PDF- (hex: 0x25, 0x50, 0x44, 0x46, 0x2D)
      expect(pdfBytes.sublist(0, 5), equals(<int>[0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('generatePdfReport handles zero requirements and empty cases gracefully', () async {
      final emptyData = QuotaReportData(
        doctorName: 'Dr. Test Clinician',
        university: 'Dental Institute',
        academicYear: '4th Year',
        generatedDate: DateTime(2026, 9, 1),
        clinics: const <Clinic>[],
        requirements: const <Requirement>[],
        cases: const <CaseRecord>[],
        patients: const <Patient>[],
      );

      final pdfBytes = await service.generatePdfReport(emptyData);

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.sublist(0, 5), equals(<int>[0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('generateCsvReport generates formatted spreadsheet with proper headers and escaping', () {
      final data = QuotaReportData(
        doctorName: 'Dr. Shehab "Pro" Shaif',
        university: 'Faculty of Dentistry, Sana\'a',
        academicYear: '5th Year',
        generatedDate: DateTime(2026, 9, 1),
        clinics: testClinics,
        requirements: testRequirements,
        cases: testCases,
        patients: testPatients,
      );

      final csv = service.generateCsvReport(data);

      // Verify metadata header
      expect(csv, contains('"DENTERA CLINICAL SUPERVISORY REPORT"'));
      expect(csv, contains('"Clinician Name","Dr. Shehab ""Pro"" Shaif"'));
      expect(csv, contains('"Institution","Faculty of Dentistry, Sana\'a"'));
      expect(csv, contains('"Academic Year","5th Year"'));
      expect(csv, contains('"Date Range","All Time"'));

      // Verify Department quotas table
      expect(csv, contains('"DEPARTMENT QUOTAS"'));
      expect(csv, contains('"Department","Target Quota","Completed Cases","Remaining","Progress %"'));
      expect(csv, contains('"Endodontics",5,3,2,60%'));
      expect(csv, contains('"Oral Surgery",10,8,2,80%'));

      // Verify Evaluated cases table
      expect(csv, contains('"EVALUATED CASES & PROCEDURAL LOGS"'));
      expect(csv, contains('"Case ID","Patient ID","Patient Name","Department","Requirement","Status","Date Started","Date Completed"'));
      expect(csv, contains('"case-001","pat-1","Jane Doe","Endodontics","Molar Root Canal Treatment","Evaluated"'));
      expect(csv, contains('"case-002","pat-2","John Smith, Jr.","Oral Surgery","Simple Extraction","Evaluated"'));
    });

    test('reportGeneratorServiceProvider resolves successfully', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final providerService = container.read(reportGeneratorServiceProvider);
      expect(providerService, isA<ReportGeneratorService>());
    });
  });
}
