/// Keeping server-owned numbers true while the app stays open.
///
/// Everything on the home screen — minutes left, XP, this week's rank — is a
/// figure the server owns and the app merely renders. Each is fetched once and
/// then shown for as long as its screen lives, which is fine right up until
/// something moves it while nobody is looking. Three things do, and none of
/// them is observable from inside a `build`:
///
///   * **The app was in the background.** A Telegram Mini App is backgrounded
///     and resumed constantly — a chat, a call, the phone locking.
///   * **The learner did something that earns XP.** Games, the course and
///     Speaking are pushed on top of the tab shell, so finishing one and coming
///     back does not rebuild the tab underneath.
///   * **The tabs never go away.** `IndexedStack` keeps all four alive on
///     purpose, so scroll position and state survive a tab switch — which also
///     means `autoDispose` never fires and a provider behind a tab is never
///     re-read.
///
/// The last one is why "close the app and open it again" used to be the only
/// thing that worked: a full restart was the only event that disposed anything.
///
/// The answer for those three is to wake up when something actually changed
/// rather than poll to find out. Polling would spend a request every few
/// seconds on a number that moves a handful of times a day.
///
/// **One figure does not fit that shape**, and [refreshEvery] is for it alone:
/// how many learners are online right now. It moves continuously, it moves
/// because of strangers, and no event on this device marks it — so there is
/// nothing to wake up on, and a timer is the honest answer rather than the
/// lazy one.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Re-fetch this provider whenever the app returns to the foreground.
///
/// Cancels itself with the provider, so an `autoDispose` provider nobody is
/// watching costs nothing and holds no listener.
void refreshOnResume(Ref ref) {
  final listener = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(listener.dispose);
}

/// Re-fetch this provider on a timer for as long as it is being watched.
///
/// The exception to everything above, and worth saying why. XP and rank move a
/// handful of times a day and always as a consequence of something this app
/// did, so they can be re-read when that something happens. "How many learners
/// are here right now" is the opposite on both counts: it moves continuously,
/// it moves because of *strangers*, and there is no local event to hang a
/// refresh on. Waiting for one means showing a number from whenever the screen
/// happened to open — and that number is the one a learner reads to decide
/// whether it is worth waiting for a partner at all.
///
/// [every] should match the rate the server's own presence actually changes
/// (`presence.py` re-stamps every 15s and counts entries younger than 45s).
/// Asking faster cannot surface anything newer; it only spends requests.
///
/// Two things stop it, and both matter:
///
/// * **The provider going away.** `autoDispose` means that is when the last
///   screen watching it closes, so a lobby left behind stops asking.
/// * **The app going into the background.** A timer keeps firing in a hidden
///   WebView, and a Mini App someone left open in another Telegram chat would
///   otherwise ask forever about a screen nobody is looking at. Coming back
///   re-reads immediately, so the pause costs nothing a learner can see.
///
/// Includes [refreshOnResume]'s behaviour; callers must not add both.
void refreshEvery(Ref ref, Duration every) {
  var foreground = true;
  final timer = Timer.periodic(every, (_) {
    if (foreground) ref.invalidateSelf();
  });
  final lifecycle = AppLifecycleListener(
    onStateChange: (state) {
      final resumed = state == AppLifecycleState.resumed;
      // Only on the edge back in. Re-reading on every lifecycle wobble would
      // put the endpoint on a hair trigger.
      if (resumed && !foreground) ref.invalidateSelf();
      foreground = resumed;
    },
  );
  ref.onDispose(() {
    timer.cancel();
    lifecycle.dispose();
  });
}

/// Tells the tab shell when a screen pushed on top of it has been popped.
///
/// Games, the course and Speaking are siblings of `/home` pushed over it, so
/// finishing one and coming back leaves the shell exactly as it was — same
/// widgets, same providers, same numbers, including the XP that was just
/// earned. `didPopNext` is the moment that stopped being true.
///
/// Wired into the router's `observers` and read by the shell alone; anything
/// else that needs it should subscribe rather than reach for a second one.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
