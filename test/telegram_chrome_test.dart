import 'package:edugain/core/telegram_safe_area.dart';
import 'package:edugain/core/telegram_webapp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Living inside Telegram's WebView without fighting it.
///
/// Two reported faults, one cause each:
///
/// * **The bottom bar sat on top of the phone's own back/home buttons.** The
///   page runs underneath them and Flutter web reports nothing about it —
///   `MediaQuery.padding` is zero whatever the phone looks like, so every
///   `SafeArea` and every `NavigationBar` had nothing to work from.
/// * **The app closed itself while somebody was reading.** Telegram dismisses
///   a Mini App on a downward drag, which is the same gesture as scrolling a
///   list back to the top.
///
/// Fullscreen is deliberately NOT requested. It was tried and put back: it
/// takes the status bar too, which moved the problem to the other end of the
/// screen. Telegram's own header stays.

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    final m = MediaQuery.of(context);
    return Column(
      children: [
        Text('pad:${m.padding.top},${m.padding.bottom}'),
        Text('view:${m.viewPadding.top},${m.viewPadding.bottom}'),
      ],
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required TelegramInsets insets,
  EdgeInsets device = EdgeInsets.zero,
}) async {
  (TelegramWebApp.insets as ValueNotifier<TelegramInsets>).value = insets;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(padding: device, viewPadding: device),
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

  group('the bottom bar clears the phone buttons', () {
    testWidgets('the inset reaches BOTH padding and viewPadding', (
      tester,
    ) async {
      // Not belt and braces: `SafeArea` reads one and `NavigationBar` reads
      // the other. Setting a single one leaves either the headers or the
      // bottom bar still wrong — the half-fix this was reported as.
      await _pump(tester, insets: const TelegramInsets(bottom: 48, top: 24));
      expect(find.text('pad:24.0,48.0'), findsOneWidget);
      expect(find.text('view:24.0,48.0'), findsOneWidget);
    });

    testWidgets('nothing is touched when there is nothing to avoid', (
      tester,
    ) async {
      await _pump(tester, insets: TelegramInsets.zero);
      expect(find.text('pad:0.0,0.0'), findsOneWidget);
    });

    testWidgets('a real OS padding is never shrunk', (tester) async {
      await _pump(
        tester,
        insets: const TelegramInsets(bottom: 10),
        device: const EdgeInsets.only(top: 47, bottom: 34),
      );
      expect(find.text('pad:47.0,34.0'), findsOneWidget);
    });

    testWidgets('it follows the phone rather than being read once', (
      tester,
    ) async {
      // Rotating, or the keyboard, or Telegram resizing itself.
      await _pump(tester, insets: TelegramInsets.zero);
      expect(find.text('pad:0.0,0.0'), findsOneWidget);

      (TelegramWebApp.insets as ValueNotifier<TelegramInsets>).value =
          const TelegramInsets(bottom: 48);
      await tester.pump();
      expect(find.text('pad:0.0,48.0'), findsOneWidget);
    });
  });

  group('two readings of one gap', () {
    test('take the wider, never the sum', () {
      // CSS env() and Telegram's own inset measure the SAME strip. Adding them
      // would leave a bar floating twice as far off the bottom as it should.
      const css = TelegramInsets(bottom: 48, top: 24);
      const telegram = TelegramInsets(bottom: 44, top: 30);
      final merged = css.largest(telegram);
      expect(merged.bottom, 48);
      expect(merged.top, 30);
    });

    test('one source reporting nothing leaves the other standing', () {
      const css = TelegramInsets(bottom: 48);
      expect(css.largest(TelegramInsets.zero).bottom, 48);
      expect(TelegramInsets.zero.largest(css).bottom, 48);
    });
  });

  group('off the web', () {
    test('there is nothing to disable and nothing to measure', () {
      // The native build must stay completely inert — it has real padding from
      // the OS already.
      TelegramWebApp.disableVerticalSwipes();
      TelegramWebApp.watchInsets();
      expect(TelegramWebApp.insets.value.isZero, isTrue);
    });
  });
}
