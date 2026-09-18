import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/l10n.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../dentera_snackbar.dart';
import '../inputs/inputs.dart';

/// Modal bottom sheet for importing and attaching radiographs (X-rays) to a patient's case sheet.
class AddRadiographModal extends ConsumerStatefulWidget {
  const AddRadiographModal({
    super.key,
    required this.patientId,
    this.patientName,
    this.initialImagePath,
    this.onRadiographSaved,
  });

  final String patientId;
  final String? patientName;
  final String? initialImagePath;
  final ValueChanged<PatientRadiograph>? onRadiographSaved;

  /// Convenience launcher helper.
  static Future<PatientRadiograph?> show(
    BuildContext context, {
    required String patientId,
    String? patientName,
    String? initialImagePath,
    ValueChanged<PatientRadiograph>? onRadiographSaved,
  }) {
    AppLogger.info('Opened AddRadiographModal for patient: $patientId');
    return showModalBottomSheet<PatientRadiograph>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddRadiographModal(
        patientId: patientId,
        patientName: patientName,
        initialImagePath: initialImagePath,
        onRadiographSaved: onRadiographSaved,
      ),
    );
  }

  @override
  ConsumerState<AddRadiographModal> createState() => _AddRadiographModalState();
}

class _AddRadiographModalState extends ConsumerState<AddRadiographModal> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _pickedImagePath;
  String _selectedType = PatientRadiograph.typePeriapical;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  String? _imageError;
  bool get _isTestEnvironment =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      Platform.executable.contains('flutter_tester') ||
      WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');

  @override
  void initState() {
    super.initState();
    _pickedImagePath = widget.initialImagePath;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 95,
      );
      if (picked != null && mounted) {
        setState(() {
          _pickedImagePath = picked.path;
          _imageError = null;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to pick image from $source', e);
      if (mounted) {
        DenteraSnackBar.showError(
          context,
          message: 'Could not access image source: $e',
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
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
                    surface: AppColors.surface,
                    onSurface: AppColors.onSurface,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_pickedImagePath == null || _pickedImagePath!.isEmpty) {
      setState(() {
        _imageError = context.l10n.pleaseSelectRadiograph;
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final savedRadiograph = await ref
          .read(radiographsControllerProvider)
          .saveRadiograph(
            patientId: widget.patientId,
            sourcePath: _pickedImagePath!,
            type: _selectedType,
            captureDate: _selectedDate,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          );

      if (mounted) {
        DenteraSnackBar.showSuccess(
          context,
          message: context.l10n.radiographAttachedSuccess(_formatProjectionType(_selectedType, context)),
        );
        widget.onRadiographSaved?.call(savedRadiograph);
        Navigator.of(context).pop(savedRadiograph);
      }
    } catch (e) {
      AppLogger.error('Failed to save radiograph', e);
      if (mounted) {
        setState(() => _isSubmitting = false);
        DenteraSnackBar.showError(
          context,
          message: context.l10n.failedToSaveRadiograph(e.toString()),
        );
      }
    }
  }

  String _formatProjectionType(String type, BuildContext context) {
    switch (type) {
      case PatientRadiograph.typePeriapical:
        return context.l10n.periapical;
      case PatientRadiograph.typeBitewing:
        return context.l10n.bitewing;
      case PatientRadiograph.typePanoramic:
        return context.l10n.panoramic;
      default:
        return context.l10n.other;
    }
  }

  Color _typeColor(String type, bool isDark) {
    switch (type) {
      case PatientRadiograph.typePeriapical:
        return isDark ? AppDarkColors.tealAccent : AppColors.primary;
      case PatientRadiograph.typeBitewing:
        return isDark ? const Color(0xFF67E8F9) : AppColors.secondary;
      case PatientRadiograph.typePanoramic:
        return const Color(0xFFFBBF24);
      default:
        return isDark ? AppDarkColors.textSecondary : AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final formattedDate = DateFormat('MMMM d, yyyy').format(_selectedDate);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceContainer : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.dragHandle : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.l10n.attachRadiographModalTitle,
                        style: AppTextStyles.h1Mobile.copyWith(
                          color: isDark ? AppDarkColors.tealAccent : AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.patientName != null)
                        Text(
                          context.l10n.patientLabel(widget.patientName!),
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                    ),
                    tooltip: context.l10n.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Image Capture / Picker Area
              Text(
                context.l10n.radiographImage,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              if (_pickedImagePath != null) ...<Widget>[
                // Image Selected Preview
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      (!_isTestEnvironment && File(_pickedImagePath!).existsSync())
                          ? Image.file(
                              File(_pickedImagePath!),
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImagePlaceholder(context),
                            )
                          : _buildImagePlaceholder(context),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: <Widget>[
                            IconButton.filledTonal(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              tooltip: context.l10n.changeImage,
                              onPressed: () => _pickImage(ImageSource.gallery),
                            ),
                            const SizedBox(width: 4),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: AppColors.onError,
                              ),
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              tooltip: context.l10n.removeImage,
                              onPressed: () => setState(() => _pickedImagePath = null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...<Widget>[
                // Image Picker Action Area
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surfaceContainerHigh : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _imageError != null
                          ? AppColors.error
                          : (isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: isDark ? AppDarkColors.tealAccent : AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.importRadiograph,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.cameraOrGallery,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          OutlinedButton.icon(
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: Text(context.l10n.camera),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: () => _pickImage(ImageSource.camera),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: Text(context.l10n.gallery),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: () => _pickImage(ImageSource.gallery),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_imageError != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    _imageError!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 20),

              // 2. Radiograph Type Selector
              Text(
                context.l10n.projectionType,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <String>[
                  PatientRadiograph.typePeriapical,
                  PatientRadiograph.typeBitewing,
                  PatientRadiograph.typePanoramic,
                  PatientRadiograph.typeOther,
                ].map((type) {
                  final isSelected = _selectedType == type;
                  final color = _typeColor(type, isDark);
                  return ChoiceChip(
                    label: Text(_formatProjectionType(type, context)),
                    selected: isSelected,
                    selectedColor: color.withValues(alpha: isDark ? 0.25 : 0.15),
                    backgroundColor: isDark
                        ? AppDarkColors.surfaceContainerHigh
                        : AppColors.surfaceContainerLowest,
                    labelStyle: AppTextStyles.caption.copyWith(
                       fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? color
                          : (isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? color
                          : (isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                      width: isSelected ? 1.5 : 1,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedType = type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 3. Capture Date Selector
              Text(
                context.l10n.captureDate,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppDarkColors.surfaceContainerHigh
                        : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 20,
                            color: isDark ? AppDarkColors.tealAccent : AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            formattedDate,
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Clinical Observations / Notes Field
              DenteraTextField(
                controller: _notesController,
                label: context.l10n.radiographicFindings,
                hintText: context.l10n.radiographicFindingsHint,
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // 5. Action Buttons
              Row(
                children: <Widget>[
                  Expanded(
                    child: SecondaryButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      text: context.l10n.cancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      text: _isSubmitting ? context.l10n.saving : context.l10n.attachRadiograph,
                      icon: Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: isDark ? AppDarkColors.onTeal : AppColors.onPrimary,
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.image_rounded, size: 40, color: Colors.white70),
          const SizedBox(height: 6),
          Text(
            context.l10n.radiographSelected,
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
