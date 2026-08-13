import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/audio_playback.dart';
import '../data/audio_recorder.dart';
import '../data/speaking_repository.dart';
import '../data/tts_service.dart';
import '../domain/models.dart';
import 'listen_mode_controller.dart';
import 'voice_controller.dart';

final speakingRepositoryProvider = Provider<SpeakingRepository>(
  (ref) => SpeakingRepository(ref.read(apiClientProvider)),
);

/// The whole Speaking home (continue / mission / recommended / tracks / summary)
/// in one call. Auto-disposed so progress + the recommendation refresh on return.
final speakingHomeProvider = FutureProvider.autoDispose<SpeakingHome>(
  (ref) => ref.read(speakingRepositoryProvider).home(),
);

/// The goal-track catalogue (auto-disposed). Kept for any standalone track view.
final tracksProvider = FutureProvider.autoDispose<TrackCatalog>(
  (ref) => ref.read(speakingRepositoryProvider).listTracks(),
);

/// The lessons inside one track (keyed by track slug).
final trackLessonsProvider = FutureProvider.autoDispose
    .family<TrackDetail, String>(
      (ref, track) =>
          ref.read(speakingRepositoryProvider).trackLessons(track),
    );

/// Today's speaking-minutes budget.
///
/// The number has to be right whenever the learner happens to look at it, and
/// the two ways it goes wrong are both invisible from inside a screen build:
///
/// **The app was in the background.** A Telegram Mini App is backgrounded and
/// resumed constantly — a chat, a call, the phone locking. Minutes spent on
/// another device, or simply the passage of the day, land while nobody is
/// watching. Without this, the figure a learner sees is the one fetched
/// whenever the app happened to start, and only fully closing and reopening
/// the bot corrects it.
///
/// **Midnight passed.** The budget refills on the learner's own day boundary.
/// An app left open across it would keep showing yesterday's remainder — the
/// failure that reads as "my minutes never came back".
///
/// Both are handled by waking up exactly when something changed, rather than
/// polling to discover it: one listener, and one timer that fires once. An
/// endpoint this cheap is still not worth asking on a schedule when the events
/// that move it can simply be observed.
final speakingQuotaProvider = FutureProvider.autoDispose<SpeakingQuota>((
  ref,
) async {
  final quota = await ref.read(speakingRepositoryProvider).quota();

  // Fires once, just past the refill, so the ring fills itself.
  //
  // A second of slack because both clocks are rounding to whole seconds and
  // arriving early would refetch the old budget and schedule zero — a spin.
  // Zero means the server did not say; then nothing is scheduled at all.
  Timer? refill;
  if (quota.resetsInSeconds > 0) {
    refill = Timer(
      Duration(seconds: quota.resetsInSeconds + 1),
      ref.invalidateSelf,
    );
  }

  final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);

  ref.onDispose(() {
    refill?.cancel();
    lifecycle.dispose();
  });
  return quota;
});

/// Is the AI tutor open yet?
///
/// One question, asked in four places — the home hero, the Speaking tile, the
/// Communication Profile and the Speaking screen itself. Reading it through a
/// single provider is what stops those four drifting apart, which is how a
/// launch flag ends up half-applied.
///
/// False while the answer is still loading: a card that appears unlocked for a
/// moment and then blurs is worse than one that was never offered.
final aiUnlockedProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(speakingQuotaProvider).valueOrNull?.aiUnlocked ?? false,
);

/// The learner's Communication Profile (auto-disposed: it changes after every
/// scored session).
final learnerProfileProvider = FutureProvider.autoDispose<LearnerProfile>(
  (ref) => ref.read(speakingRepositoryProvider).profile(),
);

/// The learner's past conversations, newest first (auto-disposed so the list is
/// fresh every visit — a session finished a minute ago must appear).
final speakingHistoryProvider =
    FutureProvider.autoDispose<List<SpeakingSession>>(
  (ref) => ref.read(speakingRepositoryProvider).history(),
);

/// The saved report for one finished session, so a learner can re-read it.
final sessionFeedbackProvider =
    FutureProvider.autoDispose.family<FeedbackReport, String>(
  (ref, sessionId) =>
      ref.read(speakingRepositoryProvider).sessionFeedback(sessionId),
);

/// Server-curated TTS voice catalogue (kept alive: small, reused by the picker
/// and the chat screen across a session).
final voicesProvider = FutureProvider<List<Voice>>(
  (ref) => ref.read(speakingRepositoryProvider).listVoices(),
);

/// The learner's chosen voice, plus whether persistence has answered yet.
/// Both halves matter — see [VoiceSelection].
final selectedVoiceProvider =
    StateNotifierProvider<VoiceController, VoiceSelection>(
      (ref) => VoiceController(),
    );

/// True while the tutor's line is hidden so the learner has to listen
/// (persisted — see [ListenModeController]).
final listenModeProvider = StateNotifierProvider<ListenModeController, bool>(
  (ref) => ListenModeController(),
);

/// Text-to-speech for spoken AI replies (app-scoped: one player reused across
/// sessions). Renders audio server-side and plays it back per sentence; owns
/// and disposes its [AudioPlayback].
final ttsServiceProvider = Provider<TtsService>((ref) {
  final repo = ref.read(speakingRepositoryProvider);
  final tts = TtsService(
    synthesize: repo.synthesizeSpeech,
    playback: createAudioPlayback(),
  );
  ref.onDispose(tts.dispose);
  return tts;
});

/// Microphone recorder for spoken user turns.
final speechRecorderProvider = Provider<SpeechRecorder>((ref) {
  final recorder = SpeechRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});
