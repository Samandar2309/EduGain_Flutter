import 'package:flutter/widgets.dart';

import 'telegram_webapp.dart';

/// Teaches the app where the phone's own furniture is.
///
/// Inside Telegram's WebView the page runs underneath the system navigation
/// buttons, and Flutter web reports none of it — `MediaQuery.padding` is zero
/// whatever the phone looks like. So the bottom navigation bar rendered on top
/// of the back/home/recents buttons, which is what was reported.
///
/// The numbers come from the device (CSS `env()`) and from Telegram, whichever
/// reads wider — see [TelegramInsets]. This folds them into `MediaQuery` at the
/// root so every screen becomes correct at once. Doing it per screen would mean
/// editing thirty of them and then remembering forever.
///
/// **Both `padding` and `viewPadding` are set**, and that is not belt and
/// braces: `SafeArea` reads the first, `NavigationBar` reads the second. Set
/// only one and either the headers or the bottom bar stays wrong, which is
/// exactly the half-fix this was reported as.
///
/// Taken as the larger of what is already there, never replacing it: a native
/// build has real padding from the OS and this must not shrink it. Off the web
/// the insets are always zero, so the whole thing is transparent there.
class TelegramSafeArea extends StatelessWidget {
  const TelegramSafeArea({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TelegramInsets>(
      valueListenable: TelegramWebApp.insets,
      builder: (context, insets, _) {
        if (insets.isZero) return child;
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            padding: _merge(media.padding, insets),
            viewPadding: _merge(media.viewPadding, insets),
          ),
          child: child,
        );
      },
    );
  }

  static EdgeInsets _merge(EdgeInsets existing, TelegramInsets insets) =>
      EdgeInsets.fromLTRB(
        _max(existing.left, insets.left),
        _max(existing.top, insets.top),
        _max(existing.right, insets.right),
        _max(existing.bottom, insets.bottom),
      );

  static double _max(double a, double b) => a > b ? a : b;
}
