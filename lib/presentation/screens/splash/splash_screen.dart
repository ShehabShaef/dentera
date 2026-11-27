import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/services/account_recovery_service.dart';
import '../../../core/theme/theme.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/modals/account_recovery_dialog.dart';
import '../onboarding/onboarding_screen.dart';
import '../root_navigation_screen.dart';

/// Seamless, theme-aware animated entry screen displaying the Dentera tooth-ribbon mark
/// and shimmering gradient wordmark before smoothly cross-fading into the active route.
///
/// Coordinates an entrance animation (`scale 0.85 -> 1.0`, `fade-in`, and wordmark gradient sweep)
/// in parallel with offline startup probes ([onboardingStatusProvider] and
/// [startupRecoveryCandidateProvider]), ensuring zero static-frame mismatch between native
/// OS splash surfaces (`#F7FAFC` Light / `#0C141F` Dark) and the initial Flutter frame.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.entranceDuration = const Duration(milliseconds: 1050),
    this.transitionDuration = const Duration(milliseconds: 360),
    this.autoNavigate = true,
  });

  /// Duration of the tooth-ribbon scale/fade & gradient wordmark shimmer entrance.
  final Duration entranceDuration;

  /// Duration of the [PageRouteBuilder] fade transition into the resolved destination.
  final Duration transitionDuration;

  /// Controls whether the splash screen automatically navigates upon animation + startup completion.
  /// Useful for deterministic isolated animation/visual testing when set to `false`.
  final bool autoNavigate;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkSlide;
  late final Animation<double> _shimmerProgress;
  late final Animation<double> _glowPulse;

  bool _animationCompleted = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.entranceDuration,
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.56, curve: Curves.easeOutCubic),
      ),
    );

    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.76, curve: Curves.easeOutCubic),
      ),
    );

    _shimmerProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _glowPulse = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.72).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        setState(() {
          _animationCompleted = true;
        });
        _maybeNavigate();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeNavigate() {
    if (!widget.autoNavigate || !mounted || !_animationCompleted || _hasNavigated) {
      return;
    }

    final onboardingAsync = ref.read(onboardingStatusProvider);
    final recoveryAsync = ref.read(startupRecoveryCandidateProvider);

    // Wait until both startup probes finish (or resolve error states gracefully).
    if (onboardingAsync.isLoading || recoveryAsync.isLoading) {
      return;
    }

    _hasNavigated = true;

    final recoveryCandidate = recoveryAsync.valueOrNull;
    final hasCompletedOnboarding = onboardingAsync.valueOrNull ?? false;

    final Widget destination;
    final String destinationName;
    if (recoveryCandidate != null) {
      destination = AccountRecoveryScreen(candidate: recoveryCandidate);
      destinationName = 'AccountRecoveryScreen';
    } else if (hasCompletedOnboarding) {
      destination = const RootNavigationScreen();
      destinationName = 'RootNavigationScreen';
    } else {
      destination = const OnboardingScreen();
      destinationName = 'OnboardingScreen';
    }

    AppLogger.info('[SplashScreen] Transitioning smoothly to $destinationName.');

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: widget.transitionDuration,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: fade,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-evaluate navigation readiness whenever offline startup providers emit.
    ref.listen<AsyncValue<bool>>(onboardingStatusProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeNavigate());
    });
    ref.listen<AsyncValue<AccountRecoveryCandidate?>>(startupRecoveryCandidateProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeNavigate());
    });

    final onboardingAsync = ref.watch(onboardingStatusProvider);
    final recoveryAsync = ref.watch(startupRecoveryCandidateProvider);
    final stillWaitingAsync =
        _animationCompleted && (onboardingAsync.isLoading || recoveryAsync.isLoading);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppDarkColors.background : AppColors.background;
    final markAsset = isDark
        ? 'assets/images/dentera_tooth_mark_dark.png'
        : 'assets/images/dentera_tooth_mark.png';
    final glowColor = isDark ? AppDarkColors.primaryTeal : AppColors.secondary;
    final subtitleText = AppLocalizations.of(context)?.denteraSubtitle;

    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final shimmerPos = -1.6 + (3.2 * _shimmerProgress.value);
                  final wordmarkGradient = isDark
                      ? <Color>[
                          const Color(0xFF60A5FA),
                          AppDarkColors.primaryTeal,
                          const Color(0xFFBDF7EB),
                          AppDarkColors.primaryTeal,
                          const Color(0xFF60A5FA),
                        ]
                      : <Color>[
                          AppColors.primary,
                          AppColors.secondary,
                          const Color(0xFF6EE7DC),
                          AppColors.secondary,
                          AppColors.primary,
                        ];

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Animated Tooth-Ribbon Emblem with soft theme-matched radial aura
                      Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Container(
                            width: 172,
                            height: 172,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: <Color>[
                                  glowColor.withValues(
                                    alpha: (isDark ? 0.16 : 0.09) * _glowPulse.value,
                                  ),
                                  Colors.transparent,
                                ],
                                stops: const <double>[0.0, 1.0],
                              ),
                            ),
                          ),
                          FadeTransition(
                            opacity: _logoOpacity,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: Image.asset(
                                markAsset,
                                width: 108,
                                height: 108,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.medical_services_rounded,
                                  size: 72,
                                  color: isDark
                                      ? AppDarkColors.primaryTeal
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Animated Brand Gradient Wordmark with gentle highlight sweep
                      FadeTransition(
                        opacity: _wordmarkOpacity,
                        child: SlideTransition(
                          position: _wordmarkSlide,
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                begin: Alignment(shimmerPos - 1.0, -0.2),
                                end: Alignment(shimmerPos + 1.0, 0.2),
                                colors: wordmarkGradient,
                                stops: const <double>[0.0, 0.38, 0.5, 0.62, 1.0],
                              ).createShader(bounds);
                            },
                            child: Text(
                              'DENTERA',
                              style: AppTextStyles.displayWordmark.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (subtitleText != null && subtitleText.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        FadeTransition(
                          opacity: _wordmarkOpacity,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: Text(
                              subtitleText,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: isDark
                                    ? AppDarkColors.textMuted
                                    : AppColors.onSurfaceVariant,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      AnimatedOpacity(
                        opacity: stillWaitingAsync ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: SizedBox(
                          width: 96,
                          child: stillWaitingAsync
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    minHeight: 3,
                                    backgroundColor: isDark
                                        ? AppDarkColors.surfaceContainerHigh
                                        : AppColors.surfaceContainerHigh,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark
                                          ? AppDarkColors.primaryTeal
                                          : AppColors.primary,
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 3),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
