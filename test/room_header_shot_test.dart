@Tags(['shot'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The group room's header line.
///
/// The code used to be the headline and the topic the footnote, which is
/// backwards: "BUART9" is an address, and what a room is about is what makes
/// somebody stay in it. The code still has to be visible — it is what you read
/// out to a friend — but in the small line.
///
/// Rendered because the swap has four states and only one of them is the happy
/// path: a room can have a topic, a name, both, or neither, and the code must
/// never end up printed twice or missing entirely.
///
///     flutter test test/room_header_shot_test.dart --tags shot --run-skipped --update-goldens
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final file in ['segoeui.ttf', 'segoeuib.ttf']) {
      final path = 'C:/Windows/Fonts/$file';
      if (!File(path).existsSync()) continue;
      final loader = FontLoader('Inter')
        ..addFont(
          Future.value(File(path).readAsBytesSync().buffer.asByteData()),
        );
      await loader.load();
    }
    const iconFont =
        'D:/flutter_windows_3.35.4-stable/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(iconFont).existsSync()) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(File(iconFont).readAsBytesSync().buffer.asByteData()),
        );
      await icons.load();
    }
  });

  // The room palette, copied from the screen so the shot matches it.
  const surface = Color(0xFF161528);
  const line = Color(0xFF262541);
  const ink = Color(0xFFF2F1FA);
  const soft = Color(0xFF9E9CC4);
  const faint = Color(0xFF6F6D96);
  const brand = Color(0xFF7C6BF5);
  const brand2 = Color(0xFFA78BFA);

  /// The same resolution the screen does, kept in one place so the shot cannot
  /// drift from the code it is meant to prove.
  ({String title, String subtitle}) resolve({
    required String code,
    required String topic,
    required String name,
  }) => (
    title: topic.isNotEmpty ? topic : (name.isEmpty ? code : name),
    subtitle: topic.isNotEmpty || name.isNotEmpty ? code : '',
  );

  Widget card(String label, {required String code, String topic = '', String name = ''}) {
    final r = resolve(code: code, topic: topic, name: name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: faint,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: line),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [brand, brand2]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      r.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        if (r.subtitle.isNotEmpty)
                          Flexible(
                            child: Text(
                              r.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: soft,
                                fontSize: 11,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        const Icon(Icons.people, size: 11, color: faint),
                        const SizedBox(width: 3),
                        const Text(
                          '2/50',
                          style: TextStyle(
                            color: faint,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    '04:12',
                    style: TextStyle(
                      color: ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text('Suhbat vaqti',
                      style: TextStyle(color: faint, fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  testWidgets('topic on top, code below — all four room shapes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 420 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFF0D0C1B),
        ),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                card('A TOPIC — the ordinary case',
                    code: 'BUART9', topic: 'Erkin suhbat'),
                card('A NAME, NO TOPIC',
                    code: 'BUART9', name: 'Kechki suhbat'),
                card('BOTH — the topic wins the headline',
                    code: 'BUART9', topic: 'Sayohat', name: 'Kechki suhbat'),
                card('NEITHER — the code takes the headline, alone',
                    code: 'BUART9'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('shots/room_header.png'),
    );
  });
}
