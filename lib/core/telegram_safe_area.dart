import 'package:flutter/widgets.dart';

import 'telegram_webapp.dart';

/// Teaches `SafeArea` about Telegram's fullscreen.
///
/// In fullscreen the Mini App owns the entire screen — including the strip
/// behind the clock and battery, and the corner where Telegram floats its own
/// close and menu buttons. The browser reports none of that: on Flutter web
/// `MediaQuery.padding` is zero whatever the phone looks like, so every
/// `SafeArea` in the app becomes a no-op at exactly the moment it matters and
/// the top row of every screen slides under the status bar.
///
/// Telegram does report it, through two insets that have to be added together
/// (see [TelegramInsets]). This folds them into `MediaQuery` at the root, so
/// the thirty-odd screens that already wrap their headers in `SafeArea` start
/// respecting it with no change to any of them. Doing it per screen would mean
/// editing all of them and then remembering forever.
///
/// `maxOf`, not replace: a native build has real padding from the OS, and this
/// must not shrink it. Off the web the insets are always zero, so the whole
/// thing is transparent there.
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
            padding: EdgeInsets.fromLTRB(
              _max(media.padding.left, insets.left),
              _max(media.padding.top, insets.top),
              _max(media.padding.right, insets.right),
              _max(media.padding.bottom, insets.bottom),
            ),
          ),
          child: child,
        );
      },
    );
  }

  static double _max(double a, double b) => a > b ? a : b;
}
