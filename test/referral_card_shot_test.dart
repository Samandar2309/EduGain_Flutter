import 'dart:io';
import 'dart:ui' as ui;

import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/profile/application/referral.dart';
import 'package:edugain/features/profile/presentation/referral_card.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The invite card, rendered for visual review.
///
/// It exists because the counts were once drawn with `_GlassChip` — a chip
/// designed for the gradient header, white text on white translucency. On the
/// card's white surface all three were invisible, and what shipped was a gap
/// where the numbers should have been. Nothing in a test caught it; the only
/// thing that would have is looking at it.
final _shot = GlobalKey();

Widget _app(ReferralStatus status) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('uz'),
    home: Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: RepaintBoundary(
          key: _shot,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ReferralCard(status: status),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('the counts are legible on the card, not white on white',
      (tester) async {
    const status = ReferralStatus(
      isOpen: true,
      link: 'https://t.me/edugain_bot?start=ref_x',
      friendsJoined: 1,
      bonusSeconds: 600,
      minutesPerFriend: 5,
    );
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(status));
    await tester.pump(const Duration(milliseconds: 300));

    // All three numbers are on screen…
    final l = await AppLocalizations.delegate.load(const Locale('uz'));
    expect(find.text(l.referralFriends(1)), findsOneWidget);
    expect(find.text(l.referralEarned(5)), findsOneWidget);
    expect(find.text(l.referralLeft(10)), findsOneWidget);

    // …and drawn in their own colour rather than the header's white. This is
    // the assertion that would have caught the invisible chips.
    for (final chip in tester.widgetList<CountChip>(find.byType(CountChip))) {
      expect(chip.color, isNot(Colors.white));
    }

    final dumpDir = Platform.environment['VECTOR_DUMP_DIR'];
    if (dumpDir == null) return;
    Directory(dumpDir).createSync(recursive: true);
    final boundary =
        _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dumpDir/referral_card.png').writeAsBytesSync(
      bytes!.buffer.asUint8List(),
    );
  });

  testWidgets('a learner with no friends yet sees no empty numbers',
      (tester) async {
    await tester.pumpWidget(_app(const ReferralStatus(isOpen: true)));
    await tester.pump(const Duration(milliseconds: 300));
    // "0 friends · 0 minutes" reads as a broken feature rather than an unused
    // one, so the row is absent until there is something to say.
    expect(find.byType(CountChip), findsNothing);
  });
}
