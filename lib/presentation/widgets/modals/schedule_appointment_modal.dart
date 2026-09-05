import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../dentera_snackbar.dart';
import '../inputs/inputs.dart';

/// Bottom sheet modal to schedule clinical appointments with patients.
///
/// Reactively watches [patientListProvider] and [clinicListProvider] to populate
/// dynamic dropdown selectors with active database records, ensuring extracted
/// relational keys ([patientId] and [clinicId]) adhere strictly to SQLite foreign
/// key constraints without mock fallbacks or orphaned entries.
class ScheduleAppointmentModal extends ConsumerStatefulWidget {
  const ScheduleAppointmentModal({
    super.key,
    this.initialDate,
    this.onAppointmentScheduled,
    this.referenceDateTime,
  });

  final DateTime? initialDate;
  final ValueChanged<Appointment>? onAppointmentScheduled;
  final DateTime? referenceDateTime;

  /// Convenience static method to show the ScheduleAppointmentModal.
  static Future<Appointment?> show(
    BuildContext context, {
    DateTime? initialDate,
    ValueChanged<Appointment>? onAppointmentScheduled,
    DateTime? referenceDateTime,
  }) {
    return showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleAppointmentModal(
        initialDate: initialDate,
        onAppointmentScheduled: onAppointmentScheduled,
        referenceDateTime: referenceDateTime,
      ),
    );
  }

  /// Synchronously validates that an appointment is not scheduled in the past.
  ///
  /// **Business Rules & Data Integrity:**
  /// - Compares [appointmentDateTime] against [referenceNow] (defaulting to [DateTime.now]).
  /// - Explicitly blocks past dates and past times (`appointmentDateTime.isBefore(now)`).
  /// - When validation fails, logs a warning via [AppLogger.warning] and returns
  ///   `'Cannot schedule appointments in the past'`.
  ///
  /// Enforces chronological consistency in the local SQLite `appointments` timeline.
  static String? validateAppointmentDateTime(
    DateTime appointmentDateTime, [
    DateTime? referenceNow,
  ]) {
    final now = referenceNow ?? DateTime.now();
    if (appointmentDateTime.isBefore(now)) {
      AppLogger.warning('Validation failed: Attempted to schedule appointment in the past');
      return 'Cannot schedule appointments in the past';
    }
    return null;
  }

  @override
  ConsumerState<ScheduleAppointmentModal> createState() => _ScheduleAppointmentModalState();
}

