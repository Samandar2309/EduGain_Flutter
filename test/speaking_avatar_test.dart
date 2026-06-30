import 'package:edugain/features/speaking/presentation/avatar/speaking_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders and animates without error across emotions/level',
      (tester) async {
    final level = ValueNotifier<double>(0);
    addTearDown(level.dispose);

    Widget app(String emotion) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SpeakingAvatar(emotion: emotion, level: level, size: 160),
        ),
      ),
    );

    await tester.pumpWidget(app('neutral'));
    expect(find.byType(SpeakingAvatar), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Drive the mouth via the level and advance frames — the ticker repaints.
    level.value = 0.8;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 100));

    // Switch emotion — the expression eases without throwing.
    await tester.pumpWidget(app('surprised'));
    await tester.pump(const Duration(milliseconds: 100));
    level.value = 0.0;
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}
