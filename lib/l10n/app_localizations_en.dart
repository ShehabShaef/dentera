// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dentera';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get clinics => 'Clinics';

  @override
  String get patients => 'Patients';

  @override
  String get appointments => 'Appointments';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get continueButton => 'Continue';

  @override
  String get continueAsGuest => 'Continue as a guest';

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get back => 'Back';

  @override
  String get confirm => 'Confirm';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get none => 'None';

  @override
  String get status => 'Status';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get notes => 'Notes';

  @override
  String get completed => 'Completed';

  @override
  String get remaining => 'Remaining';

  @override
  String percentComplete(int percent) {
    return '$percent% Complete';
  }

  @override
  String requirementsLeft(int count) {
    return '$count requirements left';
  }

  @override
  String get target => 'Target';

  @override
  String get inProgress => 'In Progress';

  @override
  String get evaluated => 'Evaluated';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get warning => 'Warning';

  @override
  String get success => 'Success';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get create => 'Create';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidNumber => 'Please enter a valid number';

  @override
  String get prosthodontics => 'Prosthodontics';

  @override
  String get removableProsthodontics => 'Removable Prosthodontics';

  @override
  String get fixedProsthodontics => 'Fixed Prosthodontics';

  @override
  String get endodontics => 'Endodontics';

  @override
  String get operative => 'Operative';

  @override
  String get operativeDentistry => 'Operative Dentistry';

  @override
  String get oralSurgery => 'Oral Surgery';

  @override
  String get orthodontics => 'Orthodontics';

  @override
  String get pedodontics => 'Pedodontics';

  @override
  String get periodontics => 'Periodontics';

  @override
  String get oralMedicine => 'Oral Medicine';

  @override
  String get completeDenture => 'Complete Denture';

  @override
  String get singleCompleteDenture => 'Single Complete Denture';

  @override
  String get rpiClaspAssembly => 'RPI Clasp Assembly';

  @override
  String get rootCanalTreatment => 'Root Canal Treatment';

  @override
  String get classIComposite => 'Class I Composite';

  @override
  String get classIIComposite => 'Class II Composite';

  @override
  String get simpleExtraction => 'Simple Extraction';

  @override
  String get surgicalExtraction => 'Surgical Extraction';

  @override
  String get scalingAndRootPlaning => 'Scaling & Root Planing';

  @override
  String get pulpotomy => 'Pulpotomy';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get upNext => 'Up Next';

  @override
  String get noUpcomingAppointments => 'No upcoming appointments';

  @override
  String get noUpcomingAppointmentsDescription =>
      'You have no appointments scheduled for the next 48 hours.';

  @override
  String get clinicalReminders => 'Clinical Reminders';

  @override
  String get noRemindersPending => 'No reminders pending';

  @override
  String get allClinicalTasksCompleted =>
      'All clinical follow-ups and requirement targets are up to date.';

  @override
  String get quickStats => 'Quick Stats';

  @override
  String get activeCases => 'Active Cases';

  @override
  String get completedCases => 'Completed Cases';

  @override
  String get totalQuotas => 'Total Quotas';

  @override
  String get upcomingAppointments => 'Upcoming Appointments';

  @override
  String get scheduleNewAppointment => 'Schedule New Appointment';

  @override
  String get viewAll => 'View All';

  @override
  String get overallAcademicProgress => 'Overall Academic Progress';

  @override
  String get onTrack => 'On Track';

  @override
  String get needsFocus => 'Needs Focus';

  @override
  String get clinicalDepartments => 'Clinical Departments';

  @override
  String get clinicalRequirements => 'Clinical Requirements';

  @override
  String get searchClinics => 'Search clinics...';

  @override
  String get searchClinicsHint => 'Search clinics by name or department...';

  @override
  String get addClinic => 'Add Clinic';

  @override
  String get editClinic => 'Edit Clinic';

  @override
  String get deleteClinic => 'Delete Clinic';

  @override
  String get clinicName => 'Clinic Name';

  @override
  String get targetQuota => 'Target Quota';

  @override
  String get targetCountLabel => 'Target Quota Count';

  @override
  String get requirementTitle => 'Requirement Title';

  @override
  String get addRequirement => 'Add Requirement';

  @override
  String get editRequirement => 'Edit Requirement';

  @override
  String get deleteRequirement => 'Delete Requirement';

  @override
  String get academicYear => 'Academic Year';

  @override
  String get sortClinics => 'Sort Clinics';

  @override
  String get orderClinicsSubtitle =>
      'Order clinical departments by academic criteria';

  @override
  String get sortByName => 'Name (A to Z)';

  @override
  String get sortByNameSubtitle => 'Alphabetical order by clinic name';

  @override
  String get sortByAcademicYear => 'Academic Year';

  @override
  String get sortByAcademicYearSubtitle =>
      'Order by target academic year curriculum';

  @override
  String get sortByQuotaProgress => 'Quota Progress';

  @override
  String get sortByQuotaProgressSubtitle =>
      'Highest percentage of completed requirements first';

  @override
  String get noClinicsFound => 'No clinics found';

  @override
  String get noClinicsMatching =>
      'No clinical departments match search criteria';

  @override
  String get overallProgress => 'Overall Progress';

  @override
  String get proceduralRequirements => 'Procedural Requirements';

  @override
  String get noRequirementsAddedYet => 'No requirements added yet';

  @override
  String get defineClinicalQuotas =>
      'Define clinical quotas and procedural targets for this clinic.';

  @override
  String get generateReport => 'Generate Report';

  @override
  String get generateQuotaReport => 'Generate Quota Report';

  @override
  String get casesLogged => 'Cases Logged';

  @override
  String get logCase => 'Log Case';

  @override
  String get logCaseRecord => 'Log Case Record';

  @override
  String get evaluateCase => 'Evaluate Case';

  @override
  String get viewCases => 'View Cases';

  @override
  String get requirementCases => 'Requirement Cases';

  @override
  String get noCasesLoggedYet => 'No cases logged yet';

  @override
  String get noClinicalCasesLoggedYet => 'No clinical cases logged yet';

  @override
  String get logCaseToMeetQuota =>
      'Log clinical cases to track progress towards meeting this academic quota.';

  @override
  String get deleteClinicConfirmation =>
      'Are you sure you want to delete this clinic? All associated requirements and records will be permanently removed.';

  @override
  String get deleteRequirementConfirmation =>
      'Are you sure you want to delete this requirement? All logged cases under this requirement will be permanently removed.';

  @override
  String get patientRoster => 'Patient Roster';

  @override
  String get searchPatients => 'Search patients...';

  @override
  String get searchPatientsHint => 'Search by name or phone...';

  @override
  String get addPatient => 'Add Patient';

  @override
  String get editPatient => 'Edit Patient';

  @override
  String get deletePatient => 'Delete Patient';

  @override
  String get patientName => 'Patient Name';

  @override
  String get patientNameLabel => 'Patient Full Name';

  @override
  String get patientDetails => 'Patient Details';

  @override
  String get patientCaseSheet => 'Patient Case Sheet';

  @override
  String get phone => 'Phone';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get gender => 'Gender';

  @override
  String get genderLabel => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get age => 'Age';

  @override
  String get ageLabel => 'Age (Years)';

  @override
  String get medicalHistory => 'Medical History';

  @override
  String get medicalHistoryLabel => 'Medical History / Allergies';

  @override
  String get dentalHistory => 'Dental History';

  @override
  String get dentalHistoryLabel => 'Dental History / Chief Complaint';

  @override
  String get patientHistory => 'Patient History';

  @override
  String get casesAndProcedures => 'Cases & Procedures';

  @override
  String get caseHistory => 'Case History';

  @override
  String get treatmentPlan => 'Treatment Plan';

  @override
  String get treatmentPlanPhases => 'Treatment Plan Phases';

  @override
  String get addTreatmentPlan => 'Add Treatment Plan';

  @override
  String get addTreatmentPlanItem => 'Add Treatment Item';

  @override
  String get noTreatmentPlanItems => 'No treatment plan items added yet';

  @override
  String get addTreatmentPlanDescription =>
      'Create a structured phased dental treatment plan for this patient.';

  @override
  String get radiographs => 'Radiographs';

  @override
  String get radiographsTitle => 'Radiographs (X-Rays)';

  @override
  String get attachXRay => 'Attach X-Ray';

  @override
  String get attachRadiograph => 'Attach Radiograph';

  @override
  String get noRadiographsAttached => 'No radiographs attached';

  @override
  String get attachRadiographDescription =>
      'Attach periapical, bitewing, or panoramic X-rays for offline diagnostic review.';

  @override
  String get radiographImage => 'Radiograph Image';

  @override
  String get importRadiograph => 'Import radiographic X-ray';

  @override
  String get cameraOrGallery =>
      'Supports Camera capture or Photo Gallery import';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get projectionType => 'Projection Type';

  @override
  String get periapical => 'Periapical';

  @override
  String get bitewing => 'Bitewing';

  @override
  String get panoramic => 'Panoramic';

  @override
  String get other => 'Other';

  @override
  String get captureDate => 'Capture Date';

  @override
  String get radiographicFindings => 'Radiographic Findings / Notes';

  @override
  String get noPatientsFound => 'No patients found';

  @override
  String get noPatientsRegisteredYet => 'No patients registered yet';

  @override
  String get startAddingPatients =>
      'Start adding patients to manage treatments, appointments, and case histories.';

  @override
  String get sortPatients => 'Sort Patients';

  @override
  String get orderPatientsSubtitle =>
      'Order patient roster by clinical criteria';

  @override
  String get sortByDateAdded => 'Date Added (Recent first)';

  @override
  String get sortByDateAddedSubtitle => 'Order by newest registered patient';

  @override
  String get sortByActiveCases => 'Active Case Count';

  @override
  String get sortByActiveCasesSubtitle =>
      'Prioritize patients with in-progress clinical procedures';

  @override
  String get deletePatientConfirmation =>
      'Are you sure you want to delete this patient? All case records, appointments, radiographs, and treatment plans will be permanently deleted.';

  @override
  String get scheduleAppointment => 'Schedule Appointment';

  @override
  String get editAppointment => 'Edit Appointment';

  @override
  String get deleteAppointment => 'Delete Appointment';

  @override
  String get cancelAppointment => 'Cancel Appointment';

  @override
  String get selectClinic => 'Select Clinic';

  @override
  String get selectPatient => 'Select Patient';

  @override
  String get noAppointmentsScheduled => 'No appointments scheduled';

  @override
  String get noAppointmentsForDate => 'No appointments for this date';

  @override
  String get allClinics => 'All Clinics';

  @override
  String get filterByClinic => 'Filter by Clinic';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get doctorProfile => 'Doctor Profile';

  @override
  String get academicProfile => 'Academic Profile';

  @override
  String get preferences => 'Preferences';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية (Arabic)';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get patientFollowUpAlerts => 'Patient Follow-up Alerts';

  @override
  String get notifications => 'Notifications';

  @override
  String get backupAndDataManagement => 'Backup & Data Management';

  @override
  String get exportLocalBackup => 'Export Local Backup';

  @override
  String get restoreDatabase => 'Restore Database';

  @override
  String get resetAllData => 'Reset All Data';

  @override
  String get resetDatabaseConfirmation =>
      'Are you sure you want to reset all clinical data? This action cannot be undone and will restore default seeded clinics.';

  @override
  String get aboutDentera => 'About Dentera';

  @override
  String get denteraSubtitle =>
      'Clinical dental education tracker for students and clinics';

  @override
  String get version => 'Version';

  @override
  String get welcomeDoctor => 'Welcome, Doctor.';

  @override
  String get setupClinicalWorkspace =>
      'Let\'s set up your clinical workspace. What\'s your name?';

  @override
  String get fullName => 'Full Name';

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get yourInstitution => 'Your Institution';

  @override
  String get universityOrSchool => 'University / School';

  @override
  String get clinicalYear => 'Clinical Year';

  @override
  String get enterWorkspace => 'Enter Workspace';

  @override
  String get supervisorName => 'Supervisor Name';

  @override
  String get gradeScore => 'Grade / Score';

  @override
  String get supervisorFeedback => 'Supervisor Feedback';

  @override
  String get toothNumberRegion => 'Tooth Number / Region';

  @override
  String get phase => 'Phase';

  @override
  String get procedure => 'Procedure';

  @override
  String get estimatedCost => 'Estimated Cost';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String selectedCount(int count) {
    return '$count Selected';
  }

  @override
  String get deleteSelectedPatients => 'Delete Selected Patients?';

  @override
  String get deleteSelectedPatientsMessage =>
      'Deleting selected patients will permanently remove all associated clinical case records and scheduled appointments. This action cannot be undone. Are you sure you want to proceed?';

  @override
  String deleteCount(int count) {
    return 'Delete ($count)';
  }

  @override
  String get deletePatients => 'Delete Patients';

  @override
  String get addFirstPatient => 'Add First Patient';

  @override
  String get noPhone => 'No Phone';

  @override
  String get medicalAlert => 'Medical Alert';

  @override
  String get active => 'Active';

  @override
  String get moreOptions => 'More options';

  @override
  String get clinicalCases => 'Clinical Cases';

  @override
  String get laterToday => 'Later Today';

  @override
  String get openCaseSheet => 'Open Case Sheet';

  @override
  String get appointmentActions => 'Appointment actions';

  @override
  String get appointmentDeleted => 'Appointment deleted';

  @override
  String get caseRecordDeleted => 'Case record deleted';

  @override
  String get deleteCaseRecord => 'Delete Case Record';

  @override
  String get deleteCaseRecordConfirmation =>
      'Are you sure you want to delete this case record? If this case was marked as completed, your requirement completed count will automatically be decremented.';

  @override
  String get logFirstCase => 'Log First Case';

  @override
  String startLoggingCases(String name) {
    return 'Start logging procedural cases and treatments completed for $name.';
  }

  @override
  String get chiefComplaint => 'Chief Complaint (CC)';

  @override
  String get historyOfChiefComplaint => 'History of Chief Complaint (HCC)';

  @override
  String get medicalHistoryAndAllergies => 'Medical History & Allergies';

  @override
  String get currentMedications => 'Current Medications';

  @override
  String get diagnosticAids => 'Diagnostic Aids';

  @override
  String get restoreDatabaseConfirmationDetailed =>
      'Restoring a database will overwrite your current clinical data, patients, and quotas with the selected backup file.\n\nAre you sure you want to proceed?';

  @override
  String get allClinicalDataReset =>
      'All clinical data and preferences have been successfully reset.';

  @override
  String get agendaReminders => 'Next-Day Agenda Reminders';

  @override
  String get exportBackupSubtitle =>
      'Save an encrypted SQLite copy to your device';

  @override
  String get restoreBackupSubtitle => 'Import data from a local backup file';

  @override
  String get privacyAndSecurity => 'Privacy & Security';

  @override
  String get onDeviceOnly => '100% On-Device';

  @override
  String get resetAllClinicalData => 'Reset All Clinical Data';

  @override
  String get assignToClinic => 'Assign to Clinic';

  @override
  String get mainCaseProcedure => 'Main Case / Procedure';

  @override
  String get selectMainProcedure => 'Select main case / procedure';

  @override
  String get addContactAndDetailsOptional => 'Add Contact & Details (Optional)';

  @override
  String get pleaseSelectMainProcedure =>
      'Please select a main case / procedure';

  @override
  String get savePatient => 'Save Patient';

  @override
  String get saveClinic => 'Save Clinic';

  @override
  String get saveRequirement => 'Save Requirement';

  @override
  String get saveAppointment => 'Save Appointment';

  @override
  String get saveEvaluation => 'Save Evaluation';

  @override
  String get addDentalClinic => 'Add Dental Clinic';

  @override
  String get createClinicSubtitle =>
      'Create a new clinical department to track quotas';

  @override
  String get editClinicSubtitle =>
      'Update clinic name, curriculum, and color theme';

  @override
  String get department => 'Department';

  @override
  String get departmentThemeColor => 'Department Theme Color';

  @override
  String get editPatientProfile => 'Edit Patient Profile';

  @override
  String get updateDemographicsSubtitle =>
      'Update demographics and medical history';

  @override
  String get clinicalAnamnesisHistory => 'Clinical Anamnesis / History';

  @override
  String get defineProceduralQuota => 'Define procedural quota';

  @override
  String get adjustProcedureTitleSubtitle =>
      'Adjust procedure title and target quota';

  @override
  String get procedureTitle => 'Procedure Title';

  @override
  String get customProcedureTitle => 'Custom Procedure Title';

  @override
  String get procedureRequirement => 'Procedure / Requirement';

  @override
  String get scheduleDateTime => 'Schedule Date & Time';

  @override
  String get appointmentStatus => 'Appointment Status';

  @override
  String get procedureAndClinicalNotes => 'Procedure & Clinical Notes';

  @override
  String get clinicalNotesOptional =>
      'Clinical Notes / Tooth Number (Optional)';

  @override
  String get pleaseSelectPatient => 'Please select a patient';

  @override
  String get pleaseSelectClinic => 'Please select a clinic';

  @override
  String get failedToLoadPatients => 'Failed to load patients';

  @override
  String get failedToLoadClinics => 'Failed to load clinics';

  @override
  String get failedToSavePatient => 'Failed to save patient';

  @override
  String get failedToSaveClinic => 'Failed to save clinic';

  @override
  String get failedToSaveAppointment => 'Failed to save appointment';

  @override
  String get failedToSaveRequirement => 'Failed to save requirement';

  @override
  String get failedToSaveCase => 'Failed to save clinical case';

  @override
  String get editClinicalCase => 'Edit Clinical Case';

  @override
  String get logClinicalCase => 'Log Clinical Case';

  @override
  String get procedureStatus => 'Procedure Status';

  @override
  String get plannedVisits => 'Planned Number of Visits (1-10)';

  @override
  String get visitMilestones => 'Visit Milestone Labels';

  @override
  String visitLabel(int number) {
    return 'Visit $number Label';
  }

  @override
  String get clinicalFindingsNotes => 'Clinical Notes / Findings';

  @override
  String get updateCaseRecord => 'Update Case Record';

  @override
  String get noRequirementsDefined =>
      'No procedural requirements defined for this clinic yet.';

  @override
  String get evaluateCaseRecord => 'Evaluate Case Record';

  @override
  String get evaluationRemarks => 'Clinical Notes & Evaluation Remarks';

  @override
  String get sortCasesAndRequirements => 'Sort Cases & Requirements';

  @override
  String get orderRequirementsSubtitle =>
      'Order clinical requirements by progression or criteria';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get wipeAllData => 'Wipe All Data';

  @override
  String get destructiveResetWarning =>
      'This action is completely destructive and irreversible. All patients, clinical requirements, logged case sheets, appointments, and user preferences will be permanently wiped from your device.';

  @override
  String get typeResetToConfirm =>
      'Type \"RESET\" in all caps below to confirm:';

  @override
  String get typeResetPlaceholder => 'Type RESET to confirm';

  @override
  String get failedToResetDatabase => 'Failed to reset database';

  @override
  String get stageProposedTreatment => 'Stage Proposed Treatment';

  @override
  String get editTreatmentPlanItem => 'Edit Treatment Plan Item';

  @override
  String get academicTreatmentPhase => 'Academic Treatment Phase';

  @override
  String get proposedTreatmentTitle => 'Proposed Procedure / Treatment Title';

  @override
  String get targetDepartmentOptional =>
      'Target Clinical Department (Optional)';

  @override
  String get treatmentStatus => 'Treatment Status';

  @override
  String get facultyInstructions => 'Clinical Notes / Faculty Instructions';

  @override
  String get updateTreatment => 'Update Treatment';

  @override
  String get stageTreatment => 'Stage Treatment';

  @override
  String get generalInterdisciplinary => 'General / Interdisciplinary';

  @override
  String get academicSupervisoryPortfolio => 'Academic Supervisory Portfolio';

  @override
  String get departmentScope => 'Department Scope';

  @override
  String get allDepartmentsAndClinics => 'All Departments & Clinics';

  @override
  String get caseDateRange => 'Case Date Range';

  @override
  String get allTimeCompleteRecord => 'All Time (Complete Record)';

  @override
  String get previewAndPrintPdf => 'Preview & Print PDF';

  @override
  String get sharePdfReport => 'Share PDF Report';

  @override
  String get exportTabularCsv => 'Export Tabular CSV (Grading Sheet)';

  @override
  String get saving => 'Saving...';

  @override
  String recordProcedureForPatient(String name) {
    return 'Record clinical procedure for $name';
  }

  @override
  String recordProcedureForPatientId(String id) {
    return 'Record clinical procedure for patient #$id';
  }

  @override
  String get noClinicsAvailable =>
      'No clinics available. Please create a clinic first.';

  @override
  String failedToLoadClinicsWithError(String error) {
    return 'Failed to load clinics: $error';
  }

  @override
  String failedToLoadRequirementsWithError(String error) {
    return 'Failed to load requirements: $error';
  }

  @override
  String get statusEvaluated => 'Evaluated';

  @override
  String get visitSingular => 'Visit';

  @override
  String get visitsPlural => 'Visits';

  @override
  String visitNumberHint(int number) {
    return 'e.g., Visit $number, Primary Impressions...';
  }

  @override
  String get clinicalNotesHint =>
      'e.g., Primary impression completed, cavity prepared Class II...';

  @override
  String get pleaseSelectRequirement =>
      'Please select a procedural requirement';

  @override
  String get failedToUpdateCase => 'Failed to update clinical case';

  @override
  String get failedToLogCase => 'Failed to log clinical case';

  @override
  String get clinicalProcedure => 'Clinical Procedure';

  @override
  String get gradeScoreOptional => 'Grade / Score (Optional)';

  @override
  String get gradeScoreHint => 'e.g., 9.0/10, Pass, A';

  @override
  String get evaluationRemarksHint =>
      'e.g., Margins well-adapted, patient tolerated procedure well...';

  @override
  String get failedToEvaluateCase => 'Failed to evaluate case record';

  @override
  String get sortByTitle => 'Name (A to Z)';

  @override
  String get sortByTitleSubtitle => 'Alphabetical order by requirement title';

  @override
  String get sortByProgress => 'Quota Progress';

  @override
  String get sortByProgressSubtitle =>
      'Highest percentage of completed cases first';

  @override
  String get sortByTargetCount => 'Target Quota';

  @override
  String get sortByTargetCountSubtitle =>
      'Highest target case requirements first';

  @override
  String patientLabel(String name) {
    return 'Patient: $name';
  }

  @override
  String get phaseEmergency => 'Phase 1: Emergency';

  @override
  String get phasePreventivePerio => 'Phase 2: Preventive / Perio';

  @override
  String get phaseRestorative => 'Phase 3: Restorative';

  @override
  String get phaseMaintenance => 'Phase 4: Maintenance';

  @override
  String get proposedTreatmentTitleHint =>
      'e.g., Scaling & Root Planing, Anterior RCT, Class II Composite';

  @override
  String get pleaseEnterTreatmentTitle =>
      'Please enter a treatment procedure title';

  @override
  String get facultyInstructionsHint =>
      'Add clinical justification, tooth numbers, or supervisor notes...';

  @override
  String get treatmentItemUpdated => 'Treatment plan item updated successfully';

  @override
  String treatmentItemStaged(int phase) {
    return 'Treatment plan item staged for Phase $phase';
  }

  @override
  String failedToSaveTreatmentPlan(String error) {
    return 'Failed to save treatment plan: $error';
  }

  @override
  String get statusProposed => 'Proposed';

  @override
  String get statusApproved => 'Approved';

  @override
  String get changeImage => 'Change Image';

  @override
  String get removeImage => 'Remove Image';

  @override
  String get pleaseSelectRadiograph =>
      'Please capture or select a radiograph image.';

  @override
  String radiographAttachedSuccess(String type) {
    return '$type radiograph attached successfully';
  }

  @override
  String failedToSaveRadiograph(String error) {
    return 'Failed to save radiograph: $error';
  }

  @override
  String get radiographicFindingsHint =>
      'e.g., Periapical radiolucency on root apex #36, crestal bone level normal...';

  @override
  String get radiographSelected => 'Radiograph Selected';

  @override
  String get clearDateFilter => 'Clear Date Filter';

  @override
  String get clinicSingular => 'Clinic';

  @override
  String get clinicsPlural => 'Clinics';

  @override
  String get requirementSingular => 'Requirement';

  @override
  String get requirementsPlural => 'Requirements';

  @override
  String get caseLogSingular => 'Case Log';

  @override
  String get caseLogsPlural => 'Case Logs';

  @override
  String get failedToGeneratePdf => 'Failed to generate PDF report';

  @override
  String get failedToSharePdf => 'Failed to share PDF report';

  @override
  String get failedToExportCsv => 'Failed to export CSV grading sheet';

  @override
  String get sort => 'Sort';

  @override
  String get updateScheduleNotesSubtitle =>
      'Update appointment schedule, status, and clinical notes';

  @override
  String get schedule => 'Schedule';

  @override
  String get nextUp => 'Next Up';

  @override
  String get schedulePatient => 'Schedule Patient';

  @override
  String get newPatient => 'New Patient';

  @override
  String get pleaseEnterPatientName => 'Please enter the patient name';

  @override
  String get patientRequired => 'Patient *';

  @override
  String get clinicDepartmentRequired => 'Clinic / Department *';

  @override
  String get loadingPatients => 'Loading patients...';

  @override
  String get loadingClinics => 'Loading clinics...';

  @override
  String get selectPatientHint => 'Select patient...';

  @override
  String get selectClinicHint => 'Select clinic...';

  @override
  String get noPatientsAvailable => 'No patients available';

  @override
  String get deleteClinics => 'Delete Clinics';

  @override
  String get deleteSelectedClinics => 'Delete Selected Clinics?';

  @override
  String get clinicsAndRequirements => 'Clinics & Requirements';

  @override
  String get noClinicsAddedYet => 'No clinics added yet';

  @override
  String noClinicsFoundInCategory(String category) {
    return 'No clinics found in \"$category\"';
  }

  @override
  String get trySelectingAllOrDifferentCategory =>
      'Try selecting \"All\" or a different clinical category.';

  @override
  String requirementsMet(int completed, int target) {
    return '$completed of $target Requirements Met';
  }

  @override
  String get sortCases => 'Sort Cases';

  @override
  String get deleteCases => 'Delete Cases';

  @override
  String percentDone(int percent) {
    return '$percent% Done';
  }

  @override
  String get noPatientsAssignedYet => 'No patients assigned yet.';

  @override
  String get tomorrowsPatients => 'Tomorrow\'s Patients';

  @override
  String get noUpcomingPatientsTomorrow =>
      'No upcoming patients scheduled for tomorrow.';

  @override
  String get viewFullSchedule => 'View Full Schedule';

  @override
  String get addFirstPatientDescription =>
      'Add your first patient to start tracking clinical requirements.';

  @override
  String get appTheme => 'App Theme';

  @override
  String get restore => 'Restore';

  @override
  String get restoreFromBackup => 'Restore from Backup';

  @override
  String get localNotifications => 'Local Notifications';

  @override
  String get dataAndOfflineBackup => 'Data & Offline Backup';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'App Version';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get attach => 'Attach';

  @override
  String get attachRadiographModalTitle => 'Attach Radiograph (X-Ray)';

  @override
  String get noAppointmentsToday => 'No appointments scheduled today';

  @override
  String get scheduledProceduresAppearHere =>
      'Scheduled clinical procedures will appear here.';

  @override
  String get reqs => 'Reqs';

  @override
  String get noActiveRequirements => 'No active requirements';

  @override
  String get chooseAppTheme => 'Choose App Theme';

  @override
  String get registerClinicalDepartments =>
      'Register your clinical departments to track quotas and case progress.';

  @override
  String defineClinicalQuotasForClinic(String clinicName) {
    return 'Define clinical quotas and procedural targets for $clinicName.';
  }

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String get restoreDatabaseBackupTitle => 'Restore Database Backup?';
}
