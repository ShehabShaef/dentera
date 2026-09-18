import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/widgets.dart';

/// Step 1 of Onboarding: Welcome & Doctor Name.
class WelcomePage extends StatefulWidget {
  const WelcomePage({
    super.key,
    required this.nameController,
    required this.onContinue,
    this.onContinueAsGuest,
    this.isLoading = false,
  });

  final TextEditingController nameController;
  final VoidCallback onContinue;
  final VoidCallback? onContinueAsGuest;
  final bool isLoading;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: BaseCard(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
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
                    context.l10n.welcomeDoctor,
                    style: AppTextStyles.h1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.setupClinicalWorkspace,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input Field
                  DenteraTextField(
                    label: context.l10n.fullName,
                    hintText: 'Dr. First Name Last Name',
                    controller: widget.nameController,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.outline,
                      size: 20,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.pleaseEnterYourName;
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleContinue(),
                  ),
                  const SizedBox(height: 24),

                  // Action Area
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      PrimaryButton(
                        isFullWidth: true,
                        isLoading: widget.isLoading,
                        text: context.l10n.continueButton,
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.onPrimary,
                        ),
                        onPressed: _handleContinue,
                      ),
                      if (widget.onContinueAsGuest != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: widget.isLoading ? null : widget.onContinueAsGuest,
                            child: Text(
                              context.l10n.continueAsGuest,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
