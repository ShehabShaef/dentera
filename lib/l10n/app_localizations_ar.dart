// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'دينتيرا';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get clinics => 'العيادات';

  @override
  String get patients => 'المرضى';

  @override
  String get appointments => 'المواعيد';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get continueButton => 'متابعة';

  @override
  String get continueAsGuest => 'المتابعة كضيف';

  @override
  String get save => 'حفظ';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get back => 'رجوع';

  @override
  String get confirm => 'تأكيد';

  @override
  String get search => 'بحث';

  @override
  String get filter => 'تصفية';

  @override
  String get all => 'الكل';

  @override
  String get none => 'لا يوجد';

  @override
  String get status => 'الحالة';

  @override
  String get date => 'التاريخ';

  @override
  String get time => 'الوقت';

  @override
  String get notes => 'الملاحظات';

  @override
  String get completed => 'المكتمل';

  @override
  String get remaining => 'المتبقي';

  @override
  String percentComplete(int percent) {
    return '$percent٪ مكتمل';
  }

  @override
  String requirementsLeft(int count) {
    return 'بقي $count من المتطلبات';
  }

  @override
  String get target => 'الهدف';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String get evaluated => 'تم التقييم';

  @override
  String get close => 'إغلاق';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get warning => 'تحذير';

  @override
  String get success => 'نجاح';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get create => 'إنشاء';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get invalidNumber => 'يرجى إدخال رقم صحيح';

  @override
  String get prosthodontics => 'الاستعاضة الصناعية';

  @override
  String get removableProsthodontics => 'الاستعاضة المتحركة';

  @override
  String get fixedProsthodontics => 'الاستعاضة الثابتة';

  @override
  String get endodontics => 'علاج جذور الأسنان';

  @override
  String get operative => 'العلاج التحفظي';

  @override
  String get operativeDentistry => 'العلاج التحفظي';

  @override
  String get oralSurgery => 'جراحة الفم';

  @override
  String get orthodontics => 'تقويم الأسنان';

  @override
  String get pedodontics => 'طب أسنان الأطفال';

  @override
  String get periodontics => 'علاج اللثة';

  @override
  String get oralMedicine => 'طب الفم';

  @override
  String get completeDenture => 'طقم أسنان كامل';

  @override
  String get singleCompleteDenture => 'طقم كامل أحادي';

  @override
  String get rpiClaspAssembly => 'ضمّة RPI';

  @override
  String get rootCanalTreatment => 'علاج جذور الأسنان';

  @override
  String get classIComposite => 'حشوة كومبوزيت صنف أول';

  @override
  String get classIIComposite => 'حشوة كومبوزيت صنف ثانٍ';

  @override
  String get simpleExtraction => 'خلع أسنان بسيط';

  @override
  String get surgicalExtraction => 'خلع أسنان جراحي';

  @override
  String get scalingAndRootPlaning => 'تقليح الأسنان وكشط الجذور';

  @override
  String get pulpotomy => 'بتر اللب';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodAfternoon => 'مساء الخير';

  @override
  String get goodEvening => 'مساء الخير';

  @override
  String get upNext => 'الموعد القادم';

  @override
  String get noUpcomingAppointments => 'لا توجد مواعيد قادمة';

  @override
  String get noUpcomingAppointmentsDescription =>
      'ليس لديك أي مواعيد مجدولة خلال الـ 48 ساعة القادمة.';

  @override
  String get clinicalReminders => 'تنبيهات إكلينيكية';

  @override
  String get noRemindersPending => 'لا توجد تنبيهات معلقة';

  @override
  String get allClinicalTasksCompleted =>
      'جميع المتابعات الإكلينيكية وأهداف المتطلبات مكتملة ومحدثة.';

  @override
  String get quickStats => 'إحصائيات سريعة';

  @override
  String get activeCases => 'الحالات النشطة';

  @override
  String get completedCases => 'الحالات المكتملة';

  @override
  String get totalQuotas => 'إجمالي المتطلبات';

  @override
  String get upcomingAppointments => 'المواعيد القادمة';

  @override
  String get scheduleNewAppointment => 'جدولة موعد جديد';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get overallAcademicProgress => 'التقدم الأكاديمي العام';

  @override
  String get onTrack => 'على المسار الصحيح';

  @override
  String get needsFocus => 'بحاجة لتركيز';

  @override
  String get clinicalDepartments => 'الأقسام الإكلينيكية';

  @override
  String get clinicalRequirements => 'المتطلبات الإكلينيكية';

  @override
  String get searchClinics => 'البحث في العيادات...';

  @override
  String get searchClinicsHint => 'البحث عن عيادة بالاسم أو القسم...';

  @override
  String get addClinic => 'إضافة عيادة';

  @override
  String get editClinic => 'تعديل العيادة';

  @override
  String get deleteClinic => 'حذف العيادة';

  @override
  String get clinicName => 'اسم العيادة';

  @override
  String get targetQuota => 'الهدف المطلوب';

  @override
  String get targetCountLabel => 'العدد المطلوب للمتطلب';

  @override
  String get requirementTitle => 'عنوان المتطلب';

  @override
  String get addRequirement => 'إضافة متطلب';

  @override
  String get editRequirement => 'تعديل المتطلب';

  @override
  String get deleteRequirement => 'حذف المتطلب';

  @override
  String get academicYear => 'السنة الدراسية';

  @override
  String get sortClinics => 'ترتيب العيادات';

  @override
  String get orderClinicsSubtitle =>
      'ترتيب الأقسام الإكلينيكية وفق المعايير الأكاديمية';

  @override
  String get sortByName => 'الاسم (أ - ي)';

  @override
  String get sortByNameSubtitle => 'ترتيب أبجدي حسب اسم العيادة';

  @override
  String get sortByAcademicYear => 'السنة الدراسية';

  @override
  String get sortByAcademicYearSubtitle => 'ترتيب حسب منهج السنة الدراسية';

  @override
  String get sortByQuotaProgress => 'نسبة إنجاز المتطلبات';

  @override
  String get sortByQuotaProgressSubtitle =>
      'النسبة الأعلى من المتطلبات المنجزة أولاً';

  @override
  String get noClinicsFound => 'لم يتم العثور على أي عيادات';

  @override
  String get noClinicsMatching => 'لا توجد عيادات تطابق معايير البحث';

  @override
  String get overallProgress => 'التقدم الإجمالي';

  @override
  String get proceduralRequirements => 'المتطلبات الإجرائية';

  @override
  String get noRequirementsAddedYet => 'لم تتم إضافة أي متطلبات بعد';

  @override
  String get defineClinicalQuotas =>
      'حدد الأهداف الإكلينيكية والمتطلبات الإجرائية لهذه العيادة.';

  @override
  String get generateReport => 'إنشاء تقرير';

  @override
  String get generateQuotaReport => 'إنشاء تقرير المتطلبات';

  @override
  String get casesLogged => 'الحالات المسجلة';

  @override
  String get logCase => 'تسجيل حالة';

  @override
  String get logCaseRecord => 'تسجيل سجل حالة';

  @override
  String get evaluateCase => 'تقييم الحالة';

  @override
  String get viewCases => 'عرض الحالات';

  @override
  String get requirementCases => 'حالات المتطلب';

  @override
  String get noCasesLoggedYet => 'لم يتم تسجيل أي حالات بعد';

  @override
  String get noClinicalCasesLoggedYet => 'لم يتم تسجيل أي حالات سريرية بعد';

  @override
  String get logCaseToMeetQuota =>
      'قم بتسجيل الحالات الإكلينيكية لمتابعة التقدم نحو إنجاز هذا المتطلب الأكاديمي.';

  @override
  String get deleteClinicConfirmation =>
      'هل أنت متأكد من حذف هذه العيادة؟ سيتم حذف جميع المتطلبات والسجلات المرتبطة بها نهائياً.';

  @override
  String get deleteRequirementConfirmation =>
      'هل أنت متأكد من حذف هذا المتطلب؟ سيتم حذف جميع الحالات المسجلة تحت هذا المتطلب نهائياً.';

  @override
  String get patientRoster => 'سجل المرضى';

  @override
  String get searchPatients => 'البحث عن مريض...';

  @override
  String get searchPatientsHint => 'البحث بالاسم أو رقم الهاتف...';

  @override
  String get addPatient => 'إضافة مريض';

  @override
  String get editPatient => 'تعديل بيانات المريض';

  @override
  String get deletePatient => 'حذف المريض';

  @override
  String get patientName => 'اسم المريض';

  @override
  String get patientNameLabel => 'اسم المريض الكامل';

  @override
  String get patientDetails => 'بيانات المريض';

  @override
  String get patientCaseSheet => 'ملف حالة المريض';

  @override
  String get phone => 'الهاتف';

  @override
  String get phoneNumberLabel => 'رقم الهاتف';

  @override
  String get gender => 'الجنس';

  @override
  String get genderLabel => 'الجنس';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get age => 'العمر';

  @override
  String get ageLabel => 'العمر (بالسنوات)';

  @override
  String get medicalHistory => 'التاريخ الطبي';

  @override
  String get medicalHistoryLabel => 'التاريخ الطبي / الحساسية';

  @override
  String get dentalHistory => 'تاريخ الأسنان';

  @override
  String get dentalHistoryLabel => 'تاريخ الأسنان / الشكوى الرئيسية';

  @override
  String get patientHistory => 'تاريخ المريض';

  @override
  String get casesAndProcedures => 'الحالات والإجراءات';

  @override
  String get caseHistory => 'سجل الحالات';

  @override
  String get treatmentPlan => 'خطة العلاج';

  @override
  String get treatmentPlanPhases => 'مراحل خطة العلاج';

  @override
  String get addTreatmentPlan => 'إضافة خطة علاج';

  @override
  String get addTreatmentPlanItem => 'إضافة إجراء علاجي';

  @override
  String get noTreatmentPlanItems => 'لم تتم إضافة أي بنود في خطة العلاج بعد';

  @override
  String get addTreatmentPlanDescription =>
      'أنشئ خطة علاج أسنان منظمة على مراحل لهذا المريض.';

  @override
  String get radiographs => 'الأشعة السينية';

  @override
  String get radiographsTitle => 'الأشعة السينية (X-Rays)';

  @override
  String get attachXRay => 'إرفاق أشعة';

  @override
  String get attachRadiograph => 'إرفاق صورة أشعة';

  @override
  String get noRadiographsAttached => 'لم يتم إرفاق أي أشعة سينية';

  @override
  String get attachRadiographDescription =>
      'أرفق أشعة حول ذروية، أو إطباقية، أو بانورامية للمراجعة التشخيصية دون اتصال.';

  @override
  String get radiographImage => 'صورة الأشعة';

  @override
  String get importRadiograph => 'استيراد صورة الأشعة السينية';

  @override
  String get cameraOrGallery => 'يدعم التقاط الكاميرا أو الاستيراد من المعرض';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get projectionType => 'نوع العرض / المسقط';

  @override
  String get periapical => 'حول ذروية (Periapical)';

  @override
  String get bitewing => 'إطباقية (Bitewing)';

  @override
  String get panoramic => 'بانورامية (Panoramic)';

  @override
  String get other => 'أخرى';

  @override
  String get captureDate => 'تاريخ الالتقاط';

  @override
  String get radiographicFindings => 'ملاحظات ومشاهدات الأشعة';

  @override
  String get noPatientsFound => 'لم يتم العثور على مرضى';

  @override
  String get noPatientsRegisteredYet => 'لم يتم تسجيل أي مرضى بعد';

  @override
  String get startAddingPatients =>
      'ابدأ بإضافة المرضى لإدارة العلاجات والمواعيد وسجلات الحالات.';

  @override
  String get sortPatients => 'ترتيب المرضى';

  @override
  String get orderPatientsSubtitle =>
      'ترتيب سجل المرضى وفق المعايير الإكلينيكية';

  @override
  String get sortByDateAdded => 'تاريخ الإضافة (الأحدث أولاً)';

  @override
  String get sortByDateAddedSubtitle => 'ترتيب حسب أحدث مريض تم تسجيله';

  @override
  String get sortByActiveCases => 'عدد الحالات النشطة';

  @override
  String get sortByActiveCasesSubtitle =>
      'إعطاء الأولوية للمرضى ذوي الإجراءات الإكلينيكية قيد التنفيذ';

  @override
  String get deletePatientConfirmation =>
      'هل أنت متأكد من حذف هذا المريض؟ سيتم حذف جميع سجلات الحالات، المواعيد، الأشعة، وخطط العلاج نهائياً.';

  @override
  String get scheduleAppointment => 'حجز موعد';

  @override
  String get editAppointment => 'تعديل الموعد';

  @override
  String get deleteAppointment => 'حذف الموعد';

  @override
  String get cancelAppointment => 'إلغاء الموعد';

  @override
  String get selectClinic => 'اختر العيادة';

  @override
  String get selectPatient => 'اختر المريض';

  @override
  String get noAppointmentsScheduled => 'لا توجد مواعيد مجدولة';

  @override
  String get noAppointmentsForDate => 'لا توجد مواعيد في هذا اليوم';

  @override
  String get allClinics => 'جميع العيادات';

  @override
  String get filterByClinic => 'تصفية حسب العيادة';

  @override
  String get statusScheduled => 'مجدول';

  @override
  String get statusConfirmed => 'مؤكد';

  @override
  String get statusInProgress => 'قيد التنفيذ';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get today => 'اليوم';

  @override
  String get tomorrow => 'غداً';

  @override
  String get yesterday => 'أمس';

  @override
  String get doctorProfile => 'الملف الشخصي للطبيب';

  @override
  String get academicProfile => 'الملف الأكاديمي';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get themeSystem => 'تلقائي حسب النظام';

  @override
  String get themeLight => 'الوضع النهاري';

  @override
  String get themeDark => 'الوضع الليلي';

  @override
  String get language => 'اللغة';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية (Arabic)';

  @override
  String get darkMode => 'الوضع الليلي';

  @override
  String get patientFollowUpAlerts => 'تنبيهات متابعة المرضى';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get backupAndDataManagement => 'النسخ الاحتياطي وإدارة البيانات';

  @override
  String get exportLocalBackup => 'تصدير نسخة احتياطية محلية';

  @override
  String get restoreDatabase => 'استعادة قاعدة البيانات';

  @override
  String get resetAllData => 'إعادة تعيين كافة البيانات';

  @override
  String get resetDatabaseConfirmation =>
      'هل أنت متأكد من إعادة تعيين كافة البيانات الإكلينيكية؟ هذا الإجراء لا يمكن التراجع عنه وسيعيد تهيئة العيادات الافتراضية.';

  @override
  String get aboutDentera => 'عن دينتيرا';

  @override
  String get denteraSubtitle =>
      'نظام إدارة ومتابعة المتطلبات السريرية لطلاب طب الأسنان والعيادات';

  @override
  String get version => 'الإصدار';

  @override
  String get welcomeDoctor => 'مرحبًا بك دكتور.';

  @override
  String get setupClinicalWorkspace =>
      'دعنا نعد مساحة عملك الإكلينيكية. ما هو اسمك؟';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get pleaseEnterYourName => 'يرجى إدخال اسمك';

  @override
  String get yourInstitution => 'جامعتك أو كليتك';

  @override
  String get universityOrSchool => 'الجامعة / الكلية';

  @override
  String get clinicalYear => 'السنة الإكلينيكية';

  @override
  String get enterWorkspace => 'الدخول لمساحة العمل';

  @override
  String get supervisorName => 'اسم المشرف';

  @override
  String get gradeScore => 'الدرجة / التقييم';

  @override
  String get supervisorFeedback => 'ملاحظات المشرف';

  @override
  String get toothNumberRegion => 'رقم السن / المنطقة';

  @override
  String get phase => 'المرحلة';

  @override
  String get procedure => 'الإجراء';

  @override
  String get estimatedCost => 'التكلفة التقديرية';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get deselectAll => 'إلغاء تحديد الكل';

  @override
  String selectedCount(int count) {
    return 'تم تحديد $count';
  }

  @override
  String get deleteSelectedPatients => 'حذف المرضى المحددين؟';

  @override
  String get deleteSelectedPatientsMessage =>
      'سيؤدي حذف المرضى المحددين إلى إزالة جميع سجلات الحالات الإكلينيكية والمواعيد المجدولة المرتبطة بهم نهائياً. لا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟';

  @override
  String deleteCount(int count) {
    return 'حذف ($count)';
  }

  @override
  String get deletePatients => 'حذف المرضى';

  @override
  String get addFirstPatient => 'إضافة أول مريض';

  @override
  String get noPhone => 'بدون هاتف';

  @override
  String get medicalAlert => 'تنبيه طبي';

  @override
  String get active => 'نشط';

  @override
  String get moreOptions => 'خيارات إضافية';

  @override
  String get clinicalCases => 'الحالات الإكلينيكية';

  @override
  String get laterToday => 'لاحقاً اليوم';

  @override
  String get openCaseSheet => 'فتح ملف الحالة';

  @override
  String get appointmentActions => 'إجراءات الموعد';

  @override
  String get appointmentDeleted => 'تم حذف الموعد';

  @override
  String get caseRecordDeleted => 'تم حذف سجل الحالة';

  @override
  String get deleteCaseRecord => 'حذف سجل الحالة';

  @override
  String get deleteCaseRecordConfirmation =>
      'هل أنت متأكد من رغبتك في حذف سجل هذه الحالة؟ إذا كانت الحالة مكتملة، فسيتم إنقاص عدد الحالات المنجزة في المتطلب تلقائياً.';

  @override
  String get logFirstCase => 'تسجيل أول حالة';

  @override
  String startLoggingCases(String name) {
    return 'ابدأ بتسجيل الحالات والإجراءات المكتملة للمريض $name.';
  }

  @override
  String get chiefComplaint => 'الشكوى الرئيسية (CC)';

  @override
  String get historyOfChiefComplaint => 'تاريخ الشكوى الرئيسية (HCC)';

  @override
  String get medicalHistoryAndAllergies => 'التاريخ الطبي والحساسية';

  @override
  String get currentMedications => 'الأدوية الحالية';

  @override
  String get diagnosticAids => 'الوسائل التشخيصية';

  @override
  String get restoreDatabaseConfirmationDetailed =>
      'ستؤدي استعادة قاعدة البيانات إلى استبدال بياناتك الحالية بالكامل بالملف المحدد.\n\nهل أنت متأكد من رغبتك في المتابعة؟';

  @override
  String get allClinicalDataReset =>
      'تمت إعادة ضبط جميع البيانات والتفضيلات بنجاح.';

  @override
  String get agendaReminders => 'تنبيهات جدول اليوم التالي';

  @override
  String get exportBackupSubtitle => 'حفظ نسخة احتياطية مشفرة على جهازك';

  @override
  String get restoreBackupSubtitle =>
      'استيراد البيانات من ملف نسخة احتياطية محلية';

  @override
  String get privacyAndSecurity => 'الخصوصية والأمان';

  @override
  String get onDeviceOnly => '100% على جهازك فقط';

  @override
  String get resetAllClinicalData => 'إعادة ضبط جميع البيانات الإكلينيكية';

  @override
  String get assignToClinic => 'تعيين للعيادة';

  @override
  String get mainCaseProcedure => 'الحالة / الإجراء الرئيسي';

  @override
  String get selectMainProcedure => 'اختر الحالة / الإجراء الرئيسي';

  @override
  String get addContactAndDetailsOptional =>
      'إضافة جهات اتصال وتفاصيل (اختياري)';

  @override
  String get pleaseSelectMainProcedure =>
      'يرجى اختيار الحالة / الإجراء الرئيسي';

  @override
  String get savePatient => 'حفظ المريض';

  @override
  String get saveClinic => 'حفظ العيادة';

  @override
  String get saveRequirement => 'حفظ المتطلب';

  @override
  String get saveAppointment => 'حفظ الموعد';

  @override
  String get saveEvaluation => 'حفظ التقييم';

  @override
  String get addDentalClinic => 'إضافة عيادة أسنان';

  @override
  String get createClinicSubtitle =>
      'إنشاء قسم سريري جديد لتتبع الحصص الأكاديمية';

  @override
  String get editClinicSubtitle =>
      'تحديث اسم العيادة والمنهج الدراسي ولون المظهر';

  @override
  String get department => 'القسم السريري';

  @override
  String get departmentThemeColor => 'لون السمة للقسم السريري';

  @override
  String get editPatientProfile => 'تعديل ملف المريض';

  @override
  String get updateDemographicsSubtitle =>
      'تحديث البيانات الديموغرافية والتاريخ الطبي';

  @override
  String get clinicalAnamnesisHistory => 'السيرة المرضية والفحص السريري';

  @override
  String get defineProceduralQuota => 'تحديد الحصة الإجرائية';

  @override
  String get adjustProcedureTitleSubtitle =>
      'تعديل عنوان الإجراء والحصة المستهدفة';

  @override
  String get procedureTitle => 'عنوان الإجراء';

  @override
  String get customProcedureTitle => 'عنوان الإجراء المخصص';

  @override
  String get procedureRequirement => 'الإجراء / المتطلب السريري';

  @override
  String get scheduleDateTime => 'تاريخ ووقت الموعد';

  @override
  String get appointmentStatus => 'حالة الموعد';

  @override
  String get procedureAndClinicalNotes => 'الإجراء والملاحظات السريرية';

  @override
  String get clinicalNotesOptional => 'ملاحظات سريرية / رقم السن (اختياري)';

  @override
  String get pleaseSelectPatient => 'يرجى اختيار مريض';

  @override
  String get pleaseSelectClinic => 'يرجى اختيار عيادة';

  @override
  String get failedToLoadPatients => 'فشل في تحميل المرضى';

  @override
  String get failedToLoadClinics => 'فشل في تحميل العيادات';

  @override
  String get failedToSavePatient => 'فشل في حفظ المريض';

  @override
  String get failedToSaveClinic => 'فشل في حفظ العيادة';

  @override
  String get failedToSaveAppointment => 'فشل في حفظ الموعد';

  @override
  String get failedToSaveRequirement => 'فشل في حفظ المتطلب';

  @override
  String get failedToSaveCase => 'فشل في حفظ الحالة السريرية';

  @override
  String get editClinicalCase => 'تعديل الحالة السريرية';

  @override
  String get logClinicalCase => 'تسجيل حالة سريرية';

  @override
  String get procedureStatus => 'حالة الإجراء';

  @override
  String get plannedVisits => 'عدد الزيارات المخططة (1-10)';

  @override
  String get visitMilestones => 'تسميات مراحل الزيارات';

  @override
  String visitLabel(int number) {
    return 'تسمية الزيارة $number';
  }

  @override
  String get clinicalFindingsNotes => 'الملاحظات والنتائج السريرية';

  @override
  String get updateCaseRecord => 'تحديث سجل الحالة';

  @override
  String get noRequirementsDefined =>
      'لم يتم تحديد أي متطلبات إجرائية لهذه العيادة بعد.';

  @override
  String get evaluateCaseRecord => 'تقييم سجل الحالة';

  @override
  String get evaluationRemarks => 'الملاحظات السريرية وملاحظات التقييم';

  @override
  String get sortCasesAndRequirements => 'فرز الحالات والمتطلبات';

  @override
  String get orderRequirementsSubtitle =>
      'ترتيب المتطلبات السريرية حسب التقدم أو المعايير';

  @override
  String get dangerZone => 'منطقة الخطر';

  @override
  String get wipeAllData => 'مسح كافة البيانات';

  @override
  String get destructiveResetWarning =>
      'هذا الإجراء نهائي ولا يمكن التراجع عنه. سيتم مسح جميع المرضى والمتطلبات السريرية وسجلات الحالات والمواعيد وتفضيلات المستخدم نهائياً من جهازك.';

  @override
  String get typeResetToConfirm =>
      'اكتب \"RESET\" بالأحرف الكبيرة أدناه للتأكيد:';

  @override
  String get typeResetPlaceholder => 'اكتب RESET للتأكيد';

  @override
  String get failedToResetDatabase => 'فشل في إعادة ضبط قاعدة البيانات';

  @override
  String get stageProposedTreatment => 'إدراج علاج مقترح';

  @override
  String get editTreatmentPlanItem => 'تعديل عنصر خطة العلاج';

  @override
  String get academicTreatmentPhase => 'مرحلة العلاج الأكاديمية';

  @override
  String get proposedTreatmentTitle => 'عنوان الإجراء / العلاج المقترح';

  @override
  String get targetDepartmentOptional => 'القسم السريري المستهدف (اختياري)';

  @override
  String get treatmentStatus => 'حالة العلاج';

  @override
  String get facultyInstructions => 'ملاحظات سريرية / تعليمات المشرف';

  @override
  String get updateTreatment => 'تحديث العلاج';

  @override
  String get stageTreatment => 'إدراج العلاج';

  @override
  String get generalInterdisciplinary => 'عام / متعدد التخصصات';

  @override
  String get academicSupervisoryPortfolio => 'الملف الأكاديمي الإشرافي';

  @override
  String get departmentScope => 'نطاق الأقسام السريرية';

  @override
  String get allDepartmentsAndClinics => 'جميع الأقسام والعيادات السريرية';

  @override
  String get caseDateRange => 'نطاق تواريخ الحالات';

  @override
  String get allTimeCompleteRecord => 'كل الأوقات (سجل كامل)';

  @override
  String get previewAndPrintPdf => 'معاينة وطباعة PDF';

  @override
  String get sharePdfReport => 'مشاركة تقرير PDF';

  @override
  String get exportTabularCsv => 'تصدير CSV جدولي (كشف الدرجات)';

  @override
  String get saving => 'جارٍ الحفظ...';

  @override
  String recordProcedureForPatient(String name) {
    return 'تسجيل الإجراء السريري للمريض $name';
  }

  @override
  String recordProcedureForPatientId(String id) {
    return 'تسجيل الإجراء السريري للمريض رقم $id';
  }

  @override
  String get noClinicsAvailable =>
      'لا توجد عيادات متاحة. يرجى إنشاء عيادة أولاً.';

  @override
  String failedToLoadClinicsWithError(String error) {
    return 'فشل تحميل العيادات: $error';
  }

  @override
  String failedToLoadRequirementsWithError(String error) {
    return 'فشل تحميل المتطلبات: $error';
  }

  @override
  String get statusEvaluated => 'مُقيَّمة';

  @override
  String get visitSingular => 'زيارة';

  @override
  String get visitsPlural => 'زيارات';

  @override
  String visitNumberHint(int number) {
    return 'مثال: الزيارة $number، الطبعة الأولية...';
  }

  @override
  String get clinicalNotesHint =>
      'مثال: تم إكمال الطبعة الأولية، تحضير تجويف من الصنف الثاني...';

  @override
  String get pleaseSelectRequirement => 'يرجى اختيار المتطلب الإجرائي';

  @override
  String get failedToUpdateCase => 'فشل تحديث الحالة السريرية';

  @override
  String get failedToLogCase => 'فشل تسجيل الحالة السريرية';

  @override
  String get clinicalProcedure => 'إجراء سريري';

  @override
  String get gradeScoreOptional => 'الدرجة / التقييم (اختياري)';

  @override
  String get gradeScoreHint => 'مثال: 9.0/10، ناجح، أ';

  @override
  String get evaluationRemarksHint =>
      'مثال: الحواف متطابقة بشكل جيد، تحمل المريض الإجراء جيداً...';

  @override
  String get failedToEvaluateCase => 'فشل تقييم سجل الحالة';

  @override
  String get sortByTitle => 'الاسم (أ إلى ي)';

  @override
  String get sortByTitleSubtitle => 'ترتيب أبجدي حسب عنوان المتطلب';

  @override
  String get sortByProgress => 'التقدم في النصاب';

  @override
  String get sortByProgressSubtitle =>
      'النسبة المئوية الأعلى للحالات المكتملة أولاً';

  @override
  String get sortByTargetCount => 'النصاب المستهدف';

  @override
  String get sortByTargetCountSubtitle =>
      'متطلبات الحالات ذات الهدف الأعلى أولاً';

  @override
  String patientLabel(String name) {
    return 'المريض: $name';
  }

  @override
  String get phaseEmergency => 'المرحلة 1: الطوارئ';

  @override
  String get phasePreventivePerio => 'المرحلة 2: الوقاية / اللثة';

  @override
  String get phaseRestorative => 'المرحلة 3: الترميم والإصلاح';

  @override
  String get phaseMaintenance => 'المرحلة 4: المتابعة والصيانة';

  @override
  String get proposedTreatmentTitleHint =>
      'مثال: تقليح وكشط الجذور، علاج عصب أمامي، حشوة كمبوزيت صنف ثانٍ';

  @override
  String get pleaseEnterTreatmentTitle => 'يرجى إدخال عنوان إجراء العلاج';

  @override
  String get facultyInstructionsHint =>
      'أضف التبرير السريري، أرقام الأسنان، أو ملاحظات المشرف...';

  @override
  String get treatmentItemUpdated => 'تم تحديث عنصر خطة العلاج بنجاح';

  @override
  String treatmentItemStaged(int phase) {
    return 'تم إدراج عنصر خطة العلاج في المرحلة $phase';
  }

  @override
  String failedToSaveTreatmentPlan(String error) {
    return 'فشل حفظ خطة العلاج: $error';
  }

  @override
  String get statusProposed => 'مقترح';

  @override
  String get statusApproved => 'معتمد';

  @override
  String get changeImage => 'تغيير الصورة';

  @override
  String get removeImage => 'إزالة الصورة';

  @override
  String get pleaseSelectRadiograph => 'يرجى التقاط صورة شعاعية أو اختيارها.';

  @override
  String radiographAttachedSuccess(String type) {
    return 'تم إرفاق صورة الأشعة ($type) بنجاح';
  }

  @override
  String failedToSaveRadiograph(String error) {
    return 'فشل حفظ صورة الأشعة: $error';
  }

  @override
  String get radiographicFindingsHint =>
      'مثال: شفوفية شعاعية ذروية عند قمة جذر السن 36، مستوى العظم الحافي طبيعي...';

  @override
  String get radiographSelected => 'تم تحديد صورة الأشعة';

  @override
  String get clearDateFilter => 'مسح تصفية التاريخ';

  @override
  String get clinicSingular => 'عيادة';

  @override
  String get clinicsPlural => 'عيادات';

  @override
  String get requirementSingular => 'متطلب';

  @override
  String get requirementsPlural => 'متطلبات';

  @override
  String get caseLogSingular => 'سجل حالة';

  @override
  String get caseLogsPlural => 'سجلات الحالات';

  @override
  String get failedToGeneratePdf => 'فشل إنشاء تقرير PDF';

  @override
  String get failedToSharePdf => 'فشل مشاركة تقرير PDF';

  @override
  String get failedToExportCsv => 'فشل تصدير كشف الدرجات بصيغة CSV';

  @override
  String get sort => 'ترتيب';

  @override
  String get updateScheduleNotesSubtitle =>
      'تحديث موعد الجلسة، الحالة، والملاحظات السريرية';

  @override
  String get schedule => 'المواعيد';

  @override
  String get nextUp => 'التالي';

  @override
  String get schedulePatient => 'حجز موعد لمريض';

  @override
  String get newPatient => 'مريض جديد';

  @override
  String get pleaseEnterPatientName => 'يرجى إدخال اسم المريض';

  @override
  String get patientRequired => 'المريض *';

  @override
  String get clinicDepartmentRequired => 'العيادة / القسم *';

  @override
  String get loadingPatients => 'جارٍ تحميل المرضى...';

  @override
  String get loadingClinics => 'جارٍ تحميل العيادات...';

  @override
  String get selectPatientHint => 'اختر المريض...';

  @override
  String get selectClinicHint => 'اختر العيادة...';

  @override
  String get noPatientsAvailable => 'لا يوجد مرضى متاحون';

  @override
  String get deleteClinics => 'حذف العيادات';

  @override
  String get deleteSelectedClinics => 'حذف العيادات المحددة؟';

  @override
  String get clinicsAndRequirements => 'العيادات والمتطلبات';

  @override
  String get noClinicsAddedYet => 'لم تتم إضافة أي عيادات بعد';

  @override
  String noClinicsFoundInCategory(String category) {
    return 'لم يتم العثور على عيادات في \"$category\"';
  }

  @override
  String get trySelectingAllOrDifferentCategory =>
      'جرّب اختيار \"الكل\" أو فئة سريرية مختلفة.';

  @override
  String requirementsMet(int completed, int target) {
    return 'تم إنجاز $completed من أصل $target متطلبات';
  }

  @override
  String get sortCases => 'ترتيب الحالات';

  @override
  String get deleteCases => 'حذف الحالات';

  @override
  String percentDone(int percent) {
    return '$percent٪ تم';
  }

  @override
  String get noPatientsAssignedYet => 'لم يتم تعيين أي مرضى بعد.';

  @override
  String get tomorrowsPatients => 'مرضى الغد';

  @override
  String get noUpcomingPatientsTomorrow => 'لا يوجد مرضى مجدولون للغد.';

  @override
  String get viewFullSchedule => 'عرض الجدول بالكامل';

  @override
  String get addFirstPatientDescription =>
      'أضف أول مريض للبدء في متابعة المتطلبات السريرية.';

  @override
  String get appTheme => 'سمة التطبيق';

  @override
  String get restore => 'استعادة';

  @override
  String get restoreFromBackup => 'الاستعادة من النسخة الاحتياطية';

  @override
  String get localNotifications => 'الإشعارات المحلية';

  @override
  String get dataAndOfflineBackup => 'البيانات والنسخ الاحتياطي';

  @override
  String get about => 'حول';

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get attach => 'إرفاق';

  @override
  String get attachRadiographModalTitle => 'إرفاق صورة أشعة (X-Ray)';

  @override
  String get noAppointmentsToday => 'لا توجد مواعيد مجدولة اليوم';

  @override
  String get scheduledProceduresAppearHere =>
      'ستظهر الإجراءات السريرية المجدولة هنا.';

  @override
  String get reqs => 'المتطلبات';

  @override
  String get noActiveRequirements => 'لا توجد متطلبات نشطة';

  @override
  String get chooseAppTheme => 'اختر مظهر التطبيق';

  @override
  String get registerClinicalDepartments =>
      'سجّل أقسامك السريرية لتتبع النصاب المستهدف وتقدم الحالات.';

  @override
  String defineClinicalQuotasForClinic(String clinicName) {
    return 'حدد النصاب السريري والأهداف الإجرائية لـ $clinicName.';
  }

  @override
  String get deleteSelected => 'حذف المحدد';

  @override
  String get restoreDatabaseBackupTitle =>
      'استعادة النسخة الاحتياطية لقاعدة البيانات؟';
}
