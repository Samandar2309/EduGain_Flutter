import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale_controller.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';

/// First-launch welcome flow — the app's very first impression.
///
/// Page 0 asks for the UI language (endonyms, effective immediately), then
/// three value slides tell the story: talk to an AI tutor, get live coaching,
/// follow a goal track. Finishing (or skipping) marks onboarding complete and
/// the router carries the user on to login. Shown once per device.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _pageCount = 4;

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _pageCount - 1;

  void _next() {
    if (_isLast) {
      ref.read(onboardingProvider.notifier).complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: skip is always available — never trap the user.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpace.sm,
                  right: AppSpace.lg,
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isLast ? 0 : 1,
                  child: TextButton(
                    onPressed: _isLast
                        ? null
                        : () =>
                              ref.read(onboardingProvider.notifier).complete(),
                    child: Text(
                      l.welcomeSkip,
                      style: const TextStyle(color: AppColors.inkFaint),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _LanguagePage(),
                  _ValueSlide(
                    icon: Icons.forum_rounded,
                    accent: AppColors.speaking,
                    title: l.welcomeSpeakTitle,
                    body: l.welcomeSpeakBody,
                  ),
                  _ValueSlide(
                    icon: Icons.auto_awesome_rounded,
                    accent: AppColors.vocabulary,
                    title: l.welcomeCoachTitle,
                    body: l.welcomeCoachBody,
                  ),
                  _ValueSlide(
                    icon: Icons.flag_rounded,
                    accent: AppColors.brand,
                    title: l.welcomeGoalTitle,
                    body: l.welcomeGoalBody,
                  ),
                ],
              ),
            ),
            _Dots(count: _pageCount, active: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xxl,
                AppSpace.xl,
                AppSpace.xxl,
                AppSpace.xxl,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? l.welcomeStart : l.continueAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page 0 — brand hero + language choice. Endonyms only, so everyone finds
/// their own language regardless of the current locale; tapping switches the
/// whole UI immediately (the strongest possible "this app is for me" signal).
class _LanguagePage extends ConsumerWidget {
  const _LanguagePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(localeProvider.notifier).current;
    ref.watch(localeProvider); // rebuild on switch

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(size: 84),
          const SizedBox(height: AppSpace.xl),
          Text(
            'EduGain',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            l.appTagline,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: AppSpace.xxxl),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l.welcomeChooseLanguage,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          for (final lang in AppLanguage.values) ...[
            _LanguageCard(
              lang: lang,
              selected: lang == current,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(localeProvider.notifier).setLanguage(lang);
              },
            ),
            const SizedBox(height: AppSpace.md),
          ],
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: lang.endonym,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.lg,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandTint : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.line,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected ? const [] : AppShadow.card,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  lang.endonym,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.brandDeep : AppColors.ink,
                  ),
                ),
              ),
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: selected ? 1 : 0,
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One value slide: a soft accent illustration disc, a headline and a calm
/// two-line body. Restrained on purpose — premium, not playful.
class _ValueSlide extends StatelessWidget {
  const _ValueSlide({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppGradients.accent(accent),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppShadow.glow(accent),
                ),
                child: Icon(icon, color: Colors.white, size: 46),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xxxl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated page indicator — the active dot stretches into a pill.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? AppColors.brand : AppColors.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
