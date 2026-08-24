import 'dart:async';
import 'dart:js_interop';

import 'voice_gender.dart';

/// The tutor speaking through the browser's own engine, with no network call.
///
/// The vocabulary section already pronounces single words this way. What the
/// conversation needs on top of that is **an end signal**: the microphone
/// re-opens the moment the tutor stops, so "fire and forget" would have the app
/// listening to itself. `speak` therefore resolves on `onend`.
///
/// It is deliberately its own file rather than a flag on the word version —
/// their failure modes differ. A word that never finishes speaking is a missed
/// pronunciation; a sentence that never finishes speaking hangs the turn.
extension type _SpeechSynthesis._(JSObject _) implements JSObject {
  external void speak(_Utterance u);
  external void cancel();
  external void pause();
  external void resume();
  external JSArray<_Voice> getVoices();
  external set onvoiceschanged(JSFunction? f);
  external bool get speaking;
}

extension type _Voice._(JSObject _) implements JSObject {
  external String get lang;
  external String get name;
  external String get voiceURI;
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
  external set onend(JSFunction? f);
  external set onerror(JSFunction? f);
  external set onstart(JSFunction? f);
  external set onboundary(JSFunction? f);
}

/// A word boundary the engine reports as it reads.
///
/// `charIndex` is the offset into the text it was given, so the caller can look
/// up which word just began. `charLength` exists in the spec but is absent on
/// several engines, so it is deliberately not declared — the word is measured
/// from the text instead, which every engine agrees on.
extension type _BoundaryEvent._(JSObject _) implements JSObject {
  external int get charIndex;
  external String get name;
}

@JS('speechSynthesis')
external _SpeechSynthesis? get _speechSynthesis;

@JS('navigator.userAgent')
external String? get _userAgent;

_Voice? _chosen;
bool _listening = false;

/// How good this voice is as an English tutor, higher is better.
///
/// The device default is often the handset's Uzbek or Russian engine reading
/// English, which is the worst thing a learner can be given to copy — the voice
/// IS the pronunciation model. Scored rather than "first match" for that
/// reason, and the same score orders the picker so the top row is the one the
/// app would have chosen by itself.
int _score(_Voice v) {
  final lang = v.lang.toLowerCase().replaceAll('_', '-');
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
  // Apple's word for the same thing. An iPhone ships a compact voice and a
  // downloaded one under the SAME first name, and only the suffix separates
  // them — so without this the picker chose "Aaron" over "Aaron (Enhanced)"
  // on a coin toss, and the tutor sounded like a machine from the nineties on
  // one platform and like a person on the other.
  if (name.contains('enhanced') || name.contains('premium')) score += 5;
  if (name.contains('siri')) score += 4;
  // The tutor has a face and it is a boy's, so a man's voice leads — a woman's
  // coming out of him reads as a bug rather than as a choice.
  if (guessGender(v.name) == 'male') score += 4;
  if (!v.localService) score += 1;
  return score;
}

_Voice? _pickEnglish(_SpeechSynthesis synth) {
  _Voice? best;
  var bestScore = -1;
  for (final v in synth.getVoices().toDart) {
    if (!v.lang.toLowerCase().replaceAll('_', '-').startsWith('en')) continue;
    final score = _score(v);
    if (score > bestScore) {
      bestScore = score;
      best = v;
    }
  }
  return best;
}

/// The learner's own pick, kept apart from `_chosen` on purpose.
///
/// `onvoiceschanged` fires whenever the engine finishes loading its roster, and
/// it used to re-run the scorer — which would silently overwrite a choice the
/// learner had just made. Their id is re-resolved instead.
String? _preferredId;

void _ensureVoice(_SpeechSynthesis synth) {
  _chosen ??= _pickEnglish(synth);
  if (!_listening) {
    _listening = true;
    try {
      synth.onvoiceschanged = (() {
        final wanted = _preferredId;
        if (wanted != null) {
          DeviceTtsPlatform.select(wanted);
          if (_chosen != null) return;
        }
        _chosen = _pickEnglish(synth);
      }).toJS;
    } catch (_) {}
  }
}

/// One voice this handset can speak English with.
///
/// `id` is the engine's own `voiceURI`, which is what survives being written to
/// preferences — names collide across engines and the index moves as the OS
/// installs voices.
class DeviceVoice {
  const DeviceVoice({
    required this.id,
    required this.name,
    required this.lang,
    required this.gender,
  });

