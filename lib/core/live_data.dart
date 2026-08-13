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
/// The answer here is to wake up when something actually changed rather than
/// poll to find out. Polling would spend a request every few seconds on a
/// number that moves a handful of times a day.
library;

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
