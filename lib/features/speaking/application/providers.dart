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

/// Today's speaking-minutes budget (auto-disposed so the ring is fresh every
/// time the learner returns; invalidate after a session to reflect spend).
final speakingQuotaProvider = FutureProvider.autoDispose<SpeakingQuota>(
  (ref) => ref.read(speakingRepositoryProvider).quota(),
);

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
