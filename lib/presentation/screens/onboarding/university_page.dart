import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

/// Step 2 of Onboarding: University / Dental School Selection.
class UniversityPage extends StatelessWidget {
  const UniversityPage({
    super.key,
    required this.universityController,
    required this.onContinue,
    required this.onBack,
  });

  final TextEditingController universityController;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: BaseCard(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Title & Subtitle
                Text(
                  'Your Institution',
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: 8),
                Text(
                  'Which university or dental school are you attending?',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Input Field
                DenteraTextField(
                  label: 'University / School',
                  hintText: "e.g., University of Sana'a",
                  controller: universityController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.school_outlined,
                    color: AppColors.outline,
                    size: 20,
                  ),
                  onFieldSubmitted: (_) => onContinue(),
                ),
                const SizedBox(height: 24),

                // Action Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TextButton(
                      onPressed: onBack,
                      child: Text(
                        'Back',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PrimaryButton(
                      isFullWidth: false,
                      text: 'Continue',
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppColors.onPrimary,
                      ),
                      onPressed: onContinue,
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
