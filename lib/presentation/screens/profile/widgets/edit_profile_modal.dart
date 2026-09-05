import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/theme.dart';
import '../../../../data/repositories/preferences_repository.dart';
import '../../../widgets/buttons/buttons.dart';
import '../../../widgets/inputs/inputs.dart';

/// Modal bottom sheet allowing dental students to edit their profile credentials
/// (Doctor Name, University, and Academic Year).
///
/// Changes are persisted locally via [PreferencesRepository] and reactively broadcast
/// via [userProfileProvider] to immediately refresh profile headers and identity badges.
class EditProfileModal extends ConsumerStatefulWidget {
  const EditProfileModal({
    super.key,
    this.initialName,
    this.initialUniversity,
    this.initialAcademicYear,
  });

  final String? initialName;
  final String? initialUniversity;
  final String? initialAcademicYear;

  /// Convenience static method to display the [EditProfileModal] bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
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
  late final TextEditingController _nameController;
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
    final defaultName = widget.initialName ?? profile?.name ?? 'Dr. Shehab Shaif';
    final defaultUni = widget.initialUniversity ?? profile?.university ?? 'Dental School';
    final defaultYear = widget.initialAcademicYear ?? profile?.academicYear ?? '5th Year';

    _nameController = TextEditingController(text: defaultName);
    _universityController = TextEditingController(text: defaultUni);
    _yearController = TextEditingController(text: defaultYear);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final university = _universityController.text.trim();
    final academicYear = _yearController.text.trim();

    try {
      await ref.read(userProfileProvider.notifier).updateProfile(
            name: name,
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomInset + 24,
      ),
      child: Form(
        key: _formKey,
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
                  color: AppColors.outlineVariant,
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Edit Clinician Profile',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Doctor Name field
            DenteraTextField(
              controller: _nameController,
              label: 'Clinician Name',
              hintText: 'e.g. Dr. Shehab Shaif',
              textCapitalization: TextCapitalization.words,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Clinician name is required';
                }
                return null;
              },
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
              hintText: "e.g. Sana'a University Faculty of Dentistry",
              textCapitalization: TextCapitalization.words,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'University name is required';
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
    );
  }
}
