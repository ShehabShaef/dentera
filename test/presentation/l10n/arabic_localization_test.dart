import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/l10n/l10n.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Arabic Localization and RTL Widget Tests', () {
    testWidgets('AppLocalizations renders in Arabic with TextDirection.rtl', (WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.lightThemeForLocale(const Locale('ar')),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              final l10n = context.l10n;
              return Scaffold(
                appBar: AppBar(title: Text(l10n.appTitle)),
                body: Column(
                  children: [
                    Text(l10n.dashboard),
                    Text(l10n.clinics),
                    Text(l10n.patients),
                    Text(l10n.appointments),
                    Text(l10n.profile),
                    Text(l10n.prosthodontics),
                    Text(l10n.endodontics),
                    Text(l10n.oralSurgery),
                    Text(l10n.phaseRestorative),
                    Text(l10n.statusCompleted),
                    Text(l10n.sort),
                    Text(l10n.sharePdfReport),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Directionality is RTL
      expect(Directionality.of(capturedContext), TextDirection.rtl);

      // Verify Arabic dental strings are rendered
      expect(find.text('دينتيرا'), findsOneWidget);
      expect(find.text('لوحة التحكم'), findsOneWidget);
      expect(find.text('العيادات'), findsOneWidget);
      expect(find.text('المرضى'), findsOneWidget);
      expect(find.text('المواعيد'), findsOneWidget);
      expect(find.text('الملف الشخصي'), findsOneWidget);
      expect(find.text('الاستعاضة الصناعية'), findsOneWidget);
      expect(find.text('علاج جذور الأسنان'), findsOneWidget);
      expect(find.text('جراحة الفم'), findsOneWidget);
      expect(find.text('المرحلة 3: الترميم والإصلاح'), findsOneWidget);
      expect(find.text('مكتمل'), findsOneWidget);
      expect(find.text('ترتيب'), findsOneWidget);
      expect(find.text('مشاركة تقرير PDF'), findsOneWidget);
    });

    testWidgets('Arabic typography applies Cairo font family', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.lightThemeForLocale(const Locale('ar')),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Text(
                  context.l10n.dashboard,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.fontFamily, contains('Cairo'));
    });

    testWidgets('ARB key parity and dental terminology completeness for Arabic', (WidgetTester tester) async {
      final arLoc = await AppLocalizations.delegate.load(const Locale('ar'));

      // Core Navigation & Screens
      expect(arLoc.appTitle, 'دينتيرا');
      expect(arLoc.dashboard, 'لوحة التحكم');
      expect(arLoc.clinics, 'العيادات');
      expect(arLoc.patients, 'المرضى');
      expect(arLoc.appointments, 'المواعيد');
      expect(arLoc.profile, 'الملف الشخصي');

      // Clinical Specialties
      expect(arLoc.prosthodontics, 'الاستعاضة الصناعية');
      expect(arLoc.endodontics, 'علاج جذور الأسنان');
      expect(arLoc.oralSurgery, 'جراحة الفم');
      expect(arLoc.periodontics, 'علاج اللثة');
      expect(arLoc.operativeDentistry, 'العلاج التحفظي');
      expect(arLoc.orthodontics, 'تقويم الأسنان');
      expect(arLoc.pedodontics, 'طب أسنان الأطفال');
      expect(arLoc.oralMedicine, 'طب الفم');

      // Modals & Actions
      expect(arLoc.addPatient, 'إضافة مريض');
      expect(arLoc.editPatient, 'تعديل بيانات المريض');
      expect(arLoc.addClinic, 'إضافة عيادة');
      expect(arLoc.editClinic, 'تعديل العيادة');
      expect(arLoc.addRequirement, 'إضافة متطلب');
      expect(arLoc.editRequirement, 'تعديل المتطلب');
      expect(arLoc.scheduleAppointment, 'حجز موعد');
      expect(arLoc.editAppointment, 'تعديل الموعد');
      expect(arLoc.logCaseRecord, 'تسجيل سجل حالة');
      expect(arLoc.evaluateCaseRecord, 'تقييم سجل الحالة');
      expect(arLoc.generateQuotaReport, 'إنشاء تقرير المتطلبات');
      expect(arLoc.resetAllClinicalData, 'إعادة ضبط جميع البيانات الإكلينيكية');
      expect(arLoc.dangerZone, 'منطقة الخطر');
      expect(arLoc.sort, 'ترتيب');

      // Parameterized strings
      expect(arLoc.patientLabel('أحمد'), 'المريض: أحمد');
      expect(arLoc.radiographAttachedSuccess('Bitewing'), 'تم إرفاق صورة الأشعة (Bitewing) بنجاح');
      expect(arLoc.treatmentItemStaged(2), 'تم إدراج عنصر خطة العلاج في المرحلة 2');
    });
  });
}
