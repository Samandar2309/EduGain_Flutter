@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/features/speaking/application/correction_panel_controller.dart';
import 'package:edugain/features/speaking/application/providers.dart';
import 'package:edugain/features/speaking/domain/models.dart';
import 'package:edugain/features/speaking/presentation/speaking_chat_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the correction panel costs the avatar, before and after.
///
///     flutter test test/correction_panel_shot_test.dart --tags shot --run-skipped --update-goldens
void main() {
  setUpAll(() async {
    // Registered under the fallback family as well as 'Inter'. The panel draws
    // with `RichText`, which takes the style it is handed and does NOT merge
    // the theme's font in -- so a style with no family lands on the test
    // harness's box glyphs, and the shot shows the layout of the thing rather
    // than the thing.
    for (final family in ['Inter', 'Roboto', '.SF UI Text']) {
      for (final file in ['segoeui.ttf', 'segoeuib.ttf']) {
        final path = 'C:/Windows/Fonts/$file';
        if (!File(path).existsSync()) continue;
        final loader = FontLoader(family)
          ..addFont(
            Future.value(File(path).readAsBytesSync().buffer.asByteData()),
          );
        await loader.load();
      }
    }
    SharedPreferences.setMockInitialValues({});
  });

  // The real coaching from the reported screenshot.
  const coaching = Coaching(
    understood: 'for us today. you you Actually I didn\'t have any adventures '
        'but I listened to a new Uzbek playlist',
    hasErrors: true,
    correction: "Actually, I didn't have any adventures for us today, but I "
        'listened to a new Uzbek playlist and enjoyed it.',
    naturalVersion: "Actually, I didn't have any adventures today, but I "
        'listened to a new Uzbek playlist and really enjoyed it.',
    grammarPoint: 'word_order',
    why: "So'zlar tartibi noto'g'ri: 'for us today' va ikki marta 'you' "
        "keraksiz qo'shilgan; gapni to'g'ri tuzish kerak.",
    vocabulary: <String>[],
    pronunciation: <String>[],
    errorTags: <String>['word_order'],
    emotion: 'neutral',
  );

  Widget frame({required bool collapsed, required String caption}) =>
      ProviderScope(
        overrides: [
          correctionPanelProvider.overrideWith(
            (ref) => _FixedPanel(collapsed),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // Without a real family every glyph renders as a box, and a shot of
          // boxes shows the layout but not the thing being judged.
          theme: ThemeData(fontFamily: 'Inter', useMaterial3: true),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('uz'),
          home: Scaffold(
            backgroundColor: const Color(0xFF241B3A),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  // Stands in for the avatar: whatever this panel does not
                  // cover is the tutor's face.
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF6D4AA8), Color(0xFF3B2A63)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'AVATAR',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Consumer(
                      builder: (context, ref, _) => CoachingStrip(
                        coaching: coaching,
                        accent: const Color(0xFF7C5CFF),
                        collapsed: ref.watch(correctionPanelProvider),
                        onToggle: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  testWidgets('correction panel, folded and open', (tester) async {
    tester.view.physicalSize = const Size(760 * 2, 620 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Inter', useMaterial3: true),
        home: Scaffold(
          backgroundColor: const Color(0xFF120C22),
          body: Row(
            children: [
              Expanded(
                child: frame(
                  collapsed: true,
                  caption: 'AFTER  —  folded: the fix stays, the face is back',
                ),
              ),
              Expanded(
                child: frame(
                  collapsed: false,
                  caption: 'BEFORE  —  open: four lines over the avatar',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Row).first,
      matchesGoldenFile('shots/correction_panel.png'),
    );
  }, skip: !Platform.isWindows);
}

/// A controller pinned to one state, so each half of the shot shows the state
/// it is captioned with rather than whatever prefs happened to hold.
class _FixedPanel extends CorrectionPanelController {
  _FixedPanel(bool collapsed) {
    state = collapsed;
  }

  @override
  Future<void> toggle() async {}
}
