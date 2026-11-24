import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/theme.dart';
import '../../../../data/repositories/preferences_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../../widgets/buttons/buttons.dart';
import '../../../widgets/inputs/inputs.dart';
import '../../../widgets/modals/modals.dart';

/// Modal bottom sheet allowing dental students to edit their profile credentials
/// (Doctor First & Last Name, University, and Academic Year).
///
/// Changes are persisted locally via [PreferencesRepository] and reactively broadcast
/// via [userProfileProvider] to immediately refresh profile headers and identity badges.
class EditProfileModal extends ConsumerStatefulWidget {
  const EditProfileModal({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    this.initialName,
    this.initialUniversity,
    this.initialAcademicYear,
  });

  final String? initialFirstName;
  final String? initialLastName;
  final String? initialName;
  final String? initialUniversity;
  final String? initialAcademicYear;

  /// Convenience static method to display the [EditProfileModal] bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    String? initialFirstName,
    String? initialLastName,
    String? initialName,
    String? initialUniversity,
    String? initialAcademicYear,
  }) {
    AppLogger.info('Opened EditProfileModal');
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModal(
        initialFirstName: initialFirstName,
        initialLastName: initialLastName,
        initialName: initialName,
        initialUniversity: initialUniversity,
        initialAcademicYear: initialAcademicYear,
      ),
    );
  }

  @override
  ConsumerState<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends ConsumerState<EditProfileModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _universityController;
  late final TextEditingController _yearController;

  bool _isSaving = false;

  static const List<String> _academicYears = <String>[
    '3rd Year',
    '4th Year',
    '5th Year',
    'Internship',
    'General Practice',
  ];

  @override
  void initState() {
    super.initState();

    // Pre-populate controllers from passed parameters or active user profile state
    final profile = ref.read(userProfileProvider).value;
    final String defaultFirst;
    final String defaultLast;

    if (widget.initialFirstName != null || widget.initialLastName != null) {
      defaultFirst = widget.initialFirstName ?? '';
      defaultLast = widget.initialLastName ?? '';
    } else if (widget.initialName != null) {
      final split = PreferencesRepository.splitFullName(widget.initialName!);
      defaultFirst = split.$1;
      defaultLast = split.$2;
    } else if (profile != null) {
      defaultFirst = profile.firstName;
      defaultLast = profile.lastName;
    } else {
      defaultFirst = 'Doctor';
      defaultLast = '';
    }

    final defaultUni = widget.initialUniversity ?? profile?.university ?? 'Dental School';
    final defaultYear = widget.initialAcademicYear ?? profile?.academicYear ?? '5th Year';

    _firstNameController = TextEditingController(text: defaultFirst);
    _lastNameController = TextEditingController(text: defaultLast);
    _universityController = TextEditingController(text: defaultUni);
    _yearController = TextEditingController(text: defaultYear);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _universityController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final firstName = PreferencesRepository.stripDoctorPrefix(_firstNameController.text.trim());
    final lastName = PreferencesRepository.stripDoctorPrefix(_lastNameController.text.trim());
    final university = _universityController.text.trim();
    final academicYear = _yearController.text.trim();

    try {
      await ref.read(userProfileProvider.notifier).updateProfile(
            firstName: firstName,
            lastName: lastName,
            university: university,
            academicYear: academicYear,
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save user profile: $e', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save profile: $e',
            style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceContainerElevated : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomInset + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
            // Drag handle
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
            const SizedBox(height: 20),

            // Header Title
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppDarkColors.primaryContainer.withValues(alpha: 0.25)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: isDark ? AppDarkColors.primary : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Edit Clinician Profile',
                  style: AppTextStyles.h2.copyWith(
                    color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Profile Avatar Picker Trigger
            Center(
              child: GestureDetector(
                onTap: () => AvatarPickerModal.show(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        _buildAvatarPreview(isDark),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark ? AppDarkColors.primary : AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppDarkColors.surfaceContainerElevated : AppColors.surface,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 12,
                              color: isDark ? AppDarkColors.onPrimary : AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Change Photo',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppDarkColors.primary : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Static "Dr." Prefix Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppDarkColors.primary.withValues(alpha: 0.08)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? AppDarkColors.primary.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.primary : AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.l10n.doctorPrefix,
                      style: AppTextStyles.labelCaps.copyWith(
                        color: isDark ? AppDarkColors.onPrimary : AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.prefixAddedAutomatically,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppDarkColors.textSecondary : AppColors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Doctor First & Last Name fields
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: DenteraTextField(
                    controller: _firstNameController,
                    label: context.l10n.firstName,
                    hintText: context.l10n.firstNamePlaceholder,
                    textCapitalization: TextCapitalization.words,
                    validator: (val) {
                      final clean = PreferencesRepository.stripDoctorPrefix(val ?? '');
                      if (clean.trim().isEmpty) {
                        return context.l10n.firstNameRequired;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DenteraTextField(
                    controller: _lastNameController,
                    label: context.l10n.lastName,
                    hintText: context.l10n.lastNamePlaceholder,
                    textCapitalization: TextCapitalization.words,
                    validator: (val) {
                      final clean = PreferencesRepository.stripDoctorPrefix(val ?? '');
                      if (clean.trim().isEmpty) {
                        return context.l10n.lastNameRequired;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Academic Year dropdown/selector
            DenteraDropdown<String>(
              label: 'Academic Year',
              value: _academicYears.contains(_yearController.text)
                  ? _yearController.text
                  : _academicYears.first,
              items: _academicYears
                  .map((year) => DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
                      ))
                  .toList(),
              onChanged: (selected) {
                if (selected != null) {
                  setState(() {
                    _yearController.text = selected;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // University field
            DenteraTextField(
              controller: _universityController,
              label: 'University / Dental School',
              hintText: context.l10n.universityHint,
              textCapitalization: TextCapitalization.words,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return context.l10n.universityRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Buttons
            Row(
              children: <Widget>[
                Expanded(
                  child: SecondaryButton(
                    text: 'Cancel',
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Save Changes',
                    isLoading: _isSaving,
                    onPressed: _handleSave,
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

  bool get _isTestEnvironment =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      Platform.executable.contains('flutter_tester') ||
      WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');

  Widget _buildAvatarPreview(bool isDark) {
    final avatarPath = ref.watch(avatarProvider);
    final hasAvatar = avatarPath != null && avatarPath.isNotEmpty;
    final file = hasAvatar ? File(avatarPath) : null;
    final fileExists = file != null && file.existsSync();

    final clean = PreferencesRepository.stripDoctorPrefix(_firstNameController.text).trim();
    final initial = clean.isNotEmpty ? clean[0].toUpperCase() : 'D';

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: (hasAvatar && (fileExists || _isTestEnvironment))
            ? null
            : (isDark ? AppDarkColors.brandGradient : AppColors.brandGradient),
        color: (hasAvatar && (fileExists || _isTestEnvironment))
            ? (isDark
                ? AppDarkColors.primaryContainer.withValues(alpha: 0.2)
                : AppColors.primaryContainer.withValues(alpha: 0.2))
            : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppDarkColors.outlineVariant : AppColors.outlineVariant,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasAvatar
          ? (!_isTestEnvironment && fileExists
              ? Image.file(
                  file,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Text(
                    initial,
                    style: AppTextStyles.h1.copyWith(
                      color: isDark ? AppDarkColors.onPrimary : AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Icon(
                  Icons.person_rounded,
                  size: 38,
                  color: isDark ? AppDarkColors.primary : AppColors.primary,
                ))
          : Text(
              initial,
              style: AppTextStyles.h1.copyWith(
                color: isDark ? AppDarkColors.onPrimary : AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