class _ScheduleAppointmentModalState extends ConsumerState<ScheduleAppointmentModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _notesController = TextEditingController();

  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 30);
  String? _dateTimeError;

  Patient? _selectedPatient;
  Clinic? _selectedClinic;

  DateTime get _effectiveNow => widget.referenceDateTime ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, $monthName ${date.day}, ${date.year}';
  }

  Future<void> _pickDate() async {
    final today = DateTime(_effectiveNow.year, _effectiveNow.month, _effectiveNow.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surfaceContainerLowest,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateTimeError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surfaceContainerLowest,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _dateTimeError = null;
      });
    }
  }

  /// Persists a newly scheduled clinical appointment to the local SQLite database.
  ///
  /// Extracts the foreign relational keys ([patientId] and [clinicId]) directly
  /// from the selected [Patient] and [Clinic] domain entities. Mapping these verified
  /// entity IDs directly into the [Appointment] record ensures database referential
  /// integrity and prevents orphaned records under SQLite foreign key constraints.
  Future<void> _saveAppointment() async {
    final patient = _selectedPatient;
    final clinic = _selectedClinic;

    // Validation Guard: Ensure both relational entities are selected.
    if (patient == null || clinic == null) {
      AppLogger.warning(
        '[ScheduleAppointmentModal] Attempted to save appointment without selecting both a patient and a clinic.',
      );
      _formKey.currentState?.validate();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Validation Guard: Enforce that appointment is not scheduled in the past.
    final dateError = ScheduleAppointmentModal.validateAppointmentDateTime(scheduledDateTime, _effectiveNow);
    if (dateError != null) {
      setState(() {
        _dateTimeError = dateError;
      });
      return;
    }

    // Extract true relational entity IDs
    final patientId = patient.id;
    final clinicId = clinic.id;

    final notes = _notesController.text.trim();
    final procedureText = notes.isNotEmpty ? '${clinic.name} - $notes' : clinic.name;

    // Generate collision-free UUID v4 for the new appointment record.
    // Offline-first SQLite requires client-side primary key generation that guarantees
    // global uniqueness without requiring a central server or roundtrip network coordination.
    final appointmentId = const Uuid().v4();
    AppLogger.debug('Generated collision-free UUID [$appointmentId] for new appointment record.');

    final newAppointment = Appointment(
      id: appointmentId,
      patientId: patientId,
      clinicId: clinicId,
      scheduledDate: scheduledDateTime,
      procedureDescription: procedureText,
      status: 'Scheduled',
    );

    // Trace relational foreign keys immediately prior to SQLite insertion
    AppLogger.info(
      '[ScheduleAppointmentModal] Inserting appointment: patientId=$patientId, clinicId=$clinicId, scheduledDate=$scheduledDateTime',
    );

    try {
      await ref.read(appointmentsNotifierProvider.notifier).addAppointment(
            newAppointment,
            clinicName: clinic.name,
          );
    } catch (e, stack) {
      if (mounted) {
        DenteraSnackBar.showError(
          context,
          message: 'Failed to schedule appointment',
          error: e,
          stackTrace: stack,
        );
      }
      return;
    }

    widget.onAppointmentScheduled?.call(newAppointment);
    if (!mounted) return;
    Navigator.of(context).pop(newAppointment);
  }

  Color _parseColor(String? hexString, {Color fallback = AppColors.secondary}) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      } else if (hex.length == 8) {
        return Color(int.parse('0x$hex'));
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final patientsAsync = ref.watch(patientListProvider);
    final clinicsAsync = ref.watch(clinicListProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 1. Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),

            // 2. Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Schedule Appointment',
                    style: AppTextStyles.h1Mobile.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 0.8,
              color: AppColors.surfaceVariant,
            ),

            // 3. Scrollable Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 1. Patient Dropdown Selection
                      patientsAsync.when(
                        data: (patients) {
                          return DenteraDropdown<Patient>(
                            key: const Key('patient_dropdown'),
                            label: 'Patient *',
                            hintText: patients.isEmpty ? 'No patients available' : 'Select patient...',
                            value: patients.contains(_selectedPatient) ? _selectedPatient : null,
                            items: patients
                                .map(
                                  (p) => DropdownMenuItem<Patient>(
                                    value: p,
                                    child: Text(
                                      '${p.name} (${p.id})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            validator: (val) {
                              if (val == null) {
                                return 'Please select a patient';
                              }
                              return null;
                            },
                            onChanged: (val) {
                              setState(() {
                                _selectedPatient = val;
                              });
                            },
                          );
                        },
                        loading: () => DenteraDropdown<Patient>(
                          key: const Key('patient_dropdown_loading'),
                          label: 'Patient *',
                          hintText: 'Loading patients...',
                          items: const <DropdownMenuItem<Patient>>[],
                          onChanged: null,
                        ),
                        error: (_, _) => DenteraDropdown<Patient>(
                          key: const Key('patient_dropdown_error'),
                          label: 'Patient *',
                          hintText: 'Failed to load patients',
                          items: const <DropdownMenuItem<Patient>>[],
                          onChanged: null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Clinic Dropdown Selection
                      clinicsAsync.when(
                        data: (clinics) {
                          return DenteraDropdown<Clinic>(
                            key: const Key('clinic_dropdown'),
                            label: 'Clinic / Department *',
                            hintText: clinics.isEmpty ? 'No clinics available' : 'Select clinic...',
                            value: clinics.contains(_selectedClinic) ? _selectedClinic : null,
                            items: clinics
                                .map(
                                  (c) => DropdownMenuItem<Clinic>(
                                    value: c,
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: _parseColor(c.colorHex),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            c.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            validator: (val) {
                              if (val == null) {
                                return 'Please select a clinic';
                              }
                              return null;
                            },
                            onChanged: (val) {
                              setState(() {
                                _selectedClinic = val;
                              });
                            },
                          );
                        },
                        loading: () => DenteraDropdown<Clinic>(
                          key: const Key('clinic_dropdown_loading'),
                          label: 'Clinic / Department *',
                          hintText: 'Loading clinics...',
                          items: const <DropdownMenuItem<Clinic>>[],
                          onChanged: null,
                        ),
                        error: (_, _) => DenteraDropdown<Clinic>(
                          key: const Key('clinic_dropdown_error'),
                          label: 'Clinic / Department *',
                          hintText: 'Failed to load clinics',
                          items: const <DropdownMenuItem<Clinic>>[],
                          onChanged: null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Date & Time Selectors Row
                      Row(
                        children: <Widget>[
                          // Date Selector
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Date *',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.outlineVariant),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _formatDate(_selectedDate),
                                            style: AppTextStyles.bodyMd.copyWith(
                                              color: AppColors.onSurface,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Time Selector
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Time *',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _pickTime,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.outlineVariant),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        const Icon(
                                          Icons.schedule_rounded,
                                          size: 18,
                                          color: AppColors.secondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _selectedTime.format(context),
                                          style: AppTextStyles.bodyMd.copyWith(
                                            color: AppColors.onSurface,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_dateTimeError != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            _dateTimeError!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // 4. Clinical Notes / Tooth Number
                      DenteraTextField(
                        label: 'Clinical Notes / Tooth Number (Optional)',
                        hintText: 'e.g. Tooth 46, Secondary impression',
                        controller: _notesController,
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Action Buttons Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: SecondaryButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      key: const Key('save_appointment_button'),
                      text: 'Save Appointment',
                      icon: const Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: AppColors.onPrimary,
                      ),
                      onPressed: _saveAppointment,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