  final String id;
  final String name;
  final String lang;

  /// Guessed from the name, and honestly labelled as a guess: the Web Speech
  /// API does not report gender at all. The tutor has a boy's face, so a man's
  /// voice is what most learners will want — but a wrong guess here only
  /// mislabels a row the learner can hear for themselves.
  final String gender;
}

class DeviceTtsPlatform {
  /// Every English voice this device offers, best first.
  ///
  /// English only: the tutor speaks English, and a phone's Uzbek or Russian
  /// engine reading it is the worst thing a learner can be given to copy. The
  /// list is ordered by the same score that picks the default, so the top row
  /// is the one the app would have chosen anyway.
  static List<DeviceVoice> voices() {
    try {
      final synth = _speechSynthesis;
      if (synth == null) return const [];
      _ensureVoice(synth);
      final scored = <(int, _Voice)>[];
      for (final v in synth.getVoices().toDart) {
        if (!v.lang.toLowerCase().replaceAll('_', '-').startsWith('en')) {
          continue;
        }
        scored.add((_score(v), v));
      }
      scored.sort((a, b) => b.$1.compareTo(a.$1));
      final all = [
        for (final (_, v) in scored)
          DeviceVoice(
            id: v.voiceURI.isEmpty ? v.name : v.voiceURI,
            name: v.name,
            lang: v.lang,
            gender: guessGender(v.name),
          ),
      ];

      // Men only, because the tutor has a boy's face — a woman's voice coming
      // out of him reads as a bug rather than as a choice the learner made.
      //
      // Filtered on a NAME, though, and plenty of handsets ship voices whose
      // names say nothing ("English (United States)"). Dropping those would
      // leave some devices with an empty picker and no voice at all, so they
      // are kept: an unlabelled voice the learner can audition beats no voice.
      final men = all.where((v) => v.gender != 'female').toList();
      return men.isEmpty ? all : men;
    } catch (_) {
      return const [];
    }
  }

  /// Speak with this voice from now on. An id the device no longer has falls
  /// back to the scored default rather than going silent — voices come and go
  /// as the OS updates.
  static void select(String voiceId) {
    _preferredId = voiceId;
    try {
      final synth = _speechSynthesis;
      if (synth == null) return;
      for (final v in synth.getVoices().toDart) {
        if (v.voiceURI == voiceId || v.name == voiceId) {
          _chosen = v;
          return;
        }
      }
    } catch (_) {}
  }

  static bool get supported {
    try {
      return _speechSynthesis != null;
    } catch (_) {
      return false;
    }
  }

  /// The English voice this device will actually use, for diagnostics — a
  /// handset with no English voice at all is a real case, and it is invisible
  /// otherwise.
  static String get voiceName {
    try {
      final synth = _speechSynthesis;
      if (synth == null) return '';
      _ensureVoice(synth);
      final v = _chosen;
      return v == null ? '' : '${v.name} (${v.lang})';
    } catch (_) {
      return '';
    }
  }

