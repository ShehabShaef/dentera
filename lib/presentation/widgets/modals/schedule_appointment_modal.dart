import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/local_notification_service.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../inputs/inputs.dart';

/// Bottom sheet modal to schedule clinical appointments with patients.
class ScheduleAppointmentModal extends ConsumerStatefulWidget {
  const ScheduleAppointmentModal({
    super.key,
    this.initialDate,
    this.onAppointmentScheduled,
  });

  final DateTime? initialDate;
  final ValueChanged<Appointment>? onAppointmentScheduled;

  /// Convenience static method to show the ScheduleAppointmentModal.
  static Future<Appointment?> show(
    BuildContext context, {
    DateTime? initialDate,
    ValueChanged<Appointment>? onAppointmentScheduled,
  }) {
    return showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleAppointmentModal(
        initialDate: initialDate,
        onAppointmentScheduled: onAppointmentScheduled,
      ),
    );
  }

  @override
  ConsumerState<ScheduleAppointmentModal> createState() => _ScheduleAppointmentModalState();
}

class _ScheduleAppointmentModalState extends ConsumerState<ScheduleAppointmentModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _notesController = TextEditingController();

  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 30);

  String _selectedPatient = 'Sara Ahmed (PT-1001)';
  String _selectedProcedure = 'Prosthodontics - Complete Denture';

  static const List<String> _mockPatients = <String>[
    'Sara Ahmed (PT-1001)',
    'Ahmed Ali (PT-1002)',
    'Omar Khalid (PT-1003)',
    'Layla Al-Yamani (PT-1004)',
    'Fatima Hassan (PT-1005)',
  ];

  static const List<Map<String, String>> _procedures = <Map<String, String>>[
    {'clinic': 'Prostho', 'procedure': 'Complete Denture', 'clinicId': 'c-pros'},
    {'clinic': 'Operative', 'procedure': 'Class II Composite', 'clinicId': 'c-op'},
    {'clinic': 'Endo', 'procedure': 'Root Canal (Tooth 46)', 'clinicId': 'c-endo'},
    {'clinic': 'Perio', 'procedure': 'Scaling & Root Planing', 'clinicId': 'c-perio'},
    {'clinic': 'Oral Surgery', 'procedure': 'Simple Extraction', 'clinicId': 'c-surg'},
  ];

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
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      });
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final patientIdMatch = RegExp(r'\((PT-\d+)\)').firstMatch(_selectedPatient);
    final patientId = patientIdMatch?.group(1) ?? 'PT-1001';

    final notes = _notesController.text.trim();
    final procedureText = notes.isNotEmpty ? '$_selectedProcedure - $notes' : _selectedProcedure;

    final newAppointment = Appointment(
      id: 'apt-${DateTime.now().millisecondsSinceEpoch % 10000}',
      patientId: patientId,
      clinicId: 'c-pros',
      scheduledDate: scheduledDateTime,
      procedureDescription: procedureText,
      status: 'Scheduled',
    );

    try {
      await ref.read(appointmentRepositoryProvider).addAppointment(newAppointment);
      ref.invalidate(dailyAppointmentsProvider(scheduledDateTime));
      ref.invalidate(allAppointmentsProvider);
      ref.invalidate(upcomingAppointmentsProvider);

      // Phase 7.2 - Schedule local notification reminder for this appointment
      await ref.read(notificationServiceProvider).scheduleAppointmentReminder(
            newAppointment,
            clinicName: _selectedProcedure.split(' - ').first,
          );
    } catch (_) {
      // Offline fallback handling
    }

    widget.onAppointmentScheduled?.call(newAppointment);
    if (!mounted) return;
    Navigator.of(context).pop(newAppointment);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                      // Patient Dropdown Selection
                      DenteraDropdown<String>(
                        label: 'Patient *',
                        value: _selectedPatient,
                        items: _mockPatients
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedPatient = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Procedure / Requirement Carousel Selection
                      Text(
                        'Procedure / Requirement *',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _procedures.map((item) {
                            final fullTitle = '${item['clinic']} - ${item['procedure']}';
                            final isSelected = _selectedProcedure == fullTitle;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedProcedure = fullTitle;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.secondaryContainer.withValues(alpha: 0.25)
                                        : AppColors.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.secondary
                                          : AppColors.outlineVariant,
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        item['clinic']!.toUpperCase(),
                                        style: AppTextStyles.labelCaps.copyWith(
                                          color: isSelected
                                              ? AppColors.secondary
                                              : AppColors.outline,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['procedure']!,
                                        style: AppTextStyles.bodyMd.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date & Time Selectors Row
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
                      const SizedBox(height: 16),

                      // Procedure Description / Notes
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
                      text: 'Confirm Appointment',
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
