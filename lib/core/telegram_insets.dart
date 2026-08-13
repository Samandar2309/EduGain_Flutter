import 'package:flutter/widgets.dart';

/// The strips of screen the app must not draw into.
///
/// Inside Telegram's WebView on Android the page extends underneath the
/// system navigation buttons, and Flutter web reports none of it —
/// `MediaQuery.padding` is zero whatever the phone looks like. So the bottom
/// navigation bar sat under the back/home/recents buttons, which is what was
/// reported.
///
/// Measured twice because neither source covers every phone:
///
/// * CSS `env(safe-area-inset-*)`, read from a probe element in
///   `web/index.html`. Works on every Telegram client, which matters because
///   the phones that most need a bottom inset are the least likely to be
///   running a current one.
/// * Telegram's own `safeAreaInset`, which only exists from Bot API 8.0 but is
///   more accurate when it is there.
///
/// They measure the SAME thing, so they are combined with [largest] rather
/// than added — summing two readings of one gap would double it.
@immutable
class TelegramInsets {
  const TelegramInsets({
    this.top = 0,
    this.bottom = 0,
    this.left = 0,
    this.right = 0,
  });

  static const zero = TelegramInsets();

  final double top;
  final double bottom;
  final double left;
  final double right;

  /// The wider reading per edge. See the note above on why this is not `+`.
  TelegramInsets largest(TelegramInsets other) => TelegramInsets(
    top: _max(top, other.top),
    bottom: _max(bottom, other.bottom),
    left: _max(left, other.left),
    right: _max(right, other.right),
  );

  EdgeInsets get padding => EdgeInsets.fromLTRB(left, top, right, bottom);

  bool get isZero => top == 0 && bottom == 0 && left == 0 && right == 0;

  static double _max(double a, double b) => a > b ? a : b;

  @override
  bool operator ==(Object other) =>
      other is TelegramInsets &&
      other.top == top &&
      other.bottom == bottom &&
      other.left == left &&
      other.right == right;

  @override
  int get hashCode => Object.hash(top, bottom, left, right);

  @override
  String toString() => 'TelegramInsets(t:$top, b:$bottom, l:$left, r:$right)';
}
