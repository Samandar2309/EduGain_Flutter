/// Driving the tutor's mouth from words rather than from a clock.
///
/// The server-rendered voice arrives as PCM, so the mouth can be driven from
/// the audio's own loudness envelope — the mouth is open exactly where the
/// sound is. A device voice gives no audio at all: the browser speaks it, and
/// all the app ever sees is the text it handed over.
///
/// What it does get is `onboundary`, which fires as each word begins. That is
/// enough to put the mouth on the words: open through a word, closed in the gap
/// after it. The alternative — and what was shipping — is an oscillation driven
/// by elapsed time alone, which flaps at a steady rate regardless of what is
/// being said, and reads as a puppet whose mouth happens to be moving while a
/// voice happens to be playing.
library;

import 'dart:math' as math;

/// How long a word of [chars] characters takes to say at [rate].
///
/// From ~150 words per minute at rate 1.0 and an average English word of about
/// six characters with its space: roughly fifteen characters a second. It is an
/// estimate and it does not need to be better than one — it only has to end
/// before the next boundary arrives, and a word that finishes early leaves the
/// mouth closed for a moment, which is what a gap between words looks like.
Duration wordDuration(int chars, {double rate = 1.0}) {
  final safeRate = rate <= 0 ? 1.0 : rate;
  final seconds = math.max(1, chars) / (15.0 * safeRate);
  return Duration(microseconds: (seconds * 1e6).round());
}

/// How open the mouth is [progress] of the way through a word, 0..1.
///
/// Two shapes multiplied. The arch opens the mouth at the start of the word and
/// closes it at the end, which is what puts a visible seam between words — the
/// thing a steady flap can never do. The flutter on top is a beat per syllable,
/// so a long word is a sequence of movements instead of one long gape.
double lipLevelInWord(double progress, int chars) {
  final p = progress.clamp(0.0, 1.0);
  final arch = math.sin(math.pi * p);
  final syllables = math.max(1, (chars / 3).round());
  final flutter = 0.7 + 0.3 * math.sin(p * syllables * 2 * math.pi);
  return (arch * flutter).clamp(0.0, 1.0);
}

/// Where the word starting at [index] ends in [text].
///
/// Measured from the text the engine was given rather than read off the event.
/// `charLength` is in the spec and missing from several engines, and a word
/// length that is sometimes right is worse than one that always is.
int wordLengthAt(String text, int index) {
  if (index < 0 || index >= text.length) return 4;
  var end = index;
  while (end < text.length && !_isBreak(text.codeUnitAt(end))) {
    end++;
  }
  return math.max(1, end - index);
}

bool _isBreak(int code) =>
    code == 0x20 || code == 0x0A || code == 0x0D || code == 0x09;
