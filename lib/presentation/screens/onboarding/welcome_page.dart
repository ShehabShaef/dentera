import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/widgets.dart';

/// Step 1 of Onboarding: Welcome & Doctor Name (First & Last Name with programmatic Dr. prefix).
class WelcomePage extends StatefulWidget {
  const WelcomePage({
    super.key,
    this.nameController,
    this.firstNameController,
    this.lastNameController,
    required this.onContinue,
    this.onContinueAsGuest,
    this.isLoading = false,
  });

  final TextEditingController? nameController;
  final TextEditingController? firstNameController;
  final TextEditingController? lastNameController;
  final VoidCallback onContinue;
  final VoidCallback? onContinueAsGuest;
  final bool isLoading;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  bool _createdInternalFirst = false;
  bool _createdInternalLast = false;

  @override
  void initState() {
    super.initState();
    if (widget.firstNameController != null) {
      _firstCtrl = widget.firstNameController!;
    } else if (widget.nameController != null) {
      final split = PreferencesRepository.splitFullName(widget.nameController!.text);
      _firstCtrl = TextEditingController(text: split.$1);
      _createdInternalFirst = true;
    } else {
      _firstCtrl = TextEditingController();
      _createdInternalFirst = true;
    }

    if (widget.lastNameController != null) {
      _lastCtrl = widget.lastNameController!;
    } else if (widget.nameController != null) {
      final split = PreferencesRepository.splitFullName(widget.nameController!.text);
      _lastCtrl = TextEditingController(text: split.$2);
      _createdInternalLast = true;
    } else {
      _lastCtrl = TextEditingController();
      _createdInternalLast = true;
    }
  }

  @override
  void dispose() {
    if (_createdInternalFirst) _firstCtrl.dispose();
    if (_createdInternalLast) _lastCtrl.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      // Sync legacy nameController if present
      if (widget.nameController != null) {
        final cleanFirst = PreferencesRepository.stripDoctorPrefix(_firstCtrl.text);
        final cleanLast = PreferencesRepository.stripDoctorPrefix(_lastCtrl.text);
        widget.nameController!.text = '$cleanFirst $cleanLast'.trim();
      }
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
                  // Header Logo
                  Center(
                    child: Image.asset(
                      isDark
                          ? 'assets/images/dentera_logo_dark.png'
                          : 'assets/images/dentera_logo.png',
                      width: 64,
                      height: 64,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.medical_services_outlined,
                        size: 48,
                        color: isDark ? AppDarkColors.primary : AppColors.primary,
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
                      color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

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

                  // Two Required Fields: First Name & Last Name
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: DenteraTextField(
                          label: context.l10n.firstName,
                          hintText: context.l10n.firstNamePlaceholder,
                          controller: _firstCtrl,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.outline,
                            size: 20,
                          ),
                          validator: (value) {
                            final clean = PreferencesRepository.stripDoctorPrefix(value ?? '');
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
                          label: context.l10n.lastName,
                          hintText: context.l10n.lastNamePlaceholder,
                          controller: _lastCtrl,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: AppColors.outline,
                            size: 20,
                          ),
                          validator: (value) {
                            final clean = PreferencesRepository.stripDoctorPrefix(value ?? '');
                            if (clean.trim().isEmpty) {
                              return context.l10n.lastNameRequired;
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleContinue(),
                        ),
                      ),
                    ],
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
                                color: isDark ? AppDarkColors.primary : AppColors.primary,
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
