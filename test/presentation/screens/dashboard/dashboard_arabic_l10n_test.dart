import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/l10n/l10n.dart';
import 'package:dentera/presentation/screens/dashboard/widgets/dashboard_appointment_card.dart';
import 'package:dentera/presentation/screens/dashboard/widgets/dashboard_header.dart';
import 'package:dentera/presentation/screens/patients/widgets/case_record_card.dart';
import 'package:dentera/presentation/state/state.dart';

Widget _buildArabicApp({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Dashboard Arabic Localization Unit & Widget Tests (Issue #54)', () {
    testWidgets('DashboardAppointmentCard renders localized Arabic badges, status, and button', (tester) async {
      await tester.pumpWidget(
        _buildArabicApp(
          child: const DashboardAppointmentCard(
            patientName: 'أحمد علي',
            patientId: 'PT-99',
            patientDetails: 'scheduled',
            timeWindow: '10:30',
            procedureTitle: 'إجراء سريري',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Arabic ID badge and localized status
      expect(find.text('المعرف: PT-99 • مجدول'), findsOneWidget);

      // Check Arabic procedure tag
      expect(find.text('إجراء سريري'), findsOneWidget);

      // Check Arabic time window
      expect(find.text('10:30'), findsOneWidget);

      // Check Arabic patient name
      expect(find.text('أحمد علي'), findsOneWidget);

      // Check localized "View Case" button
      expect(find.text('عرض الحالة'), findsOneWidget);
    });

    testWidgets('DashboardHeader renders localized Dr. prefix and localized academic year in Arabic', (tester) async {
      await tester.pumpWidget(
        _buildArabicApp(
          child: const DashboardHeader(
            doctorName: 'شهاب شائف',
            academicYear: '5th Year',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Arabic doctor greeting with "د."
      expect(find.textContaining('د. شهاب شائف'), findsOneWidget);

      // Check localized subtitle with "عيادات السنة الخامسة"
      expect(find.textContaining('عيادات السنة الخامسة'), findsOneWidget);
      expect(find.textContaining('اليوم'), findsOneWidget);
    });

    test('ClinicalReminderItem produces localized Arabic reminder messages via getMessage', () {
      final l10nAr = lookupAppLocalizations(const Locale('ar'));

      // 1. Overdue case reminder
      final overdueItem = ClinicalReminderItem(
        id: 'test-overdue',
        message: 'Molar RCT: overdue (16 days in progress)',
        icon: Icons.warning,
        type: ReminderType.alert,
        category: ReminderCategory.overdueCase,
        localizedMessage: (l10n) => l10n.overdueCaseReminder('علاج عصب (أحمد علي)', 16),
      );
      expect(overdueItem.getMessage(l10nAr), equals('علاج عصب (أحمد علي): متأخرة (16 يوم قيد التنفيذ)'));

      // 2. Imminent appointment reminder
      final imminentItem = ClinicalReminderItem(
        id: 'test-imminent',
        message: 'Appointment starting in 30m (Ahmed)',
        icon: Icons.alarm,
        type: ReminderType.warning,
        category: ReminderCategory.imminentAppointment,
        localizedMessage: (l10n) => l10n.appointmentImminentReminder(l10n.startingInMinutes(30), 'أحمد علي'),
      );
      expect(imminentItem.getMessage(l10nAr), equals('موعد يبدأ خلال 30 دقيقة (أحمد علي)'));

      // 3. Quota lagging reminder
      final quotaItem = ClinicalReminderItem(
        id: 'test-quota',
        message: 'Pedodontics quota lagging (15% / Target: 20)',
        icon: Icons.pie_chart,
        type: ReminderType.warning,
        category: ReminderCategory.laggingQuota,
        localizedMessage: (l10n) => l10n.quotaLaggingReminder('طب الأطفال', 15, 20),
      );
      expect(quotaItem.getMessage(l10nAr), equals('تأخر نصاب طب الأطفال (15٪ / المستهدف: 20)'));

      // 4. Daily schedule summary reminder
      final todaySummaryItem = ClinicalReminderItem(
        id: 'test-today-summary',
        message: '3 appointment(s) scheduled today',
        icon: Icons.schedule,
        localizedMessage: (l10n) => l10n.todayAppointmentsReminder(3),
      );
      expect(todaySummaryItem.getMessage(l10nAr), equals('3 موعد مجدول اليوم'));

      // 5. Upcoming schedule summary reminder
      final upcomingSummaryItem = ClinicalReminderItem(
        id: 'test-upcoming-summary',
        message: '5 upcoming appointment(s) scheduled',
        icon: Icons.event,
        localizedMessage: (l10n) => l10n.upcomingAppointmentsReminder(5),
      );
      expect(upcomingSummaryItem.getMessage(l10nAr), equals('5 موعد قادم مجدول'));
    });

    test('AppLocalizationsFormattingX helper extension localizes statuses and academic years', () {
      final l10nAr = lookupAppLocalizations(const Locale('ar'));
      final l10nEn = lookupAppLocalizations(const Locale('en'));

      // Arabic statuses
      expect(l10nAr.localizeStatus('scheduled'), equals('مجدول'));
      expect(l10nAr.localizeStatus('confirmed'), equals('مؤكد'));
      expect(l10nAr.localizeStatus('in progress'), equals('قيد التنفيذ'));
      expect(l10nAr.localizeStatus('in_progress'), equals('قيد التنفيذ'));
      expect(l10nAr.localizeStatus('completed'), equals('مكتمل'));
      expect(l10nAr.localizeStatus('cancelled'), equals('ملغى'));
      expect(l10nAr.localizeStatus('evaluated'), equals(l10nAr.statusEvaluated));
      expect(l10nAr.localizeStatus('pending'), equals('قيد الانتظار'));

      // English statuses
      expect(l10nEn.localizeStatus('scheduled'), equals('Scheduled'));
      expect(l10nEn.localizeStatus('completed'), equals('Completed'));
      expect(l10nEn.localizeStatus('in_progress'), equals('In Progress'));

      // Arabic academic years
      expect(l10nAr.localizeAcademicYear('1st Year'), equals('السنة الأولى'));
      expect(l10nAr.localizeAcademicYear('2nd Year'), equals('السنة الثانية'));
      expect(l10nAr.localizeAcademicYear('3rd Year'), equals('السنة الثالثة'));
      expect(l10nAr.localizeAcademicYear('4th Year'), equals('السنة الرابعة'));
      expect(l10nAr.localizeAcademicYear('5th Year'), equals('السنة الخامسة'));
      expect(l10nAr.localizeAcademicYear('Intern'), equals('سنة الامتياز'));

      // English academic years preserved
      expect(l10nEn.localizeAcademicYear('5th Year'), equals('5th Year'));
    });

    testWidgets('CaseRecordCard renders localized Arabic visit progress', (tester) async {
      final caseRecord = CaseRecord(
        id: 'case-test-1',
        patientId: 'patient-test-1',
        requirementId: 'req-test-1',
        status: 'In Progress',
        dateStarted: DateTime(2026, 4, 1),
      );

      final visits = [
        const CaseVisit(id: 'v1', caseRecordId: 'case-test-1', visitNumber: 1, title: 'Visit 1', status: 'Completed'),
        const CaseVisit(id: 'v2', caseRecordId: 'case-test-1', visitNumber: 2, title: 'Visit 2', status: 'Scheduled'),
        const CaseVisit(id: 'v3', caseRecordId: 'case-test-1', visitNumber: 3, title: 'Visit 3', status: 'Scheduled'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caseVisitsByCaseRecordProvider('case-test-1').overrideWith((ref) => Future.value(visits)),
          ],
          child: _buildArabicApp(
            child: CaseRecordCard(
              caseRecord: caseRecord,
              requirementTitle: 'علاج جذور',
              clinicName: 'العلاج التحفظي',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check localized visit progress: "الزيارة 1 من 3"
      expect(find.text('الزيارة 1 من 3'), findsOneWidget);
    });
  });
}
