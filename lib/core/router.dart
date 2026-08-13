import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'live_data.dart';

import '../features/games/presentation/games_hub_screen.dart';
import '../features/quiz/presentation/quiz_screen.dart';
import '../features/vocabulary/domain/game.dart';
import '../features/vocabulary/presentation/game_modes_screen.dart';
import '../features/vocabulary/presentation/spell_game_screen.dart';
import '../features/vocabulary/presentation/words_to_learn_screen.dart';
import '../features/vocabulary/presentation/vocab_duel_screen.dart';
import '../features/vocabulary/presentation/vocab_game_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/name_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/auth/presentation/sign_in_failed_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/feedback/presentation/feedback_form_screen.dart';
import '../features/course/presentation/lesson_screen.dart';
import '../features/course/presentation/path_screen.dart';
import '../features/course/presentation/test_out_screen.dart';
import '../features/course/presentation/unit_screen.dart';
import '../features/home/presentation/main_shell.dart';
import '../features/onboarding/application/channel_gate_controller.dart';
import '../features/onboarding/application/onboarding_controller.dart';
import '../features/onboarding/presentation/channel_screen.dart';
import '../features/onboarding/presentation/language_screen.dart';
import '../features/onboarding/presentation/learning_language_screen.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/peer/application/peer_call_controller.dart';
import '../features/peer/presentation/peer_call_screen.dart';
import '../features/peer/presentation/peer_entry_screen.dart';
import '../features/placement/presentation/placement_screen.dart';
import '../features/profile/presentation/account_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/questions/domain/models.dart';
import '../features/questions/presentation/cue_card_screen.dart';
import '../features/questions/presentation/question_list_screen.dart';
import '../features/questions/presentation/question_parts_screen.dart';
import '../features/questions/presentation/question_topics_screen.dart';
import '../features/speaking/domain/models.dart';
import '../features/speaking/presentation/speaking_chat_screen.dart';
import '../features/speaking/presentation/speaking_history_screen.dart';
import '../features/speaking/presentation/speaking_home_screen.dart';
import '../features/group/presentation/group_call_screen.dart';
import '../features/group/presentation/group_lobby_screen.dart';
import '../features/speaking/presentation/speaking_modes_screen.dart';
import '../features/speaking/presentation/track_detail_screen.dart';
import '../features/subscriptions/presentation/plans_screen.dart';
import 'locale_controller.dart';
import 'providers.dart';
import 'telegram_webapp.dart';

/// App router. Redirects are driven by the auth status; the router refreshes
/// whenever that status changes.
/// The deep-link destination, held for one trip through the gates.
///
/// A plain variable rather than a provider: it is written and read inside the
/// router's own redirect, lives for a few hundred milliseconds, and belongs to
/// nothing else.
String? _intended;

