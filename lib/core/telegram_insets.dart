import 'package:flutter/widgets.dart';

/// The strips of screen a fullscreen Mini App must not draw into.
///
/// Two of them, and both are needed. Telegram reports the DEVICE's own unsafe
/// area (`safeAreaInset` — the notch, the status bar, the home indicator) and,
/// separately, the space its OWN controls occupy (`contentSafeAreaInset` — in
/// fullscreen the close and menu buttons float over the page rather than
/// sitting in a header). Honouring only the first puts the app's top row under
/// Telegram's close button; honouring only the second puts it under the clock.
///
/// Outside fullscreen every value is zero, which is why this can be applied
/// unconditionally.
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

  /// The two insets stacked. Telegram reports them independently and they
  /// overlap in neither direction — the device's strip is measured from the
  /// screen edge, its own controls sit below that.
  TelegramInsets operator +(TelegramInsets other) => TelegramInsets(
    top: top + other.top,
    bottom: bottom + other.bottom,
    left: left + other.left,
    right: right + other.right,
  );

  EdgeInsets get padding =>
      EdgeInsets.fromLTRB(left, top, right, bottom);

  bool get isZero => top == 0 && bottom == 0 && left == 0 && right == 0;

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
  String toString() =>
      'TelegramInsets(t:$top, b:$bottom, l:$left, r:$right)';
}
