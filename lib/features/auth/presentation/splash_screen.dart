import 'package:flutter/material.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Branded splash shown while the auth status is resolving. A single gentle
/// fade-and-settle entrance (no looping effects) — the premium feel comes from
/// restraint, and the app is usually past this screen in under a second.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.92, end: 1)
      .animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.brand),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Text(
                    'EduGain',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    l.appTagline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xxxl),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.6,
                    ),
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
