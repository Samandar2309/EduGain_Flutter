import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/grammar/domain/models.dart';
import '../features/grammar/presentation/grammar_topic_list_screen.dart';
import '../features/grammar/presentation/grammar_topic_screen.dart';
import '../features/home/presentation/main_shell.dart';
import '../features/placement/presentation/placement_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/speaking/domain/models.dart';
import '../features/speaking/presentation/scenario_list_screen.dart';
import '../features/speaking/presentation/speaking_chat_screen.dart';
import '../features/subscriptions/presentation/plans_screen.dart';
import '../features/vocabulary/domain/models.dart';
import '../features/vocabulary/presentation/review_screen.dart';
import '../features/vocabulary/presentation/vocab_set_list_screen.dart';
import '../features/vocabulary/presentation/vocab_study_screen.dart';
import 'providers.dart';

/// App router. Redirects are driven by the auth status; the router refreshes
/// whenever that status changes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;

      if (status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }
      if (status == AuthStatus.unauthenticated) {
        return loc.startsWith('/login') ? null : '/login';
      }
      // authenticated
      final atGate = loc == '/splash' || loc.startsWith('/login');
      return atGate ? '/home' : null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
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
      GoRoute(path: '/home', builder: (_, _) => const MainShell()),
      GoRoute(path: '/placement', builder: (_, _) => const PlacementScreen()),
      GoRoute(path: '/review', builder: (_, _) => const ReviewScreen()),
      GoRoute(path: '/subscriptions', builder: (_, _) => const PlansScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/speaking',
        builder: (_, _) => const ScenarioListScreen(),
        routes: [
          GoRoute(
            path: 'chat',
            builder: (_, state) =>
                SpeakingChatScreen(started: state.extra as StartedSession),
          ),
        ],
      ),
      GoRoute(
        path: '/vocabulary',
        builder: (_, _) => const VocabSetListScreen(),
        routes: [
          GoRoute(
            path: 'study',
            builder: (_, state) =>
                VocabStudyScreen(set: state.extra as VocabSet),
          ),
        ],
      ),
      GoRoute(
        path: '/grammar',
        builder: (_, _) => const GrammarTopicListScreen(),
        routes: [
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
