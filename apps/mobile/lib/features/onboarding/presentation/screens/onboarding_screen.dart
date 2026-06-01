import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/config/public_config_provider.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/onboarding_prefs.dart';
import '../widgets/dots_indicator.dart';
import '../widgets/slide.dart';

/// First-launch intro: a 3-page [PageView] with dots, Skip, and Next/
/// Get-started actions. Mirrors the `intro` prototype. Finishing or skipping
/// persists the "seen" flag and routes to `/auth/phone`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const String routeName = 'onboarding';
  static const String routePath = '/onboarding';

  /// Destination after finishing/skipping (T-009 builds the real screen).
  static const String nextRoutePath = '/auth/phone';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<OnboardingSlideData> _slides(AppLocalizations l10n) => [
        OnboardingSlideData(
          emoji: '🏠',
          background: KhatirColors.sageBg,
          accent: KhatirColors.sage,
          accentDark: KhatirColors.sageDk,
          kicker: l10n.onboarding_slide1_kicker,
          title: l10n.onboarding_slide1_title,
          accentLine: l10n.onboarding_slide1_accent,
          body: l10n.onboarding_slide1_body,
        ),
        OnboardingSlideData(
          emoji: '⚡',
          background: KhatirColors.butterBg,
          accent: KhatirColors.butter,
          accentDark: KhatirColors.butterDk,
          kicker: l10n.onboarding_slide2_kicker,
          title: l10n.onboarding_slide2_title,
          accentLine: l10n.onboarding_slide2_accent,
          body: l10n.onboarding_slide2_body,
        ),
        OnboardingSlideData(
          emoji: '🎁',
          background: KhatirColors.roseBg,
          accent: KhatirColors.rose,
          accentDark: KhatirColors.roseDk,
          kicker: l10n.onboarding_slide3_kicker,
          title: l10n.onboarding_slide3_title,
          accentLine: l10n.onboarding_slide3_accent,
          body: l10n.onboarding_slide3_body,
        ),
      ];

  Future<void> _finish() async {
    await ref.read(onboardingPrefsProvider).markSeen();
    if (!mounted) return;
    context.go(OnboardingScreen.nextRoutePath);
  }

  void _next(int lastIndex) {
    if (_index >= lastIndex) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slides = _slides(l10n);
    final lastIndex = slides.length - 1;
    final active = slides[_index];
    final isLast = _index == lastIndex;

    final configAsync = ref.watch(publicConfigProvider);
    // Loading guard while /config/public resolves; skip availability is
    // config-driven (defaults to allowed on error).
    final skipAllowed = configAsync.maybeWhen(
      data: (c) => c.introSlideSkipAllowed,
      orElse: () => true,
    );
    final isLoading = configAsync.isLoading;

    final onButterAccent = active.accent == KhatirColors.butter;

    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header: dots + Skip.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KhatirSpacing.s6,
                      KhatirSpacing.s4,
                      KhatirSpacing.s6,
                      KhatirSpacing.s1,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DotsIndicator(
                          count: slides.length,
                          activeIndex: _index,
                          activeColor: active.accentDark,
                        ),
                        if (skipAllowed)
                          TextButton(
                            onPressed: _finish,
                            style: TextButton.styleFrom(
                              foregroundColor: KhatirColors.muted,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              l10n.onboarding_skip,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: KhatirColors.muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Slides.
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: slides.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) =>
                          OnboardingSlide(data: slides[i]),
                    ),
                  ),
                  // Footer: Next / Get-started.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KhatirSpacing.s6,
                      KhatirSpacing.s4,
                      KhatirSpacing.s6,
                      KhatirSpacing.s6,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _next(lastIndex),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isLast ? KhatirColors.sage : active.accent,
                          foregroundColor: isLast
                              ? KhatirColors.cream
                              : (onButterAccent
                                  ? KhatirColors.ink
                                  : KhatirColors.cream),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: KhatirSpacing.s4,
                          ),
                          textStyle: AppTextStyles.labelLarge,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(KhatirRadius.button),
                          ),
                        ),
                        child: Text(
                          isLast
                              ? l10n.onboarding_start
                              : l10n.onboarding_next,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
