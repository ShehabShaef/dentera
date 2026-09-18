import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../dentera_snackbar.dart';
import '../inputs/inputs.dart';

/// Modal bottom sheet to edit an existing scheduled clinical appointment.
///
/// Pre-filled with the appointment's date, time, assigned clinic, status, and procedure notes.
/// Persists modifications via [AppointmentsNotifier.updateAppointment] (which handles SQLite mutation,
/// cancels previous notifications, reschedules active reminders, and invalidates timeline providers).
class EditAppointmentModal extends ConsumerStatefulWidget {
  const EditAppointmentModal({
    super.key,
    required this.appointment,
    this.patientName,
    this.onAppointmentUpdated,
  });

  final Appointment appointment;
  final String? patientName;
  final ValueChanged<Appointment>? onAppointmentUpdated;

  /// Convenience static helper to show the [EditAppointmentModal] bottom sheet.
  static Future<Appointment?> show(
    BuildContext context, {
    required Appointment appointment,
    String? patientName,
    ValueChanged<Appointment>? onAppointmentUpdated,
  }) {
    AppLogger.info('Opened EditAppointmentModal for appointment: ${appointment.id}');
    return showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditAppointmentModal(
        appointment: appointment,
        patientName: patientName,
        onAppointmentUpdated: onAppointmentUpdated,
      ),
    );
  }

  @override
  ConsumerState<EditAppointmentModal> createState() => _EditAppointmentModalState();
}

class _EditAppointmentModalState extends ConsumerState<EditAppointmentModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _notesController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedClinicId;
  late String _selectedStatus;
  bool _isSubmitting = false;

  static const List<String> _statuses = <String>[
    'Scheduled',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.appointment.scheduledDate.year,
      widget.appointment.scheduledDate.month,
      widget.appointment.scheduledDate.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(widget.appointment.scheduledDate);
    _selectedClinicId = widget.appointment.clinicId;
    _selectedStatus = _statuses.contains(widget.appointment.status)
        ? widget.appointment.status
        : 'Scheduled';
    _notesController = TextEditingController(
      text: widget.appointment.procedureDescription ?? '',
    );
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _pickDate() async {
    final initial = _selectedDate;
    final first = DateTime(2020, 1, 1);
    final last = DateTime.now().add(const Duration(days: 730));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppDarkColors.tealAccent,
                    onPrimary: AppDarkColors.onTeal,
                    surface: AppDarkColors.surfaceContainer,
                    onSurface: AppDarkColors.textPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: AppColors.onPrimary,
                    onSurface: AppColors.onSurface,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppDarkColors.tealAccent,
                    onPrimary: AppDarkColors.onTeal,
                    surface: AppDarkColors.surfaceContainer,
                    onSurface: AppDarkColors.textPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: AppColors.onPrimary,
                    onSurface: AppColors.onSurface,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final clinics = ref.read(clinicListProvider).valueOrNull ?? const <Clinic>[];
    final selectedClinic = clinics.where((c) => c.id == _selectedClinicId).firstOrNull;
    final clinicName = selectedClinic?.name ?? 'Dental Clinic';

    final updatedAppointment = widget.appointment.copyWith(
      clinicId: _selectedClinicId,
      scheduledDate: scheduledDateTime,
      status: _selectedStatus,
      procedureDescription: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    try {
      AppLogger.info('Updating appointment: ${updatedAppointment.id}');
      await ref.read(appointmentsNotifierProvider.notifier).updateAppointment(
            updatedAppointment,
            clinicName: clinicName,
          );

      // Also ensure old date timeline is invalidated if the date was changed
      final oldDate = DateTime(
        widget.appointment.scheduledDate.year,
        widget.appointment.scheduledDate.month,
        widget.appointment.scheduledDate.day,
      );
      final newDate = DateTime(
        scheduledDateTime.year,
        scheduledDateTime.month,
        scheduledDateTime.day,
      );
      if (oldDate != newDate) {
        ref.invalidate(dailyAppointmentsProvider(oldDate));
      }

      widget.onAppointmentUpdated?.call(updatedAppointment);

      if (mounted) {
        Navigator.of(context).pop(updatedAppointment);
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        DenteraSnackBar.showError(
          context,
          message: 'Failed to update appointment',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final clinicsAsync = ref.watch(clinicListProvider);
    final patientsAsync = ref.watch(patientListProvider);

    final resolvedPatientName = widget.patientName ??
        patientsAsync.valueOrNull
            ?.where((p) => p.id == widget.appointment.patientId)
            .firstOrNull
            ?.name ??
        'Patient #${widget.appointment.patientId}';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 1. Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.dragHandle : AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Appointment',
                            style: AppTextStyles.h2.copyWith(
                              color: isDark ? AppDarkColors.tealAccent : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update schedule, clinic department, and notes',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? AppDarkColors.textSecondary : AppColors.outline),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Divider(height: 20, thickness: 0.8, color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),

                // 3. Patient Info Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 20, color: isDark ? AppDarkColors.tealAccent : AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        resolvedPatientName,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Clinic Department Selection
                Text(
                  'Clinical Department',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                clinicsAsync.when(
                  data: (clinics) {
                    return DropdownButtonFormField<String>(
                      initialValue: clinics.any((c) => c.id == _selectedClinicId)
                          ? _selectedClinicId
                          : (clinics.isNotEmpty ? clinics.first.id : null),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? AppDarkColors.inputFill : AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        prefixIcon: Icon(Icons.business_rounded, color: isDark ? AppDarkColors.textSecondary : AppColors.outline),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      dropdownColor: isDark ? AppDarkColors.surfaceContainer : null,
                      items: clinics.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(
                            c.name,
                            style: AppTextStyles.bodyMd.copyWith(color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedClinicId = val);
                      },
                      validator: (val) => val == null ? 'Please select a clinic' : null,
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) => const Text('Failed to load clinics'),
                ),
                const SizedBox(height: 16),

                // 5. Date & Time Row
                Text(
                  'Schedule Date & Time',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Date Button
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppDarkColors.inputFill : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 18, color: isDark ? AppDarkColors.tealAccent : AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatDate(_selectedDate),
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Time Button
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppDarkColors.inputFill : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 18, color: isDark ? AppDarkColors.tealAccent : AppColors.secondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatTime(_selectedTime),
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. Appointment Status Selection
                Text(
                  'Appointment Status',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _statuses.map((status) {
                    final isSelected = status == _selectedStatus;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedStatus = status);
                      },
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: isSelected ? (isDark ? AppDarkColors.onTeal : AppColors.onSecondary) : (isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      selectedColor: isDark ? AppDarkColors.tealAccent : AppColors.secondary,
                      backgroundColor: isDark ? AppDarkColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
                      side: BorderSide(
                        color: isSelected ? (isDark ? AppDarkColors.tealAccent : AppColors.secondary) : (isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 7. Procedure Notes
                Text(
                  'Procedure & Clinical Notes',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                DenteraTextField(
                  controller: _notesController,
                  hintText: 'e.g. Tooth #36 Root Canal Obturation',
                  prefixIcon: Icon(Icons.medical_services_outlined, color: isDark ? AppDarkColors.textSecondary : AppColors.outline),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // 8. Action Buttons
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SecondaryButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        text: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        text: _isSubmitting ? 'Saving...' : 'Save Changes',
                        icon: Icon(Icons.check_circle_outline_rounded, size: 18, color: isDark ? AppDarkColors.onTeal : AppColors.onPrimary),
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
