import 'package:edugain/features/speaking/data/capture_health.dart';
import 'package:flutter_test/flutter_test.dart';

/// Noticing a microphone that has stopped without saying so.
///
/// This is the failure behind "it stops hearing me after two turns": the
/// browser mutes the track or suspends the audio context, the stream neither
/// ends nor errors, and every flag the app owns still reads "listening". The
/// learner talks into nothing, the silence detector never fires because no
/// audio arrives to be measured, and typing keeps working — which is what made
/// it look like a permission problem for so long.
///
/// The only honest question is whether audio has arrived recently. These pin
/// the three states that question has to distinguish: working, stalled, and
/// closed — because treating "closed" as "stalled" would have the healer
/// rebuilding the microphone forever while the app sat idle.
void main() {
  late DateTime clock;
  CaptureHealth make() =>
      CaptureHealth(stallAfter: const Duration(seconds: 2), now: () => clock);

  setUp(() => clock = DateTime(2026, 8, 17, 12));

  void tick(Duration d) => clock = clock.add(d);

  group('a working capture', () {
    test('is not stalled while audio keeps arriving', () {
      final h = make()..opened();
      for (var i = 0; i < 50; i++) {
        tick(const Duration(milliseconds: 100));
        h.heard();
        expect(h.isStalled, isFalse, reason: 'reading $i');
      }
    });

    test('survives a gap shorter than the window', () {
      final h = make()..opened();
      tick(const Duration(milliseconds: 1900));
      expect(h.isStalled, isFalse);
      h.heard();
      tick(const Duration(milliseconds: 1900));
      expect(h.isStalled, isFalse);
    });

    test('reports how long it has been quiet', () {
      final h = make()..opened();
      tick(const Duration(milliseconds: 700));
      expect(h.sinceLastAudio, const Duration(milliseconds: 700));
    });
  });

  group('a stalled capture', () {
    test('is caught once the window passes', () {
      final h = make()..opened();
      tick(const Duration(milliseconds: 2001));
      expect(h.isStalled, isTrue);
    });

    test('a stream that never delivers ages like one that stopped', () {
      // The nastier half of the same bug: `startStream` resolves, the handle is
      // non-null, and not one chunk ever arrives. Opening has to start the
      // clock or this state is invisible for ever.
      final h = make()..opened();
      expect(h.isOpen, isTrue);
      tick(const Duration(seconds: 10));
      expect(h.isStalled, isTrue);
    });

    test('recovers the moment real audio comes back', () {
      final h = make()..opened();
      tick(const Duration(seconds: 5));
      expect(h.isStalled, isTrue);
      h.heard();
      expect(h.isStalled, isFalse);
      expect(h.sinceLastAudio, Duration.zero);
    });
  });

  group('a closed capture', () {
    test('is never stalled, however long it sits', () {
      final h = make()
        ..opened()
        ..closed();
      tick(const Duration(hours: 1));
      expect(h.isStalled, isFalse);
      expect(h.isOpen, isFalse);
      // Zero, not "an hour": a healer that read a closed capture as a silent
      // one would rebuild the microphone on a loop for the whole time the app
      // was idle between conversations.
      expect(h.sinceLastAudio, Duration.zero);
    });

    test('a fresh one is closed, not stalled', () {
      final h = make();
      tick(const Duration(hours: 1));
      expect(h.isOpen, isFalse);
      expect(h.isStalled, isFalse);
    });

    test('reopening starts the window again', () {
      final h = make()
        ..opened()
        ..closed();
      tick(const Duration(hours: 1));
      h.opened();
      expect(h.isStalled, isFalse);
      tick(const Duration(milliseconds: 2001));
      expect(h.isStalled, isTrue);
    });
  });

  test('the shipped window is short enough to be one beat', () {
    // Long enough that a browser scheduling hiccup is not read as a dead
    // device; short enough that a learner notices a pause, not a broken app.
    expect(CaptureHealth().stallAfter, const Duration(milliseconds: 1500));
  });
}
