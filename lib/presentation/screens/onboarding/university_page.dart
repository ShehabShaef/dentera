import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/widgets.dart';

/// Step 2 of Onboarding: University / Dental School Selection.
class UniversityPage extends StatefulWidget {
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
  State<UniversityPage> createState() => _UniversityPageState();
}

class _UniversityPageState extends State<UniversityPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  // Title & Subtitle
                  Text(
                    context.l10n.yourInstitution,
                    style: AppTextStyles.h1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.whichUniversityAttending,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input Field
                  DenteraTextField(
                    label: context.l10n.universityOrSchool,
                    hintText: context.l10n.universityHint,
                    controller: widget.universityController,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(
                      Icons.school_outlined,
                      color: isDark ? AppDarkColors.outline : AppColors.outline,
                      size: 20,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.universityRequired;
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleContinue(),
                  ),
                  const SizedBox(height: 24),

                  // Action Area
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      TextButton(
                        onPressed: widget.onBack,
                        child: Text(
                          context.l10n.back,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppDarkColors.primary : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      PrimaryButton(
                        isFullWidth: false,
                        text: context.l10n.continueButton,
                        icon: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: isDark ? AppDarkColors.onPrimary : AppColors.onPrimary,
                        ),
                        onPressed: _handleContinue,
                      ),
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