bool _isGate(String loc) =>
    loc == '/splash' ||
    loc == '/welcome' ||
    loc.startsWith('/login') ||
    loc == '/signin-failed' ||
    loc.startsWith('/onboarding/');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(onboardingProvider, (_, _) => refresh.value++);
  ref.listen(localeProvider, (_, _) => refresh.value++);
  ref.listen(channelGateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    // Lets the tab shell notice when a pushed screen — a game, a lesson, a
    // conversation — is popped back off it. See `appRouteObserver`.
    observers: [appRouteObserver],
    // Where the learner was actually heading, held across the gates.
    //
    // A notification opens the Mini App at a URL — `/peer`, or a room. The
    // redirect below then sends them to `/splash` while auth resolves, and by
    // the time it clears, `state.matchedLocation` says `/splash` and the
    // destination is gone: everyone lands on home no matter what they tapped.
    //
    // So the first non-gate location seen is remembered, and handed back once
    // the gates are done with. Consumed on use — a destination that survived
    // would drag the learner back to it every time they reached home.
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final seenWelcome = ref.read(onboardingProvider);
      final language = ref.watch(localeProvider);
      final status = auth.status;
      final loc = state.matchedLocation;
      // Captured before any gate can overwrite it. Only a real destination —
      // `/home` and the gates themselves are what we would have done anyway.
      if (_intended == null && !_isGate(loc) && loc != '/home') {
        _intended = state.uri.toString();
      }

      // Hold the splash until BOTH auth and the first-launch flag are known,
      // so the welcome flow never flashes for returning users.
      if (status == AuthStatus.unknown ||
          seenWelcome == null ||
          !language.isLoaded) {
        return loc == '/splash' ? null : '/splash';
      }
      // Telegram Mini App. The only thing that can stop someone here is not
      // having a session at all.
      //
      // There used to be a second condition — no phone on file — which sent
      // them back to the bot to press /start. It is gone, and deliberately:
      // the bot's own /start now asks for the phone before it will show the
      // button into the app, so this was a second gate on something already
      // enforced upstream. When the two disagreed the learner was stuck in a
      // loop with no way out, which is exactly what happened. Telegram vouches
      // for whoever opens the Mini App, so an account without a phone is worth
      // letting in far more than a registered learner is worth bouncing.
      if (TelegramWebApp.isTelegram) {
        if (status != AuthStatus.authenticated) {
          return loc == '/signin-failed' ? null : '/signin-failed';
        }
        if (loc == '/signin-failed') return '/home';
      }
      if (status == AuthStatus.unauthenticated) {
        // First launch on this device → the welcome flow (language + story).
        if (!seenWelcome) {
          return loc == '/welcome' ? null : '/welcome';
        }
        return loc.startsWith('/login') ? null : '/login';
      }
      // Ask for the interface language before showing an interface. This has
      // to sit ahead of the name step and the home screen: those are the very
      // screens that would otherwise be rendered in a language the learner may
      // not read. Only reached when we KNOW nothing was saved, so it is asked
      // once and never again.
      if (language.needsChoosing) {
        return loc == '/onboarding/language' ? null : '/onboarding/language';
      }
      if (loc == '/onboarding/language') return '/home';

      // authenticated — but a brand-new user must set their name first.
      final needsName = (auth.user?.fullName ?? '').trim().isEmpty;
      if (needsName) {
        return loc == '/onboarding/name' ? null : '/onboarding/name';
      }
      // ...and then what they came here to learn. Null means never asked — the
      // column has no default precisely so this question can be asked exactly
      // once. Placed after the name because that step is the lighter one, and
      // because this answer lands better right before the app opens.
      final needsLearningLanguage = (auth.user?.learningLanguage ?? '')
          .trim()
          .isEmpty;
      if (needsLearningLanguage) {
        return loc == '/onboarding/learn' ? null : '/onboarding/learn';
      }
      // Last: our Telegram channel. Held on the splash rather than let through
      // provisionally, because the alternative — showing home and yanking them
      // back a moment later — reads as a broken app. The controller resolves
      // within a few seconds no matter what, and resolves to "no gate" on any
      // failure, so this cannot strand anyone.
      final channel = ref.watch(channelGateProvider);
      if (!channel.isLoaded) {
        return loc == '/splash' ? null : '/splash';
      }
      if (channel.mustJoin) {
        return loc == '/onboarding/channel' ? null : '/onboarding/channel';
      }
      // past every gate: keep them out of all of them.
      final atGate =
          loc == '/splash' ||
          loc == '/welcome' ||
          loc.startsWith('/login') ||
          loc == '/onboarding/name' ||
          loc == '/onboarding/learn' ||
          loc == '/onboarding/channel';
      if (!atGate) return null;
      final wanted = _intended;
      _intended = null;
      return wanted ?? '/home';
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/signin-failed',
        builder: (_, _) => const SignInFailedScreen(),
      ),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: '/onboarding/language',
        builder: (_, _) => const LanguageScreen(),
      ),
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
      GoRoute(path: '/onboarding/name', builder: (_, _) => const NameScreen()),
      GoRoute(
        path: '/onboarding/learn',
        builder: (_, _) => const LearningLanguageScreen(),
      ),
      GoRoute(
        path: '/onboarding/channel',
        builder: (_, _) => const ChannelScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const MainShell()),
      // The same shell, opened on the board.
      //
      // Its own route because the bot links here: "somebody passed you" is
      // worth exactly one tap, and /home would land the learner on the home
      // tab to go looking for the thing the message was about.
      GoRoute(
        path: '/leaderboard',
        builder: (_, _) => const MainShell(initialTab: 2),
      ),
      GoRoute(path: '/placement', builder: (_, _) => const PlacementScreen()),
      GoRoute(path: '/games', builder: (_, _) => const GamesHubScreen()),
      // A sibling of the hub, not a child of it: a parent route's
      // redirect runs for every route in the matched stack, which is how
      // every card in this hub once reopened the hub.
      GoRoute(path: '/games/quiz', builder: (_, _) => const QuizScreen()),
      // ── the games ────────────────────────────────────────────────────
      //
      // Restored, not rebuilt. The screens were removed when Vocabulary and
      // Grammar were folded into one course path — the right call for a study
      // path, and the wrong one to have applied to play: a duel against
      // another learner is not half a curriculum. The engine, the content and
      // the matchmaking relay were all still here.
      // Flat, not nested under a `/vocabulary` parent.
      //
      // There was one, and it carried `redirect: () => '/games'` so the old
      // landing URL would not dead-end. go_router runs the redirect of EVERY
      // route in a matched stack, parents included — so `/vocabulary/play` and
      // `/vocabulary/learn` were bounced to the hub as well, and every card in
      // the games hub reopened the games hub. Nothing in the app can redirect
      // a route it is also a prefix of.
      //
      // Straight into a game: the deck comes from the words the learner is
      // already working on, so no set has to be chosen first.
      GoRoute(
        path: '/vocabulary/play',
        builder: (_, _) => const GameModesScreen(),
      ),
      GoRoute(
        path: '/vocabulary/learn',
        builder: (_, _) => const WordsToLearnScreen(),
      ),
      GoRoute(
        path: '/vocabulary/game',
        builder: (_, state) =>
            VocabGameScreen(launch: state.extra as VocabGameLaunch),
      ),
      GoRoute(
        path: '/vocabulary/duel',
        builder: (_, state) =>
            VocabDuelScreen(launch: state.extra as VocabGameLaunch),
      ),
      GoRoute(
        path: '/vocabulary/spell',
        builder: (_, state) =>
            SpellGameScreen(launch: state.extra as VocabGameLaunch),
      ),
      GoRoute(path: '/subscriptions', builder: (_, _) => const PlansScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/questions',
        builder: (_, _) => const QuestionPartsScreen(),
        routes: [
          GoRoute(
            path: 'part',
            builder: (_, state) =>
                QuestionTopicsScreen(part: state.extra as QuestionPart),
          ),
          GoRoute(
            path: 'topic',
            // One route, two screens: Part 2 carries a card rather than a
            // question list, and which one to show is a property of the
            // topic — not something the caller should have to know.
            builder: (_, state) {
              final topic = state.extra as QuestionTopic;
              return topic.isCueCard
                  ? CueCardScreen(topic: topic)
                  : QuestionListScreen(topic: topic);
            },
          ),
          GoRoute(
            path: 'saved',
            builder: (_, _) => const SavedQuestionsScreen(),
          ),
        ],
      ),
      GoRoute(path: '/feedback', builder: (_, _) => const FeedbackFormScreen()),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      GoRoute(
        path: '/peer',
        // The hub is not shown for now.
        //
        // It carried the search, a friend room, a join-by-code box and the
        // conversation history, and every one of those was reachable only
        // after a tap that opened the microphone. The bot's button now spends
        // that tap in Telegram instead: this asks for the microphone on
        // arrival and either starts the search or sends the learner home.
        //
        // `PeerHubScreen` is kept, not deleted — restoring it is this one
        // line back.
        builder: (_, _) => const PeerEntryScreen(),
        routes: [
          GoRoute(
            path: 'call',
            // A call may only be entered from a tap that opened the
            // microphone — and `extra` is what proves one did.
            //
            // Every in-app route to here carries a `PeerLaunch`, set by the
            // handler that has just run `ensureMicrophoneReady`. A URL cannot
            // carry one: it arrives null. That is precisely the case that must
            // not start a search, because a page that has just loaded has no
            // user gesture to spend on a permission prompt — the learner lands
            // in a room unable to speak, and their partner hears silence.
            //
            // It is not hypothetical. The bot's "Join the conversation" button
            // linked straight here, and those messages sit in people's chats
            // for good, so repointing the button fixes only the ones sent from
            // now on. This covers the rest — and a browser reload mid-call,
            // where `extra` is likewise gone.
            //
            // The hub is one tap away and that tap does open the microphone.
            redirect: (_, state) => state.extra == null ? '/peer' : null,
            builder: (_, state) => PeerCallScreen(
              launch: state.extra! as PeerLaunch,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/speaking',
        builder: (_, _) => const SpeakingModesScreen(),
        routes: [
          GoRoute(path: 'ai', builder: (_, _) => const SpeakingHomeScreen()),
          GoRoute(
            path: 'group',
            builder: (_, _) => const GroupLobbyScreen(),
            routes: [
              GoRoute(
                path: 'call/:code',
                // Same rule as the peer call, for the same reason.
                //
                // LiveKit opens the microphone on `setMicrophoneEnabled` after
                // the room is joined — a callback, not a gesture. Reached from
                // a notification URL there is no activation left to spend on a
                // permission prompt, so on WebKit it is refused in silence and
                // the learner sits in a room hearing everyone and heard by
                // nobody.
                //
                // Only public rooms are ever announced (`group.py` never
                // announces a private one), so the lobby is guaranteed to be
                // showing this room — nothing is lost by landing there, and
                // its join button is a real tap.
                redirect: (_, state) =>
                    state.extra == null ? '/speaking/group' : null,
                builder: (_, state) =>
                    GroupCallScreen(code: state.pathParameters['code']!),
              ),
            ],
          ),
          GoRoute(
            path: 'history',
            builder: (_, _) => const SpeakingHistoryScreen(),
          ),
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
      // The course path — one walk that replaces the separate Grammar and
      // Vocabulary sections. Both of those taught half a thing each and left
      // the learner to decide which half to do today.
      GoRoute(
        path: '/course',
        builder: (context, state) => const CoursePathScreen(),
      ),
      GoRoute(
        path: '/course/unit/:id',
        builder: (context, state) =>
            UnitScreen(unitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/course/test-out/:id',
        builder: (context, state) =>
            TestOutScreen(unitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/course/lesson/:id',
        builder: (context, state) =>
            LessonScreen(lessonId: state.pathParameters['id']!),
      ),
    ],
  );
});