  /// Speak [text], resolving when the engine says it has finished.
  ///
  /// Never rejects: a speech engine that errors must not break the turn, and
  /// the caller's contract is "this resolves when the tutor has stopped".
  static Future<void> speak(
    String text, {
    double rate = 1.0,
    void Function()? onStart,
    void Function(int charIndex)? onWord,
  }) async {
    final synth = _speechSynthesis;
    if (synth == null) return;
    final done = Completer<void>();
    try {
      _ensureVoice(synth);
      // `getVoices()` is usually EMPTY on the first call — the engine loads its
      // roster asynchronously — so the very first utterance could go out with
      // no voice attached. The browser then falls back to its own default,
      // which on a Russian-locale desktop is a Russian woman reading English:
      // the exact thing the scorer exists to avoid, and it never corrected
      // itself because `_chosen` was only ever picked once.
      _chosen ??= _pickEnglish(synth);
      final u = _Utterance(text)
        ..lang = 'en-US'
        ..rate = rate
        ..pitch = 1.0
        ..volume = 1.0;
      final v = _chosen;
      if (v != null) {
        u.voice = v;
      } else {
        // Still nothing English on this machine. `lang` is the only steer left;
        // it at least asks the default engine for English rather than letting
        // it read with whatever locale it was installed for.
        u.lang = 'en-US';
      }
      // Chrome stops speaking after about fifteen seconds.
      //
      // A long-standing engine bug, and this app walks straight into it: the
      // whole reply is handed over as ONE utterance, because splitting it is
      // what let the browser drop the second half. A three-sentence answer is
      // already ten to fifteen seconds.
      //
      // `pause()` immediately followed by `resume()` resets the internal timer
      // that ends it. It only starts after ten seconds of continuous speech, so
      // ordinary short replies — nearly all of them — never touch it.
      //
      // NOT on WebKit. The bug being worked around is Chrome's, and iOS does
      // not have it — but iOS does have its own: `pause()` there can stop an
      // utterance that `resume()` then fails to restart. Applying this
      // everywhere would cure a bug the iPhone never had by introducing one it
      // never had either, in the middle of the tutor's longest answers.
      Timer? keepAlive;
      if (platform != 'ios') {
        keepAlive = Timer(const Duration(seconds: 10), () {
          keepAlive = Timer.periodic(const Duration(seconds: 10), (t) {
            try {
              if (!synth.speaking) {
                t.cancel();
                return;
              }
              synth
                ..pause()
                ..resume();
            } catch (_) {
              t.cancel();
            }
          });
        });
      }

      void finish() {
        keepAlive?.cancel();
        if (!done.isCompleted) done.complete();
      }

      u.onend = ((JSObject _) => finish()).toJS;
      u.onerror = ((JSObject _) => finish()).toJS;
      // When the SOUND starts, which is not when `speak` is called: utterances
      // queue, so a sentence handed over early can wait behind another. The
      // mouth has to move on this and not on the handover.
      if (onStart != null) {
        u.onstart = ((JSObject _) => onStart()).toJS;
      }
      // Word boundaries are the only real timing a browser gives away, and
      // they are what makes the mouth belong to the words rather than merely
      // run alongside them. Not every engine emits them — the caller keeps a
      // fallback for that — but where they exist they are exact.
      if (onWord != null) {
        u.onboundary = ((JSObject event) {
          try {
            final e = event as _BoundaryEvent;
            if (e.name == 'word') onWord(e.charIndex);
          } catch (_) {
            // A boundary that cannot be read is one the fallback covers.
          }
        }).toJS;
      }
      synth.speak(u);
    } catch (_) {
      return;
    }
    return done.future;
  }

  static void stop() {
    try {
      _speechSynthesis?.cancel();
    } catch (_) {}
  }

  /// Load the speech engine now, so the tutor's first sentence does not pay for
  /// it.
  ///
  /// Android's engine is not resident: the first `speak` of a session loads the
  /// voice before any sound comes out, which the learner hears as the tutor
  /// pausing for a second before starting. A silent utterance does that work
  /// while they are still reading the screen. It must run inside the tap that
  /// opened the conversation — browsers gate speech on a user gesture, and a
  /// warm-up that is itself blocked warms nothing.
  /// Which OS's settings hold the voices, so the app can say where to look.
  ///
  /// A guess from the user agent, and it only ever chooses which set of
  /// instructions to show — a wrong guess costs a learner one wrong menu path,
  /// not a broken feature, so `''` (say nothing specific) is the safe default.
  static String get platform {
    try {
      final ua = (_userAgent ?? '').toLowerCase();
      if (ua.contains('android')) return 'android';
      if (ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod')) {
        return 'ios';
      }
      if (ua.contains('windows')) return 'windows';
      if (ua.contains('mac os') || ua.contains('macintosh')) return 'mac';
      return '';
    } catch (_) {
      return '';
    }
  }

  /// A coarse device label for telemetry: `android`, `ios`, `windows`, `mac`
  /// or `` when the user agent says nothing useful.
  ///
  /// Every client reports `platform: web`, which is true and useless: a phone
  /// on mobile data and a laptop on wifi run identical code and behave nothing
  /// alike. Without this, "it is slower on the phone" cannot be checked.
  static String get deviceKind => platform;

  static void warmUp() {
    try {
      final synth = _speechSynthesis;
      if (synth == null) return;
      _ensureVoice(synth);
      _chosen ??= _pickEnglish(synth);
      final u = _Utterance(' ')
        ..lang = 'en-US'
        ..volume = 0;
      final v = _chosen;
      if (v != null) u.voice = v;
      synth.speak(u);
    } catch (_) {}
  }
}
