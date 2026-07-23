import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the first-launch welcome flow has been completed on this device.
///
/// Tri-state on purpose: `null` = still loading from disk (the router keeps
/// showing the splash so the welcome screen never flashes for returning
/// users), `false` = first launch → show `/welcome`, `true` = been here →
/// straight to login/home.
class OnboardingController extends StateNotifier<bool?> {
  OnboardingController() : super(null) {
    _load();
  }

  static const String prefsKey = 'onboarding.seen';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Don't clobber a `complete()` that raced ahead of the disk read.
    if (state == null) state = prefs.getBool(prefsKey) ?? false;
  }

  /// Mark the welcome flow as done (called from its final CTA and from Skip).
  Future<void> complete() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingController, bool?>(
  (ref) => OnboardingController(),
);
