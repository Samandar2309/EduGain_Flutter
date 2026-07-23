import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edugain/features/speaking/presentation/avatar/avatar_stage.dart';
import 'package:edugain/features/speaking/presentation/avatar/avatar_state.dart';
import 'package:edugain/features/speaking/presentation/avatar/vector_hero.dart';
import 'package:edugain/features/speaking/presentation/avatar/vector_hero_view.dart';
import 'package:edugain/features/speaking/presentation/scenario_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget host(ScenarioBackdrop backdrop, ValueNotifier<double> level) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: AvatarStage(
                backdrop: backdrop,
                emotion: 'happy',
                state: AvatarState.talking,
                level: level,
                fillScreen: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('every scenario shows the code-drawn vector hero', (
    tester,
  ) async {
    final level = ValueNotifier<double>(0.4);
    await tester.pumpWidget(host(backdropForKey('taxi'), level));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(VectorHeroView), findsOneWidget);
    // A few animation frames render without errors.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    level.dispose();
  });

  testWidgets('the scenario picks the matching outfit', (tester) async {
    expect(backdropForKey('doctor').heroOutfit, HeroOutfit.doctor);
    expect(backdropForKey('coffee').heroOutfit, HeroOutfit.barista);
    expect(backdropForKey('interview').heroOutfit, HeroOutfit.business);
    expect(backdropForKey('daily').heroOutfit, HeroOutfit.casual);
    expect(backdropForKey('taxi').heroOutfit, HeroOutfit.concierge);
  });

  testWidgets('onReady fires immediately after the first frame', (
    tester,
  ) async {
    final level = ValueNotifier<double>(0);
    var ready = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarStage(
            backdrop: backdropForKey('taxi'),
            emotion: 'neutral',
            state: AvatarState.idle,
            level: level,
            onReady: () => ready = true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(ready, isTrue);
    level.dispose();
  });
}
