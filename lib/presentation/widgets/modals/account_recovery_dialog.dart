import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/services/account_recovery_service.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/root_navigation_screen.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';

/// Backward-compatible alias for [AccountRecoveryScreen].
typedef AccountRecoveryDialog = AccountRecoveryScreen;

/// Recovery gate rendered on launch when Android Auto Backup or local files preserved
/// non-guest clinician data across an uninstall + reinstall (Scenario A).
///
/// Gives the clinician an explicit choice between:
/// - **Continue with Existing Data**: Keeps restored SQLite + profile data intact, marks this
///   installation as verified, and enters [RootNavigationScreen].
/// - **Start New Account**: Performs a full wipe (SQLite + prefs + recovery artifacts) and
///   launches a clean [OnboardingScreen].
class AccountRecoveryScreen extends ConsumerStatefulWidget {
  const AccountRecoveryScreen({
    super.key,
    required this.candidate,
  });

  final AccountRecoveryCandidate candidate;

  @override
  ConsumerState<AccountRecoveryScreen> createState() => _AccountRecoveryScreenState();
}

enum _RecoveryAction {
  continueAccount,
  startFresh,
}

class _AccountRecoveryScreenState extends ConsumerState<AccountRecoveryScreen> {
  _RecoveryAction? _activeAction;

  Future<void> _handleContinue() async {
    if (_activeAction != null) return;
    setState(() {
      _activeAction = _RecoveryAction.continueAccount;
    });

    try {
      await ref.read(accountRecoveryServiceProvider).continueWithRecoveredAccount(widget.candidate);
      if (!mounted) return;
      ref.read(rootNavigationIndexProvider.notifier).state = 0;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (context) => const RootNavigationScreen(),
        ),
        (route) => false,
      );
    } catch (e, st) {
      AppLogger.error('[AccountRecoveryScreen] Failed continuing with recovered account: $e', e, st);
      if (!mounted) return;
      setState(() {
        _activeAction = null;
      });
    }
  }

  Future<void> _handleStartFresh() async {
    if (_activeAction != null) return;
    setState(() {
      _activeAction = _RecoveryAction.startFresh;
    });

    try {
      await ref.read(accountRecoveryServiceProvider).discardAndStartFresh();
      if (!mounted) return;
      ref.read(rootNavigationIndexProvider.notifier).state = 0;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (context) => const OnboardingScreen(),
        ),
        (route) => false,
      );
    } catch (e, st) {
      AppLogger.error('[AccountRecoveryScreen] Failed wiping recovered account for fresh start: $e', e, st);
      if (!mounted) return;
      setState(() {
        _activeAction = null;
      });
    }
  }

  String _avatarInitial(String doctorName) {
    final clean = doctorName
        .replaceAll(RegExp(r'^Dr\.\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^د\.\s*'), '')
        .trim();
    if (clean.isEmpty) return 'D';
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeCode = Localizations.localeOf(context).languageCode;
    final doctorName = widget.candidate.formattedDoctorName(localeCode);
    final isBusy = _activeAction != null;

    final scaffoldBg = isDark ? AppDarkColors.surfaceDim : AppColors.surfaceDim;
    final cardBg = isDark ? AppDarkColors.surfaceContainer : AppColors.surface;
    final borderColor = isDark ? AppDarkColors.outlineVariant : AppColors.outlineVariant;
    final badgeBg = isDark ? AppDarkColors.surfaceContainerHigh : AppColors.surfaceContainer;
    final accentColor = isDark ? AppDarkColors.primaryTeal : AppColors.secondary;
    final dangerColor = isDark ? AppDarkColors.statusError : AppColors.error;
    final primaryText = isDark ? AppDarkColors.textPrimary : AppColors.onSurface;
    final secondaryText = isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: 1.0),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Recovery Header Icon
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.restore_rounded,
                          color: accentColor,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Localized Title
                    Text(
                      context.l10n.accountRecoveryTitle,
                      style: AppTextStyles.h1Mobile.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Saved Clinician Identity Card Preview
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: isDark ? AppDarkColors.brandGradient : AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _avatarInitial(doctorName),
                              style: AppTextStyles.h2.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  doctorName,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: primaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.candidate.academicYear} • ${widget.candidate.university}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    color: secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recovery Prompt Body
                    Text(
                      context.l10n.accountRecoveryMessage(
                        doctorName,
                        widget.candidate.academicYear,
                      ),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: secondaryText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary CTA: Continue with Existing Data
                    PrimaryButton(
                      key: const Key('recovery_continue_button'),
                      text: context.l10n.continueWithExistingData,
                      icon: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: isDark ? AppDarkColors.onPrimary : AppColors.onPrimary,
                      ),
                      isLoading: _activeAction == _RecoveryAction.continueAccount,
                      onPressed: isBusy ? null : _handleContinue,
                    ),
                    const SizedBox(height: 12),

                    // Secondary Destructive CTA: Start New Account
                    SecondaryButton(
                      key: const Key('recovery_start_fresh_button'),
                      text: context.l10n.startNewAccount,
                      icon: Icon(
                        Icons.restart_alt_rounded,
                        size: 18,
                        color: isBusy
                            ? (isDark ? AppDarkColors.textMuted : AppColors.outline)
                            : dangerColor,
                      ),
                      borderColor: isBusy ? null : dangerColor,
                      textStyle: isBusy
                          ? null
                          : AppTextStyles.h2.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: dangerColor,
                            ),
                      isLoading: _activeAction == _RecoveryAction.startFresh,
                      onPressed: isBusy ? null : _handleStartFresh,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
