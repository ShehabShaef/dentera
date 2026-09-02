import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

/// Step 1 of Onboarding: Welcome & Doctor Name.
class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.nameController,
    required this.onContinue,
  });

  final TextEditingController nameController;
  final VoidCallback onContinue;

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
                // Header Logo
                Center(
                  child: Image.asset(
                    'assets/images/dentera_logo.png',
                    width: 56,
                    height: 56,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.medical_services_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Subtitle
                Text(
                  'Welcome, Doctor.',
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: 8),
                Text(
                  "Let's set up your clinical workspace. What's your name?",
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Input Field
                DenteraTextField(
                  label: 'Full Name',
                  hintText: 'Dr. First Name Last Name',
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.outline,
                    size: 20,
                  ),
                  onFieldSubmitted: (_) => onContinue(),
                ),
                const SizedBox(height: 24),

                // Action Area
                Align(
                  alignment: Alignment.centerRight,
                  child: PrimaryButton(
                    isFullWidth: false,
                    text: 'Continue',
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.onPrimary,
                    ),
                    onPressed: onContinue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
