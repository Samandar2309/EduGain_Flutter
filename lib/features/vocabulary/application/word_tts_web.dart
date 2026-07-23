import 'dart:js_interop';

/// Web pronunciation via the browser's Web Speech API. The key to *clean*
/// English is not trusting the device default voice (often the phone's
/// Uzbek/Russian engine reading English badly) — we explicitly pick the best
/// available English voice and speak with it.
extension type _SpeechSynthesis._(JSObject _) implements JSObject {
  external void speak(_Utterance u);
  external void cancel();
  external JSArray<_Voice> getVoices();
  external set onvoiceschanged(JSFunction? f);
}

extension type _Voice._(JSObject _) implements JSObject {
  external String get lang;
  external String get name;
  external bool get localService;
}

@JS('SpeechSynthesisUtterance')
extension type _Utterance._(JSObject _) implements JSObject {
  external factory _Utterance(String text);
  external set lang(String value);
  external set rate(double value);
  external set pitch(double value);
  external set volume(double value);
  external set voice(_Voice? value);
}

@JS('speechSynthesis')
external _SpeechSynthesis? get _speechSynthesis;

_Voice? _chosen;
bool _listening = false;

/// Scores English voices, preferring en-US and known natural engines
/// (Google / Microsoft Natural / Apple Siri) over robotic local ones.
_Voice? _pickEnglish(_SpeechSynthesis synth) {
  final voices = synth.getVoices().toDart;
  _Voice? best;
  var bestScore = -1;
  for (final v in voices) {
    final lang = v.lang.toLowerCase().replaceAll('_', '-');
    if (!lang.startsWith('en')) continue;
    var score = 0;
    if (lang.startsWith('en-us')) {
      score += 6;
    } else if (lang.startsWith('en-gb')) {
      score += 4;
    } else {
      score += 2;
    }
    final name = v.name.toLowerCase();
    if (name.contains('google')) score += 5;
    if (name.contains('natural')) score += 5;
    if (name.contains('siri')) score += 4;
    for (final good in const ['samantha', 'aaron', 'daniel', 'karen', 'zira', 'ava']) {
      if (name.contains(good)) score += 3;
    }
    if (!v.localService) score += 1; // cloud voices are usually smoother
    if (score > bestScore) {
      bestScore = score;
      best = v;
    }
  }
  return best;
}

void _ensureVoice(_SpeechSynthesis synth) {
  _chosen ??= _pickEnglish(synth);
  // getVoices() is often empty until the engine loads them — re-pick then.
  if (!_listening) {
    _listening = true;
    try {
      synth.onvoiceschanged = (() => _chosen = _pickEnglish(synth)).toJS;
    } catch (_) {}
  }
}

class WordTtsPlatform {
  static bool get supported {
    try {
      return _speechSynthesis != null;
    } catch (_) {
      return false;
    }
  }

  static void speak(String word) {
    try {
      final synth = _speechSynthesis;
      if (synth == null) return;
      _ensureVoice(synth);
      synth.cancel(); // never let words pile up
      final u = _Utterance(word)
        ..lang = 'en-US'
        ..rate = 0.9
        ..pitch = 1.0
        ..volume = 1.0;
      final v = _chosen;
      if (v != null) u.voice = v;
      synth.speak(u);
    } catch (_) {
      // speech engine hiccup — silently ignore
    }
  }

  static void stop() {
    try {
      _speechSynthesis?.cancel();
    } catch (_) {}
  }
}
