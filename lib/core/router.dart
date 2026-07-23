import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/name_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/auth/presentation/register_in_bot_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/grammar/domain/models.dart';
import '../features/grammar/presentation/grammar_learn_screen.dart';
import '../features/grammar/presentation/grammar_practice_screen.dart';
import '../features/grammar/presentation/grammar_topic_list_screen.dart';
import '../features/grammar/presentation/grammar_topic_screen.dart';
import '../features/home/presentation/main_shell.dart';
import '../features/onboarding/application/onboarding_controller.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/peer/application/peer_call_controller.dart';
import '../features/peer/presentation/peer_call_screen.dart';
import '../features/peer/presentation/peer_hub_screen.dart';
import '../features/placement/presentation/placement_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/speaking/domain/models.dart';
import '../features/speaking/presentation/speaking_chat_screen.dart';
import '../features/speaking/presentation/speaking_home_screen.dart';
import '../features/speaking/presentation/track_detail_screen.dart';
import '../features/subscriptions/presentation/plans_screen.dart';
import '../features/vocabulary/domain/game.dart';
import '../features/vocabulary/domain/models.dart';
import '../features/vocabulary/presentation/review_screen.dart';
import '../features/vocabulary/presentation/spell_game_screen.dart';
import '../features/vocabulary/presentation/vocab_duel_screen.dart';
import '../features/vocabulary/presentation/vocab_game_screen.dart';
import '../features/vocabulary/presentation/vocab_landing_screen.dart';
import '../features/vocabulary/presentation/vocab_set_list_screen.dart';
import '../features/vocabulary/presentation/vocab_study_screen.dart';
import '../features/vocabulary/presentation/vocab_words_screen.dart';
import 'providers.dart';
import 'telegram_webapp.dart';

/// App router. Redirects are driven by the auth status; the router refreshes
/// whenever that status changes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(onboardingProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final seenWelcome = ref.read(onboardingProvider);
      final status = auth.status;
      final loc = state.matchedLocation;

      // Hold the splash until BOTH auth and the first-launch flag are known,
      // so the welcome flow never flashes for returning users.
      if (status == AuthStatus.unknown || seenWelcome == null) {
        return loc == '/splash' ? null : '/splash';
      }
      // Telegram Mini App: registration happens in the bot (phone-number share).
      // A learner who slipped in without registering — no phone on file, or
      // whose silent login failed — is sent back to the bot; the in-app
      // phone/Google/OTP flow is never shown inside Telegram.
      if (TelegramWebApp.isTelegram) {
        final registered = status == AuthStatus.authenticated &&
            (auth.user?.phone ?? '').trim().isNotEmpty;
        if (!registered) {
          return loc == '/register-in-bot' ? null : '/register-in-bot';
        }
        if (loc == '/register-in-bot') return '/home';
      }
      if (status == AuthStatus.unauthenticated) {
        // First launch on this device → the welcome flow (language + story).
        if (!seenWelcome) {
          return loc == '/welcome' ? null : '/welcome';
        }
        return loc.startsWith('/login') ? null : '/login';
      }
      // authenticated — but a brand-new user must set their name first.
      final needsName = (auth.user?.fullName ?? '').trim().isEmpty;
      if (needsName) {
        return loc == '/onboarding/name' ? null : '/onboarding/name';
      }
      // has a name: keep them out of the gates and the name step.
      final atGate = loc == '/splash' ||
          loc == '/welcome' ||
          loc.startsWith('/login') ||
          loc == '/onboarding/name';
      return atGate ? '/home' : null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/register-in-bot',
        builder: (_, _) => const RegisterInBotScreen(),
      ),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: '/login',
        builder: (_, _) => const PhoneScreen(),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (_, state) => OtpScreen(phone: state.extra as String),
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding/name',
        builder: (_, _) => const NameScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const MainShell()),
      GoRoute(path: '/placement', builder: (_, _) => const PlacementScreen()),
      GoRoute(path: '/review', builder: (_, _) => const ReviewScreen()),
      GoRoute(path: '/subscriptions', builder: (_, _) => const PlansScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/peer',
        builder: (_, _) => const PeerHubScreen(),
        routes: [
          GoRoute(
            path: 'call',
            builder: (_, state) => PeerCallScreen(
              launch: state.extra as PeerLaunch? ?? PeerLaunch.match,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/speaking',
        builder: (_, _) => const SpeakingHomeScreen(),
        routes: [
          GoRoute(
            path: 'track',
            builder: (_, state) =>
                TrackDetailScreen(track: state.extra as TrackSummary),
          ),
          GoRoute(
            path: 'chat',
            builder: (_, state) =>
                SpeakingChatScreen(launch: state.extra as SpeakingLaunch),
          ),
        ],
      ),
      GoRoute(
        path: '/vocabulary',
        builder: (_, _) => const VocabLandingScreen(),
        routes: [
          GoRoute(
            path: 'sets',
            builder: (_, state) => VocabSetListScreen(
              intent: state.extra as VocabIntent? ?? VocabIntent.play,
            ),
          ),
          GoRoute(
            path: 'words',
            builder: (_, state) =>
                VocabWordsScreen(set: state.extra as VocabSet),
          ),
          GoRoute(
            path: 'study',
            builder: (_, state) =>
                VocabStudyScreen(set: state.extra as VocabSet),
          ),
          GoRoute(
            path: 'game',
            builder: (_, state) =>
                VocabGameScreen(launch: state.extra as VocabGameLaunch),
          ),
          GoRoute(
            path: 'duel',
            builder: (_, state) =>
                VocabDuelScreen(launch: state.extra as VocabGameLaunch),
          ),
          GoRoute(
            path: 'spell',
            builder: (_, state) =>
                SpellGameScreen(launch: state.extra as VocabGameLaunch),
          ),
        ],
      ),
      GoRoute(
        path: '/grammar',
        builder: (_, _) => const GrammarTopicListScreen(),
        routes: [
          GoRoute(
            path: 'learn',
            builder: (_, state) =>
                GrammarLearnScreen(topic: state.extra as GrammarTopic),
          ),
          GoRoute(
            path: 'practice',
            builder: (_, state) =>
                GrammarPracticeScreen(topic: state.extra as GrammarTopic),
          ),
          GoRoute(
            path: 'topic',
            builder: (_, state) =>
                GrammarTopicScreen(topic: state.extra as GrammarTopic),
          ),
        ],
      ),
    ],
  );
});
