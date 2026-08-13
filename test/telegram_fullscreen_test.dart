import 'package:edugain/core/telegram_safe_area.dart';
import 'package:edugain/core/telegram_webapp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opening the Mini App on the whole screen, without hiding its own header
/// under the clock.
///
/// Fullscreen is two halves and only one of them is the interesting one.
/// Asking Telegram for the screen is a single call; the half that decides
/// whether it looks finished or broken is the insets. In fullscreen the page
/// owns the strip behind the status bar AND the corner where Telegram floats
/// its close and menu buttons — and the browser reports neither, so on Flutter
/// web `MediaQuery.padding` stays zero and every `SafeArea` in the app quietly
/// becomes a no-op at exactly the moment it is needed.
///
/// Thirty-odd screens already wrap their headers in `SafeArea`. Folding
/// Telegram's numbers into `MediaQuery` at the root is what makes all of them
/// correct without touching any of them.

/// Reports whatever padding it was handed, the way a real screen's `SafeArea`
/// reads it.
class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    final p = MediaQuery.of(context).padding;
    return Text('${p.top},${p.bottom},${p.left},${p.right}');
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required TelegramInsets insets,
  EdgeInsets devicePadding = EdgeInsets.zero,
}) async {
  (TelegramWebApp.insets as ValueNotifier<TelegramInsets>).value = insets;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(padding: devicePadding),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: TelegramSafeArea(child: _Probe()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  tearDown(() {
    (TelegramWebApp.insets as ValueNotifier<TelegramInsets>).value =
        TelegramInsets.zero;
  });

  group('what SafeArea is told', () {
    testWidgets('nothing at all when the app is not fullscreen', (
      tester,
    ) async {
      // The ordinary case, and it must cost nothing: outside fullscreen
      // Telegram reports zeroes and the tree is passed through untouched.
      await _pump(tester, insets: TelegramInsets.zero);
      expect(find.text('0.0,0.0,0.0,0.0'), findsOneWidget);
    });

    testWidgets('the status bar strip once fullscreen is on', (tester) async {
      await _pump(tester, insets: const TelegramInsets(top: 44, bottom: 34));
      expect(find.text('44.0,34.0,0.0,0.0'), findsOneWidget);
    });

    testWidgets('never less than the device already asked for', (tester) async {
      // A native build has real padding from the OS. Replacing rather than
      // taking the larger would let a notch be un-reported by a client that
      // knows nothing about it.
      await _pump(
        tester,
        insets: const TelegramInsets(top: 10),
        devicePadding: const EdgeInsets.only(top: 47, bottom: 34),
      );
      expect(find.text('47.0,34.0,0.0,0.0'), findsOneWidget);
    });

    testWidgets('it follows Telegram rather than being read once', (
      tester,
    ) async {
      // Entering fullscreen, rotating the phone and Telegram moving its own
      // controls all change these while the app is running.
      await _pump(tester, insets: TelegramInsets.zero);
      expect(find.text('0.0,0.0,0.0,0.0'), findsOneWidget);

      (TelegramWebApp.insets as ValueNotifier<TelegramInsets>).value =
          const TelegramInsets(top: 59);
      await tester.pump();
      expect(find.text('59.0,0.0,0.0,0.0'), findsOneWidget);
    });
  });

  group('the two insets Telegram reports', () {
    test('are added, because they do not overlap', () {
      // The device's strip is measured from the screen edge; Telegram's own
      // buttons sit below it. Honouring only one puts the app's top row under
      // the other.
      const device = TelegramInsets(top: 44, bottom: 34);
      const controls = TelegramInsets(top: 46);
      expect((device + controls).top, 90);
      expect((device + controls).bottom, 34);
    });

    test('zero is recognised so the common path stays free', () {
      expect(TelegramInsets.zero.isZero, isTrue);
      expect(const TelegramInsets(top: 1).isZero, isFalse);
    });
  });

  group('asking for the screen', () {
    test('is refused off the web, where there is no Telegram at all', () {
      // The native build must not pretend. A false return is what keeps the
      // caller from assuming the status bar is now its own.
      expect(TelegramWebApp.requestFullscreen(), isFalse);
    });

    test('and watching insets is harmless there too', () {
      TelegramWebApp.watchInsets();
      expect(TelegramWebApp.insets.value.isZero, isTrue);
    });
  });
}
