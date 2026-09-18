import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Dentera'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @clinics.
  ///
  /// In en, this message translates to:
  /// **'Clinics'**
  String get clinics;

  /// No description provided for @patients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patients;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as a guest'**
  String get continueAsGuest;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// Percentage completed in clinic summary card
  ///
  /// In en, this message translates to:
  /// **'{percent}% Complete'**
  String percentComplete(int percent);

  /// Remaining requirements count in clinic summary card
  ///
  /// In en, this message translates to:
  /// **'{count} requirements left'**
  String requirementsLeft(int count);

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @evaluated.
  ///
  /// In en, this message translates to:
  /// **'Evaluated'**
  String get evaluated;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get invalidNumber;

  /// No description provided for @prosthodontics.
  ///
  /// In en, this message translates to:
  /// **'Prosthodontics'**
  String get prosthodontics;

  /// No description provided for @removableProsthodontics.
  ///
  /// In en, this message translates to:
  /// **'Removable Prosthodontics'**
  String get removableProsthodontics;

  /// No description provided for @fixedProsthodontics.
  ///
  /// In en, this message translates to:
  /// **'Fixed Prosthodontics'**
  String get fixedProsthodontics;

  /// No description provided for @endodontics.
  ///
  /// In en, this message translates to:
  /// **'Endodontics'**
  String get endodontics;

  /// No description provided for @operative.
  ///
  /// In en, this message translates to:
  /// **'Operative'**
  String get operative;

  /// No description provided for @operativeDentistry.
  ///
  /// In en, this message translates to:
  /// **'Operative Dentistry'**
  String get operativeDentistry;

  /// No description provided for @oralSurgery.
  ///
  /// In en, this message translates to:
  /// **'Oral Surgery'**
  String get oralSurgery;

  /// No description provided for @orthodontics.
  ///
  /// In en, this message translates to:
  /// **'Orthodontics'**
  String get orthodontics;

  /// No description provided for @pedodontics.
  ///
  /// In en, this message translates to:
  /// **'Pedodontics'**
  String get pedodontics;

  /// No description provided for @periodontics.
  ///
  /// In en, this message translates to:
  /// **'Periodontics'**
  String get periodontics;

  /// No description provided for @oralMedicine.
  ///
  /// In en, this message translates to:
  /// **'Oral Medicine'**
  String get oralMedicine;

  /// No description provided for @completeDenture.
  ///
  /// In en, this message translates to:
  /// **'Complete Denture'**
  String get completeDenture;

  /// No description provided for @singleCompleteDenture.
  ///
  /// In en, this message translates to:
  /// **'Single Complete Denture'**
  String get singleCompleteDenture;

  /// No description provided for @rpiClaspAssembly.
  ///
  /// In en, this message translates to:
  /// **'RPI Clasp Assembly'**
  String get rpiClaspAssembly;

  /// No description provided for @rootCanalTreatment.
  ///
  /// In en, this message translates to:
  /// **'Root Canal Treatment'**
  String get rootCanalTreatment;

  /// No description provided for @classIComposite.
  ///
  /// In en, this message translates to:
  /// **'Class I Composite'**
  String get classIComposite;

  /// No description provided for @classIIComposite.
  ///
  /// In en, this message translates to:
  /// **'Class II Composite'**
  String get classIIComposite;

  /// No description provided for @simpleExtraction.
  ///
  /// In en, this message translates to:
  /// **'Simple Extraction'**
  String get simpleExtraction;

  /// No description provided for @surgicalExtraction.
  ///
  /// In en, this message translates to:
  /// **'Surgical Extraction'**
  String get surgicalExtraction;

  /// No description provided for @scalingAndRootPlaning.
  ///
  /// In en, this message translates to:
  /// **'Scaling & Root Planing'**
  String get scalingAndRootPlaning;

  /// No description provided for @pulpotomy.
  ///
  /// In en, this message translates to:
  /// **'Pulpotomy'**
  String get pulpotomy;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get upNext;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments'**
  String get noUpcomingAppointments;

  /// No description provided for @noUpcomingAppointmentsDescription.
  ///
  /// In en, this message translates to:
  /// **'You have no appointments scheduled for the next 48 hours.'**
  String get noUpcomingAppointmentsDescription;

  /// No description provided for @clinicalReminders.
  ///
  /// In en, this message translates to:
  /// **'Clinical Reminders'**
  String get clinicalReminders;

  /// No description provided for @noRemindersPending.
  ///
  /// In en, this message translates to:
  /// **'No reminders pending'**
  String get noRemindersPending;

  /// No description provided for @allClinicalTasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'All clinical follow-ups and requirement targets are up to date.'**
  String get allClinicalTasksCompleted;

  /// No description provided for @quickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get quickStats;

  /// No description provided for @activeCases.
  ///
  /// In en, this message translates to:
  /// **'Active Cases'**
  String get activeCases;

  /// No description provided for @completedCases.
  ///
  /// In en, this message translates to:
  /// **'Completed Cases'**
  String get completedCases;

  /// No description provided for @totalQuotas.
  ///
  /// In en, this message translates to:
  /// **'Total Quotas'**
  String get totalQuotas;

  /// No description provided for @upcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointments'**
  String get upcomingAppointments;

  /// No description provided for @scheduleNewAppointment.
  ///
  /// In en, this message translates to:
  /// **'Schedule New Appointment'**
  String get scheduleNewAppointment;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @overallAcademicProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Academic Progress'**
  String get overallAcademicProgress;

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get onTrack;

  /// No description provided for @needsFocus.
  ///
  /// In en, this message translates to:
  /// **'Needs Focus'**
  String get needsFocus;

  /// No description provided for @clinicalDepartments.
  ///
  /// In en, this message translates to:
  /// **'Clinical Departments'**
  String get clinicalDepartments;

  /// No description provided for @clinicalRequirements.
  ///
  /// In en, this message translates to:
  /// **'Clinical Requirements'**
  String get clinicalRequirements;

  /// No description provided for @searchClinics.
  ///
  /// In en, this message translates to:
  /// **'Search clinics...'**
  String get searchClinics;

  /// No description provided for @searchClinicsHint.
  ///
  /// In en, this message translates to:
  /// **'Search clinics by name or department...'**
  String get searchClinicsHint;

  /// No description provided for @addClinic.
  ///
  /// In en, this message translates to:
  /// **'Add Clinic'**
  String get addClinic;

  /// No description provided for @editClinic.
  ///
  /// In en, this message translates to:
  /// **'Edit Clinic'**
  String get editClinic;

  /// No description provided for @deleteClinic.
  ///
  /// In en, this message translates to:
  /// **'Delete Clinic'**
  String get deleteClinic;

  /// No description provided for @clinicName.
  ///
  /// In en, this message translates to:
  /// **'Clinic Name'**
  String get clinicName;

  /// No description provided for @targetQuota.
  ///
  /// In en, this message translates to:
  /// **'Target Quota'**
  String get targetQuota;

  /// No description provided for @targetCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Quota Count'**
  String get targetCountLabel;

  /// No description provided for @requirementTitle.
  ///
  /// In en, this message translates to:
  /// **'Requirement Title'**
  String get requirementTitle;

  /// No description provided for @addRequirement.
  ///
  /// In en, this message translates to:
  /// **'Add Requirement'**
  String get addRequirement;

  /// No description provided for @editRequirement.
  ///
  /// In en, this message translates to:
  /// **'Edit Requirement'**
  String get editRequirement;

  /// No description provided for @deleteRequirement.
  ///
  /// In en, this message translates to:
  /// **'Delete Requirement'**
  String get deleteRequirement;

  /// No description provided for @academicYear.
  ///
  /// In en, this message translates to:
  /// **'Academic Year'**
  String get academicYear;

  /// No description provided for @sortClinics.
  ///
  /// In en, this message translates to:
  /// **'Sort Clinics'**
  String get sortClinics;

  /// No description provided for @orderClinicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order clinical departments by academic criteria'**
  String get orderClinicsSubtitle;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name (A to Z)'**
  String get sortByName;

  /// No description provided for @sortByNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical order by clinic name'**
  String get sortByNameSubtitle;

  /// No description provided for @sortByAcademicYear.
  ///
  /// In en, this message translates to:
  /// **'Academic Year'**
  String get sortByAcademicYear;

  /// No description provided for @sortByAcademicYearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order by target academic year curriculum'**
  String get sortByAcademicYearSubtitle;

  /// No description provided for @sortByQuotaProgress.
  ///
  /// In en, this message translates to:
  /// **'Quota Progress'**
  String get sortByQuotaProgress;

  /// No description provided for @sortByQuotaProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Highest percentage of completed requirements first'**
  String get sortByQuotaProgressSubtitle;

  /// No description provided for @noClinicsFound.
  ///
  /// In en, this message translates to:
  /// **'No clinics found'**
  String get noClinicsFound;

  /// No description provided for @noClinicsMatching.
  ///
  /// In en, this message translates to:
  /// **'No clinical departments match search criteria'**
  String get noClinicsMatching;

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get overallProgress;

  /// No description provided for @proceduralRequirements.
  ///
  /// In en, this message translates to:
  /// **'Procedural Requirements'**
  String get proceduralRequirements;

  /// No description provided for @noRequirementsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No requirements added yet'**
  String get noRequirementsAddedYet;

  /// No description provided for @defineClinicalQuotas.
  ///
  /// In en, this message translates to:
  /// **'Define clinical quotas and procedural targets for this clinic.'**
  String get defineClinicalQuotas;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @generateQuotaReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Quota Report'**
  String get generateQuotaReport;

  /// No description provided for @casesLogged.
  ///
  /// In en, this message translates to:
  /// **'Cases Logged'**
  String get casesLogged;

  /// No description provided for @logCase.
  ///
  /// In en, this message translates to:
  /// **'Log Case'**
  String get logCase;

  /// No description provided for @logCaseRecord.
  ///
  /// In en, this message translates to:
  /// **'Log Case Record'**
  String get logCaseRecord;

  /// No description provided for @evaluateCase.
  ///
  /// In en, this message translates to:
  /// **'Evaluate Case'**
  String get evaluateCase;

  /// No description provided for @viewCases.
  ///
  /// In en, this message translates to:
  /// **'View Cases'**
  String get viewCases;

  /// No description provided for @requirementCases.
  ///
  /// In en, this message translates to:
  /// **'Requirement Cases'**
  String get requirementCases;

  /// No description provided for @noCasesLoggedYet.
  ///
  /// In en, this message translates to:
  /// **'No cases logged yet'**
  String get noCasesLoggedYet;

  /// No description provided for @noClinicalCasesLoggedYet.
  ///
  /// In en, this message translates to:
  /// **'No clinical cases logged yet'**
  String get noClinicalCasesLoggedYet;

  /// No description provided for @logCaseToMeetQuota.
  ///
  /// In en, this message translates to:
  /// **'Log clinical cases to track progress towards meeting this academic quota.'**
  String get logCaseToMeetQuota;

  /// No description provided for @deleteClinicConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this clinic? All associated requirements and records will be permanently removed.'**
  String get deleteClinicConfirmation;

  /// No description provided for @deleteRequirementConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this requirement? All logged cases under this requirement will be permanently removed.'**
  String get deleteRequirementConfirmation;

  /// No description provided for @patientRoster.
  ///
  /// In en, this message translates to:
  /// **'Patient Roster'**
  String get patientRoster;

  /// No description provided for @searchPatients.
  ///
  /// In en, this message translates to:
  /// **'Search patients...'**
  String get searchPatients;

  /// No description provided for @searchPatientsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone...'**
  String get searchPatientsHint;

  /// No description provided for @addPatient.
  ///
  /// In en, this message translates to:
  /// **'Add Patient'**
  String get addPatient;

  /// No description provided for @editPatient.
  ///
  /// In en, this message translates to:
  /// **'Edit Patient'**
  String get editPatient;

  /// No description provided for @deletePatient.
  ///
  /// In en, this message translates to:
  /// **'Delete Patient'**
  String get deletePatient;

  /// No description provided for @patientName.
  ///
  /// In en, this message translates to:
  /// **'Patient Name'**
  String get patientName;

  /// No description provided for @patientNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient Full Name'**
  String get patientNameLabel;

  /// No description provided for @patientDetails.
  ///
  /// In en, this message translates to:
  /// **'Patient Details'**
  String get patientDetails;

  /// No description provided for @patientCaseSheet.
  ///
  /// In en, this message translates to:
  /// **'Patient Case Sheet'**
  String get patientCaseSheet;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age (Years)'**
  String get ageLabel;

  /// No description provided for @medicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical History'**
  String get medicalHistory;

  /// No description provided for @medicalHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Medical History / Allergies'**
  String get medicalHistoryLabel;

  /// No description provided for @dentalHistory.
  ///
  /// In en, this message translates to:
  /// **'Dental History'**
  String get dentalHistory;

  /// No description provided for @dentalHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Dental History / Chief Complaint'**
  String get dentalHistoryLabel;

  /// No description provided for @patientHistory.
  ///
  /// In en, this message translates to:
  /// **'Patient History'**
  String get patientHistory;

  /// No description provided for @casesAndProcedures.
  ///
  /// In en, this message translates to:
  /// **'Cases & Procedures'**
  String get casesAndProcedures;

  /// No description provided for @caseHistory.
  ///
  /// In en, this message translates to:
  /// **'Case History'**
  String get caseHistory;

  /// No description provided for @treatmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Treatment Plan'**
  String get treatmentPlan;

  /// No description provided for @treatmentPlanPhases.
  ///
  /// In en, this message translates to:
  /// **'Treatment Plan Phases'**
  String get treatmentPlanPhases;

  /// No description provided for @addTreatmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Add Treatment Plan'**
  String get addTreatmentPlan;

  /// No description provided for @addTreatmentPlanItem.
  ///
  /// In en, this message translates to:
  /// **'Add Treatment Item'**
  String get addTreatmentPlanItem;

  /// No description provided for @noTreatmentPlanItems.
  ///
  /// In en, this message translates to:
  /// **'No treatment plan items added yet'**
  String get noTreatmentPlanItems;

  /// No description provided for @addTreatmentPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a structured phased dental treatment plan for this patient.'**
  String get addTreatmentPlanDescription;

  /// No description provided for @radiographs.
  ///
  /// In en, this message translates to:
  /// **'Radiographs'**
  String get radiographs;

  /// No description provided for @radiographsTitle.
  ///
  /// In en, this message translates to:
  /// **'Radiographs (X-Rays)'**
  String get radiographsTitle;

  /// No description provided for @attachXRay.
  ///
  /// In en, this message translates to:
  /// **'Attach X-Ray'**
  String get attachXRay;

  /// No description provided for @attachRadiograph.
  ///
  /// In en, this message translates to:
  /// **'Attach Radiograph'**
  String get attachRadiograph;

  /// No description provided for @noRadiographsAttached.
  ///
  /// In en, this message translates to:
  /// **'No radiographs attached'**
  String get noRadiographsAttached;

  /// No description provided for @attachRadiographDescription.
  ///
  /// In en, this message translates to:
  /// **'Attach periapical, bitewing, or panoramic X-rays for offline diagnostic review.'**
  String get attachRadiographDescription;

  /// No description provided for @radiographImage.
  ///
  /// In en, this message translates to:
  /// **'Radiograph Image'**
  String get radiographImage;

  /// No description provided for @importRadiograph.
  ///
  /// In en, this message translates to:
  /// **'Import radiographic X-ray'**
  String get importRadiograph;

  /// No description provided for @cameraOrGallery.
  ///
  /// In en, this message translates to:
  /// **'Supports Camera capture or Photo Gallery import'**
  String get cameraOrGallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @projectionType.
  ///
  /// In en, this message translates to:
  /// **'Projection Type'**
  String get projectionType;

  /// No description provided for @periapical.
  ///
  /// In en, this message translates to:
  /// **'Periapical'**
  String get periapical;

  /// No description provided for @bitewing.
  ///
  /// In en, this message translates to:
  /// **'Bitewing'**
  String get bitewing;

  /// No description provided for @panoramic.
  ///
  /// In en, this message translates to:
  /// **'Panoramic'**
  String get panoramic;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @captureDate.
  ///
  /// In en, this message translates to:
  /// **'Capture Date'**
  String get captureDate;

  /// No description provided for @radiographicFindings.
  ///
  /// In en, this message translates to:
  /// **'Radiographic Findings / Notes'**
  String get radiographicFindings;

  /// No description provided for @noPatientsFound.
  ///
  /// In en, this message translates to:
  /// **'No patients found'**
  String get noPatientsFound;

  /// No description provided for @noPatientsRegisteredYet.
  ///
  /// In en, this message translates to:
  /// **'No patients registered yet'**
  String get noPatientsRegisteredYet;

  /// No description provided for @startAddingPatients.
  ///
  /// In en, this message translates to:
  /// **'Start adding patients to manage treatments, appointments, and case histories.'**
  String get startAddingPatients;

  /// No description provided for @sortPatients.
  ///
  /// In en, this message translates to:
  /// **'Sort Patients'**
  String get sortPatients;

  /// No description provided for @orderPatientsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order patient roster by clinical criteria'**
  String get orderPatientsSubtitle;

  /// No description provided for @sortByDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date Added (Recent first)'**
  String get sortByDateAdded;

  /// No description provided for @sortByDateAddedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order by newest registered patient'**
  String get sortByDateAddedSubtitle;

  /// No description provided for @sortByActiveCases.
  ///
  /// In en, this message translates to:
  /// **'Active Case Count'**
  String get sortByActiveCases;

  /// No description provided for @sortByActiveCasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prioritize patients with in-progress clinical procedures'**
  String get sortByActiveCasesSubtitle;

  /// No description provided for @deletePatientConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this patient? All case records, appointments, radiographs, and treatment plans will be permanently deleted.'**
  String get deletePatientConfirmation;

  /// No description provided for @scheduleAppointment.
  ///
  /// In en, this message translates to:
  /// **'Schedule Appointment'**
  String get scheduleAppointment;

  /// No description provided for @editAppointment.
  ///
  /// In en, this message translates to:
  /// **'Edit Appointment'**
  String get editAppointment;

  /// No description provided for @deleteAppointment.
  ///
  /// In en, this message translates to:
  /// **'Delete Appointment'**
  String get deleteAppointment;

  /// No description provided for @cancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointment;

  /// No description provided for @selectClinic.
  ///
  /// In en, this message translates to:
  /// **'Select Clinic'**
  String get selectClinic;

  /// No description provided for @selectPatient.
  ///
  /// In en, this message translates to:
  /// **'Select Patient'**
  String get selectPatient;

  /// No description provided for @noAppointmentsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No appointments scheduled'**
  String get noAppointmentsScheduled;

  /// No description provided for @noAppointmentsForDate.
  ///
  /// In en, this message translates to:
  /// **'No appointments for this date'**
  String get noAppointmentsForDate;

  /// No description provided for @allClinics.
  ///
  /// In en, this message translates to:
  /// **'All Clinics'**
  String get allClinics;

  /// No description provided for @filterByClinic.
  ///
  /// In en, this message translates to:
  /// **'Filter by Clinic'**
  String get filterByClinic;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @doctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Doctor Profile'**
  String get doctorProfile;

  /// No description provided for @academicProfile.
  ///
  /// In en, this message translates to:
  /// **'Academic Profile'**
  String get academicProfile;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية (Arabic)'**
  String get arabic;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @patientFollowUpAlerts.
  ///
  /// In en, this message translates to:
  /// **'Patient Follow-up Alerts'**
  String get patientFollowUpAlerts;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @backupAndDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Backup & Data Management'**
  String get backupAndDataManagement;

  /// No description provided for @exportLocalBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Local Backup'**
  String get exportLocalBackup;

  /// No description provided for @restoreDatabase.
  ///
  /// In en, this message translates to:
  /// **'Restore Database'**
  String get restoreDatabase;

  /// No description provided for @resetAllData.
  ///
  /// In en, this message translates to:
  /// **'Reset All Data'**
  String get resetAllData;

  /// No description provided for @resetDatabaseConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all clinical data? This action cannot be undone and will restore default seeded clinics.'**
  String get resetDatabaseConfirmation;

  /// No description provided for @aboutDentera.
  ///
  /// In en, this message translates to:
  /// **'About Dentera'**
  String get aboutDentera;

  /// No description provided for @denteraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clinical dental education tracker for students and clinics'**
  String get denteraSubtitle;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @welcomeDoctor.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Doctor.'**
  String get welcomeDoctor;

  /// No description provided for @setupClinicalWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your clinical workspace. What\'s your name?'**
  String get setupClinicalWorkspace;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @yourInstitution.
  ///
  /// In en, this message translates to:
  /// **'Your Institution'**
  String get yourInstitution;

  /// No description provided for @universityOrSchool.
  ///
  /// In en, this message translates to:
  /// **'University / School'**
  String get universityOrSchool;

  /// No description provided for @clinicalYear.
  ///
  /// In en, this message translates to:
  /// **'Clinical Year'**
  String get clinicalYear;

  /// No description provided for @enterWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Enter Workspace'**
  String get enterWorkspace;

  /// No description provided for @supervisorName.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Name'**
  String get supervisorName;

  /// No description provided for @gradeScore.
  ///
  /// In en, this message translates to:
  /// **'Grade / Score'**
  String get gradeScore;

  /// No description provided for @supervisorFeedback.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Feedback'**
  String get supervisorFeedback;

  /// No description provided for @toothNumberRegion.
  ///
  /// In en, this message translates to:
  /// **'Tooth Number / Region'**
  String get toothNumberRegion;

  /// No description provided for @phase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get phase;

  /// No description provided for @procedure.
  ///
  /// In en, this message translates to:
  /// **'Procedure'**
  String get procedure;

  /// No description provided for @estimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated Cost'**
  String get estimatedCost;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String selectedCount(int count);

  /// No description provided for @deleteSelectedPatients.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Patients?'**
  String get deleteSelectedPatients;

  /// No description provided for @deleteSelectedPatientsMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting selected patients will permanently remove all associated clinical case records and scheduled appointments. This action cannot be undone. Are you sure you want to proceed?'**
  String get deleteSelectedPatientsMessage;

  /// No description provided for @deleteCount.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String deleteCount(int count);

  /// No description provided for @deletePatients.
  ///
  /// In en, this message translates to:
  /// **'Delete Patients'**
  String get deletePatients;

  /// No description provided for @addFirstPatient.
  ///
  /// In en, this message translates to:
  /// **'Add First Patient'**
  String get addFirstPatient;

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'No Phone'**
  String get noPhone;

  /// No description provided for @medicalAlert.
  ///
  /// In en, this message translates to:
  /// **'Medical Alert'**
  String get medicalAlert;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @clinicalCases.
  ///
  /// In en, this message translates to:
  /// **'Clinical Cases'**
  String get clinicalCases;

  /// No description provided for @laterToday.
  ///
  /// In en, this message translates to:
  /// **'Later Today'**
  String get laterToday;

  /// No description provided for @openCaseSheet.
  ///
  /// In en, this message translates to:
  /// **'Open Case Sheet'**
  String get openCaseSheet;

  /// No description provided for @appointmentActions.
  ///
  /// In en, this message translates to:
  /// **'Appointment actions'**
  String get appointmentActions;

  /// No description provided for @appointmentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Appointment deleted'**
  String get appointmentDeleted;

  /// No description provided for @caseRecordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Case record deleted'**
  String get caseRecordDeleted;

  /// No description provided for @deleteCaseRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Case Record'**
  String get deleteCaseRecord;

  /// No description provided for @deleteCaseRecordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this case record? If this case was marked as completed, your requirement completed count will automatically be decremented.'**
  String get deleteCaseRecordConfirmation;

  /// No description provided for @logFirstCase.
  ///
  /// In en, this message translates to:
  /// **'Log First Case'**
  String get logFirstCase;

  /// No description provided for @startLoggingCases.
  ///
  /// In en, this message translates to:
  /// **'Start logging procedural cases and treatments completed for {name}.'**
  String startLoggingCases(String name);

  /// No description provided for @chiefComplaint.
  ///
  /// In en, this message translates to:
  /// **'Chief Complaint (CC)'**
  String get chiefComplaint;

  /// No description provided for @historyOfChiefComplaint.
  ///
  /// In en, this message translates to:
  /// **'History of Chief Complaint (HCC)'**
  String get historyOfChiefComplaint;

  /// No description provided for @medicalHistoryAndAllergies.
  ///
  /// In en, this message translates to:
  /// **'Medical History & Allergies'**
  String get medicalHistoryAndAllergies;

  /// No description provided for @currentMedications.
  ///
  /// In en, this message translates to:
  /// **'Current Medications'**
  String get currentMedications;

  /// No description provided for @diagnosticAids.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic Aids'**
  String get diagnosticAids;

  /// No description provided for @restoreDatabaseConfirmationDetailed.
  ///
  /// In en, this message translates to:
  /// **'Restoring a database will overwrite your current clinical data, patients, and quotas with the selected backup file.\n\nAre you sure you want to proceed?'**
  String get restoreDatabaseConfirmationDetailed;

  /// No description provided for @allClinicalDataReset.
  ///
  /// In en, this message translates to:
  /// **'All clinical data and preferences have been successfully reset.'**
  String get allClinicalDataReset;

  /// No description provided for @agendaReminders.
  ///
  /// In en, this message translates to:
  /// **'Next-Day Agenda Reminders'**
  String get agendaReminders;

  /// No description provided for @exportBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save an encrypted SQLite copy to your device'**
  String get exportBackupSubtitle;

  /// No description provided for @restoreBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import data from a local backup file'**
  String get restoreBackupSubtitle;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacyAndSecurity;

  /// No description provided for @onDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'100% On-Device'**
  String get onDeviceOnly;

  /// No description provided for @resetAllClinicalData.
  ///
  /// In en, this message translates to:
  /// **'Reset All Clinical Data'**
  String get resetAllClinicalData;

  /// No description provided for @assignToClinic.
  ///
  /// In en, this message translates to:
  /// **'Assign to Clinic'**
  String get assignToClinic;

  /// No description provided for @mainCaseProcedure.
  ///
  /// In en, this message translates to:
  /// **'Main Case / Procedure'**
  String get mainCaseProcedure;

  /// No description provided for @selectMainProcedure.
  ///
  /// In en, this message translates to:
  /// **'Select main case / procedure'**
  String get selectMainProcedure;

  /// No description provided for @addContactAndDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Add Contact & Details (Optional)'**
  String get addContactAndDetailsOptional;

  /// No description provided for @pleaseSelectMainProcedure.
  ///
  /// In en, this message translates to:
  /// **'Please select a main case / procedure'**
  String get pleaseSelectMainProcedure;

  /// No description provided for @savePatient.
  ///
  /// In en, this message translates to:
  /// **'Save Patient'**
  String get savePatient;

  /// No description provided for @saveClinic.
  ///
  /// In en, this message translates to:
  /// **'Save Clinic'**
  String get saveClinic;

  /// No description provided for @saveRequirement.
  ///
  /// In en, this message translates to:
  /// **'Save Requirement'**
  String get saveRequirement;

  /// No description provided for @saveAppointment.
  ///
  /// In en, this message translates to:
  /// **'Save Appointment'**
  String get saveAppointment;

  /// No description provided for @saveEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Save Evaluation'**
  String get saveEvaluation;

  /// No description provided for @addDentalClinic.
  ///
  /// In en, this message translates to:
  /// **'Add Dental Clinic'**
  String get addDentalClinic;

  /// No description provided for @createClinicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new clinical department to track quotas'**
  String get createClinicSubtitle;

  /// No description provided for @editClinicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update clinic name, curriculum, and color theme'**
  String get editClinicSubtitle;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @departmentThemeColor.
  ///
  /// In en, this message translates to:
  /// **'Department Theme Color'**
  String get departmentThemeColor;

  /// No description provided for @editPatientProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Patient Profile'**
  String get editPatientProfile;

  /// No description provided for @updateDemographicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update demographics and medical history'**
  String get updateDemographicsSubtitle;

  /// No description provided for @clinicalAnamnesisHistory.
  ///
  /// In en, this message translates to:
  /// **'Clinical Anamnesis / History'**
  String get clinicalAnamnesisHistory;

  /// No description provided for @defineProceduralQuota.
  ///
  /// In en, this message translates to:
  /// **'Define procedural quota'**
  String get defineProceduralQuota;

  /// No description provided for @adjustProcedureTitleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust procedure title and target quota'**
  String get adjustProcedureTitleSubtitle;

  /// No description provided for @procedureTitle.
  ///
  /// In en, this message translates to:
  /// **'Procedure Title'**
  String get procedureTitle;

  /// No description provided for @customProcedureTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Procedure Title'**
  String get customProcedureTitle;

  /// No description provided for @procedureRequirement.
  ///
  /// In en, this message translates to:
  /// **'Procedure / Requirement'**
  String get procedureRequirement;

  /// No description provided for @scheduleDateTime.
  ///
  /// In en, this message translates to:
  /// **'Schedule Date & Time'**
  String get scheduleDateTime;

  /// No description provided for @appointmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Appointment Status'**
  String get appointmentStatus;

  /// No description provided for @procedureAndClinicalNotes.
  ///
  /// In en, this message translates to:
  /// **'Procedure & Clinical Notes'**
  String get procedureAndClinicalNotes;

  /// No description provided for @clinicalNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Clinical Notes / Tooth Number (Optional)'**
  String get clinicalNotesOptional;

  /// No description provided for @pleaseSelectPatient.
  ///
  /// In en, this message translates to:
  /// **'Please select a patient'**
  String get pleaseSelectPatient;

  /// No description provided for @pleaseSelectClinic.
  ///
  /// In en, this message translates to:
  /// **'Please select a clinic'**
  String get pleaseSelectClinic;

  /// No description provided for @failedToLoadPatients.
  ///
  /// In en, this message translates to:
  /// **'Failed to load patients'**
  String get failedToLoadPatients;

  /// No description provided for @failedToLoadClinics.
  ///
  /// In en, this message translates to:
  /// **'Failed to load clinics'**
  String get failedToLoadClinics;

  /// No description provided for @failedToSavePatient.
  ///
  /// In en, this message translates to:
  /// **'Failed to save patient'**
  String get failedToSavePatient;

  /// No description provided for @failedToSaveClinic.
  ///
  /// In en, this message translates to:
  /// **'Failed to save clinic'**
  String get failedToSaveClinic;

  /// No description provided for @failedToSaveAppointment.
  ///
  /// In en, this message translates to:
  /// **'Failed to save appointment'**
  String get failedToSaveAppointment;

  /// No description provided for @failedToSaveRequirement.
  ///
  /// In en, this message translates to:
  /// **'Failed to save requirement'**
  String get failedToSaveRequirement;

  /// No description provided for @failedToSaveCase.
  ///
  /// In en, this message translates to:
  /// **'Failed to save clinical case'**
  String get failedToSaveCase;

  /// No description provided for @editClinicalCase.
  ///
  /// In en, this message translates to:
  /// **'Edit Clinical Case'**
  String get editClinicalCase;

  /// No description provided for @logClinicalCase.
  ///
  /// In en, this message translates to:
  /// **'Log Clinical Case'**
  String get logClinicalCase;

  /// No description provided for @procedureStatus.
  ///
  /// In en, this message translates to:
  /// **'Procedure Status'**
  String get procedureStatus;

  /// No description provided for @plannedVisits.
  ///
  /// In en, this message translates to:
  /// **'Planned Number of Visits (1-10)'**
  String get plannedVisits;

  /// No description provided for @visitMilestones.
  ///
  /// In en, this message translates to:
  /// **'Visit Milestone Labels'**
  String get visitMilestones;

  /// No description provided for @visitLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit {number} Label'**
  String visitLabel(int number);

  /// No description provided for @clinicalFindingsNotes.
  ///
  /// In en, this message translates to:
  /// **'Clinical Notes / Findings'**
  String get clinicalFindingsNotes;

  /// No description provided for @updateCaseRecord.
  ///
  /// In en, this message translates to:
  /// **'Update Case Record'**
  String get updateCaseRecord;

  /// No description provided for @noRequirementsDefined.
  ///
  /// In en, this message translates to:
  /// **'No procedural requirements defined for this clinic yet.'**
  String get noRequirementsDefined;

  /// No description provided for @evaluateCaseRecord.
  ///
  /// In en, this message translates to:
  /// **'Evaluate Case Record'**
  String get evaluateCaseRecord;

  /// No description provided for @evaluationRemarks.
  ///
  /// In en, this message translates to:
  /// **'Clinical Notes & Evaluation Remarks'**
  String get evaluationRemarks;

  /// No description provided for @sortCasesAndRequirements.
  ///
  /// In en, this message translates to:
  /// **'Sort Cases & Requirements'**
  String get sortCasesAndRequirements;

  /// No description provided for @orderRequirementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order clinical requirements by progression or criteria'**
  String get orderRequirementsSubtitle;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @wipeAllData.
  ///
  /// In en, this message translates to:
  /// **'Wipe All Data'**
  String get wipeAllData;

  /// No description provided for @destructiveResetWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is completely destructive and irreversible. All patients, clinical requirements, logged case sheets, appointments, and user preferences will be permanently wiped from your device.'**
  String get destructiveResetWarning;

  /// No description provided for @typeResetToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \"RESET\" in all caps below to confirm:'**
  String get typeResetToConfirm;

  /// No description provided for @typeResetPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type RESET to confirm'**
  String get typeResetPlaceholder;

  /// No description provided for @failedToResetDatabase.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset database'**
  String get failedToResetDatabase;

  /// No description provided for @stageProposedTreatment.
  ///
  /// In en, this message translates to:
  /// **'Stage Proposed Treatment'**
  String get stageProposedTreatment;

  /// No description provided for @editTreatmentPlanItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Treatment Plan Item'**
  String get editTreatmentPlanItem;

  /// No description provided for @academicTreatmentPhase.
  ///
  /// In en, this message translates to:
  /// **'Academic Treatment Phase'**
  String get academicTreatmentPhase;

  /// No description provided for @proposedTreatmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Proposed Procedure / Treatment Title'**
  String get proposedTreatmentTitle;

  /// No description provided for @targetDepartmentOptional.
  ///
  /// In en, this message translates to:
  /// **'Target Clinical Department (Optional)'**
  String get targetDepartmentOptional;

  /// No description provided for @treatmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Treatment Status'**
  String get treatmentStatus;

  /// No description provided for @facultyInstructions.
  ///
  /// In en, this message translates to:
  /// **'Clinical Notes / Faculty Instructions'**
  String get facultyInstructions;

  /// No description provided for @updateTreatment.
  ///
  /// In en, this message translates to:
  /// **'Update Treatment'**
  String get updateTreatment;

  /// No description provided for @stageTreatment.
  ///
  /// In en, this message translates to:
  /// **'Stage Treatment'**
  String get stageTreatment;

  /// No description provided for @generalInterdisciplinary.
  ///
  /// In en, this message translates to:
  /// **'General / Interdisciplinary'**
  String get generalInterdisciplinary;

  /// No description provided for @academicSupervisoryPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Academic Supervisory Portfolio'**
  String get academicSupervisoryPortfolio;

  /// No description provided for @departmentScope.
  ///
  /// In en, this message translates to:
  /// **'Department Scope'**
  String get departmentScope;

  /// No description provided for @allDepartmentsAndClinics.
  ///
  /// In en, this message translates to:
  /// **'All Departments & Clinics'**
  String get allDepartmentsAndClinics;

  /// No description provided for @caseDateRange.
  ///
  /// In en, this message translates to:
  /// **'Case Date Range'**
  String get caseDateRange;

  /// No description provided for @allTimeCompleteRecord.
  ///
  /// In en, this message translates to:
  /// **'All Time (Complete Record)'**
  String get allTimeCompleteRecord;

  /// No description provided for @previewAndPrintPdf.
  ///
  /// In en, this message translates to:
  /// **'Preview & Print PDF'**
  String get previewAndPrintPdf;

  /// No description provided for @sharePdfReport.
  ///
  /// In en, this message translates to:
  /// **'Share PDF Report'**
  String get sharePdfReport;

  /// No description provided for @exportTabularCsv.
  ///
  /// In en, this message translates to:
  /// **'Export Tabular CSV (Grading Sheet)'**
  String get exportTabularCsv;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @recordProcedureForPatient.
  ///
  /// In en, this message translates to:
  /// **'Record clinical procedure for {name}'**
  String recordProcedureForPatient(String name);

  /// No description provided for @recordProcedureForPatientId.
  ///
  /// In en, this message translates to:
  /// **'Record clinical procedure for patient #{id}'**
  String recordProcedureForPatientId(String id);

  /// No description provided for @noClinicsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No clinics available. Please create a clinic first.'**
  String get noClinicsAvailable;

  /// No description provided for @failedToLoadClinicsWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load clinics: {error}'**
  String failedToLoadClinicsWithError(String error);

  /// No description provided for @failedToLoadRequirementsWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load requirements: {error}'**
  String failedToLoadRequirementsWithError(String error);

  /// No description provided for @statusEvaluated.
  ///
  /// In en, this message translates to:
  /// **'Evaluated'**
  String get statusEvaluated;

  /// No description provided for @visitSingular.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get visitSingular;

  /// No description provided for @visitsPlural.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get visitsPlural;

  /// No description provided for @visitNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Visit {number}, Primary Impressions...'**
  String visitNumberHint(int number);

  /// No description provided for @clinicalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Primary impression completed, cavity prepared Class II...'**
  String get clinicalNotesHint;

  /// No description provided for @pleaseSelectRequirement.
  ///
  /// In en, this message translates to:
  /// **'Please select a procedural requirement'**
  String get pleaseSelectRequirement;

  /// No description provided for @failedToUpdateCase.
  ///
  /// In en, this message translates to:
  /// **'Failed to update clinical case'**
  String get failedToUpdateCase;

  /// No description provided for @failedToLogCase.
  ///
  /// In en, this message translates to:
  /// **'Failed to log clinical case'**
  String get failedToLogCase;

  /// No description provided for @clinicalProcedure.
  ///
  /// In en, this message translates to:
  /// **'Clinical Procedure'**
  String get clinicalProcedure;

  /// No description provided for @gradeScoreOptional.
  ///
  /// In en, this message translates to:
  /// **'Grade / Score (Optional)'**
  String get gradeScoreOptional;

  /// No description provided for @gradeScoreHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 9.0/10, Pass, A'**
  String get gradeScoreHint;

  /// No description provided for @evaluationRemarksHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Margins well-adapted, patient tolerated procedure well...'**
  String get evaluationRemarksHint;

  /// No description provided for @failedToEvaluateCase.
  ///
  /// In en, this message translates to:
  /// **'Failed to evaluate case record'**
  String get failedToEvaluateCase;

  /// No description provided for @sortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Name (A to Z)'**
  String get sortByTitle;

  /// No description provided for @sortByTitleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical order by requirement title'**
  String get sortByTitleSubtitle;

  /// No description provided for @sortByProgress.
  ///
  /// In en, this message translates to:
  /// **'Quota Progress'**
  String get sortByProgress;

  /// No description provided for @sortByProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Highest percentage of completed cases first'**
  String get sortByProgressSubtitle;

  /// No description provided for @sortByTargetCount.
  ///
  /// In en, this message translates to:
  /// **'Target Quota'**
  String get sortByTargetCount;

  /// No description provided for @sortByTargetCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Highest target case requirements first'**
  String get sortByTargetCountSubtitle;

  /// No description provided for @patientLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient: {name}'**
  String patientLabel(String name);

  /// No description provided for @phaseEmergency.
  ///
  /// In en, this message translates to:
  /// **'Phase 1: Emergency'**
  String get phaseEmergency;

  /// No description provided for @phasePreventivePerio.
  ///
  /// In en, this message translates to:
  /// **'Phase 2: Preventive / Perio'**
  String get phasePreventivePerio;

  /// No description provided for @phaseRestorative.
  ///
  /// In en, this message translates to:
  /// **'Phase 3: Restorative'**
  String get phaseRestorative;

  /// No description provided for @phaseMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Phase 4: Maintenance'**
  String get phaseMaintenance;

  /// No description provided for @proposedTreatmentTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Scaling & Root Planing, Anterior RCT, Class II Composite'**
  String get proposedTreatmentTitleHint;

  /// No description provided for @pleaseEnterTreatmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a treatment procedure title'**
  String get pleaseEnterTreatmentTitle;

  /// No description provided for @facultyInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'Add clinical justification, tooth numbers, or supervisor notes...'**
  String get facultyInstructionsHint;

  /// No description provided for @treatmentItemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Treatment plan item updated successfully'**
  String get treatmentItemUpdated;

  /// No description provided for @treatmentItemStaged.
  ///
  /// In en, this message translates to:
  /// **'Treatment plan item staged for Phase {phase}'**
  String treatmentItemStaged(int phase);

  /// No description provided for @failedToSaveTreatmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Failed to save treatment plan: {error}'**
  String failedToSaveTreatmentPlan(String error);

  /// No description provided for @statusProposed.
  ///
  /// In en, this message translates to:
  /// **'Proposed'**
  String get statusProposed;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get removeImage;

  /// No description provided for @pleaseSelectRadiograph.
  ///
  /// In en, this message translates to:
  /// **'Please capture or select a radiograph image.'**
  String get pleaseSelectRadiograph;

  /// No description provided for @radiographAttachedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{type} radiograph attached successfully'**
  String radiographAttachedSuccess(String type);

  /// No description provided for @failedToSaveRadiograph.
  ///
  /// In en, this message translates to:
  /// **'Failed to save radiograph: {error}'**
  String failedToSaveRadiograph(String error);

  /// No description provided for @radiographicFindingsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Periapical radiolucency on root apex #36, crestal bone level normal...'**
  String get radiographicFindingsHint;

  /// No description provided for @radiographSelected.
  ///
  /// In en, this message translates to:
  /// **'Radiograph Selected'**
  String get radiographSelected;

  /// No description provided for @clearDateFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Date Filter'**
  String get clearDateFilter;

  /// No description provided for @clinicSingular.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get clinicSingular;

  /// No description provided for @clinicsPlural.
  ///
  /// In en, this message translates to:
  /// **'Clinics'**
  String get clinicsPlural;

  /// No description provided for @requirementSingular.
  ///
  /// In en, this message translates to:
  /// **'Requirement'**
  String get requirementSingular;

  /// No description provided for @requirementsPlural.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get requirementsPlural;

  /// No description provided for @caseLogSingular.
  ///
  /// In en, this message translates to:
  /// **'Case Log'**
  String get caseLogSingular;

  /// No description provided for @caseLogsPlural.
  ///
  /// In en, this message translates to:
  /// **'Case Logs'**
  String get caseLogsPlural;

  /// No description provided for @failedToGeneratePdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate PDF report'**
  String get failedToGeneratePdf;

  /// No description provided for @failedToSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to share PDF report'**
  String get failedToSharePdf;

  /// No description provided for @failedToExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Failed to export CSV grading sheet'**
  String get failedToExportCsv;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @updateScheduleNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update appointment schedule, status, and clinical notes'**
  String get updateScheduleNotesSubtitle;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @nextUp.
  ///
  /// In en, this message translates to:
  /// **'Next Up'**
  String get nextUp;

  /// No description provided for @schedulePatient.
  ///
  /// In en, this message translates to:
  /// **'Schedule Patient'**
  String get schedulePatient;

  /// No description provided for @newPatient.
  ///
  /// In en, this message translates to:
  /// **'New Patient'**
  String get newPatient;

  /// No description provided for @pleaseEnterPatientName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the patient name'**
  String get pleaseEnterPatientName;

  /// No description provided for @patientRequired.
  ///
  /// In en, this message translates to:
  /// **'Patient *'**
  String get patientRequired;

  /// No description provided for @clinicDepartmentRequired.
  ///
  /// In en, this message translates to:
  /// **'Clinic / Department *'**
  String get clinicDepartmentRequired;

  /// No description provided for @loadingPatients.
  ///
  /// In en, this message translates to:
  /// **'Loading patients...'**
  String get loadingPatients;

  /// No description provided for @loadingClinics.
  ///
  /// In en, this message translates to:
  /// **'Loading clinics...'**
  String get loadingClinics;

  /// No description provided for @selectPatientHint.
  ///
  /// In en, this message translates to:
  /// **'Select patient...'**
  String get selectPatientHint;

  /// No description provided for @selectClinicHint.
  ///
  /// In en, this message translates to:
  /// **'Select clinic...'**
  String get selectClinicHint;

  /// No description provided for @noPatientsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No patients available'**
  String get noPatientsAvailable;

  /// No description provided for @deleteClinics.
  ///
  /// In en, this message translates to:
  /// **'Delete Clinics'**
  String get deleteClinics;

  /// No description provided for @deleteSelectedClinics.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Clinics?'**
  String get deleteSelectedClinics;

  /// No description provided for @clinicsAndRequirements.
  ///
  /// In en, this message translates to:
  /// **'Clinics & Requirements'**
  String get clinicsAndRequirements;

  /// No description provided for @noClinicsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No clinics added yet'**
  String get noClinicsAddedYet;

  /// No description provided for @noClinicsFoundInCategory.
  ///
  /// In en, this message translates to:
  /// **'No clinics found in \"{category}\"'**
  String noClinicsFoundInCategory(String category);

  /// No description provided for @trySelectingAllOrDifferentCategory.
  ///
  /// In en, this message translates to:
  /// **'Try selecting \"All\" or a different clinical category.'**
  String get trySelectingAllOrDifferentCategory;

  /// No description provided for @requirementsMet.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {target} Requirements Met'**
  String requirementsMet(int completed, int target);

  /// No description provided for @sortCases.
  ///
  /// In en, this message translates to:
  /// **'Sort Cases'**
  String get sortCases;

  /// No description provided for @deleteCases.
  ///
  /// In en, this message translates to:
  /// **'Delete Cases'**
  String get deleteCases;

  /// No description provided for @percentDone.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Done'**
  String percentDone(int percent);

  /// No description provided for @noPatientsAssignedYet.
  ///
  /// In en, this message translates to:
  /// **'No patients assigned yet.'**
  String get noPatientsAssignedYet;

  /// No description provided for @tomorrowsPatients.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s Patients'**
  String get tomorrowsPatients;

  /// No description provided for @noUpcomingPatientsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'No upcoming patients scheduled for tomorrow.'**
  String get noUpcomingPatientsTomorrow;

  /// No description provided for @viewFullSchedule.
  ///
  /// In en, this message translates to:
  /// **'View Full Schedule'**
  String get viewFullSchedule;

  /// No description provided for @addFirstPatientDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first patient to start tracking clinical requirements.'**
  String get addFirstPatientDescription;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appTheme;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreFromBackup;

  /// No description provided for @localNotifications.
  ///
  /// In en, this message translates to:
  /// **'Local Notifications'**
  String get localNotifications;

  /// No description provided for @dataAndOfflineBackup.
  ///
  /// In en, this message translates to:
  /// **'Data & Offline Backup'**
  String get dataAndOfflineBackup;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @attach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get attach;

  /// No description provided for @attachRadiographModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach Radiograph (X-Ray)'**
  String get attachRadiographModalTitle;

  /// No description provided for @noAppointmentsToday.
  ///
  /// In en, this message translates to:
  /// **'No appointments scheduled today'**
  String get noAppointmentsToday;

  /// No description provided for @scheduledProceduresAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Scheduled clinical procedures will appear here.'**
  String get scheduledProceduresAppearHere;

  /// No description provided for @reqs.
  ///
  /// In en, this message translates to:
  /// **'Reqs'**
  String get reqs;

  /// No description provided for @noActiveRequirements.
  ///
  /// In en, this message translates to:
  /// **'No active requirements'**
  String get noActiveRequirements;

  /// No description provided for @chooseAppTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose App Theme'**
  String get chooseAppTheme;

  /// No description provided for @registerClinicalDepartments.
  ///
  /// In en, this message translates to:
  /// **'Register your clinical departments to track quotas and case progress.'**
  String get registerClinicalDepartments;

  /// No description provided for @defineClinicalQuotasForClinic.
  ///
  /// In en, this message translates to:
  /// **'Define clinical quotas and procedural targets for {clinicName}.'**
  String defineClinicalQuotasForClinic(String clinicName);

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteSelected;

  /// No description provided for @restoreDatabaseBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Database Backup?'**
  String get restoreDatabaseBackupTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
