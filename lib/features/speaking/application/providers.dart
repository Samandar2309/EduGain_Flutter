import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/audio_playback.dart';
import '../data/audio_recorder.dart';
import '../data/speaking_repository.dart';
import '../data/tts_service.dart';
import '../domain/models.dart';
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

/// The learner's Communication Profile (auto-disposed: it changes after every
/// scored session).
final learnerProfileProvider = FutureProvider.autoDispose<LearnerProfile>(
  (ref) => ref.read(speakingRepositoryProvider).profile(),
);

/// Server-curated TTS voice catalogue (kept alive: small, reused by the picker
/// and the chat screen across a session).
final voicesProvider = FutureProvider<List<Voice>>(
  (ref) => ref.read(speakingRepositoryProvider).listVoices(),
);

/// The learner's chosen voice id (persisted), or null until they pick one.
final selectedVoiceProvider = StateNotifierProvider<VoiceController, String?>(
  (ref) => VoiceController(),
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
