import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components.dart';
import '../application/peer_call_controller.dart';
import 'mic_gate.dart';

/// Where the bot's "join the conversation" button lands.
///
/// It used to land on the hub — a page with the search, a friend room, a code
/// box and a conversation history. That page existed for one reason: the
/// microphone. A page that has just loaded from a link has no user gesture
/// behind it, so the hub's button supplied one, and arriving able to speak
/// cost a tap.
///
/// The tap is now spent in Telegram instead. This screen asks for the
/// microphone as it opens and then gets out of the way:
///
///   * granted  → straight into the search, which is what the button promised
///   * anything else → home, rather than a live room with no microphone
///
/// The second branch is the one that matters. Two learners once met in a room
/// where neither had been asked for a microphone; both heard silence and both
/// concluded the app was broken. Landing on the home screen is a worse
/// outcome than a working call and a far better one than that.
///
/// It draws almost nothing on purpose — it is a decision, not a destination.
class PeerEntryScreen extends ConsumerStatefulWidget {
  const PeerEntryScreen({super.key});

  @override
  ConsumerState<PeerEntryScreen> createState() => _PeerEntryScreenState();
}

class _PeerEntryScreenState extends ConsumerState<PeerEntryScreen> {
  @override
  void initState() {
    super.initState();
    // After the first frame: `ensureMicrophoneReady` can show a dialog, and a
    // dialog needs a mounted route to sit in.
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    final granted = await ensureMicrophoneReady(context, ref);
    if (!mounted) return;

    if (!granted) {
      // Home, not back: there is nothing behind this when it was opened from
      // a link, and `pop` on an empty stack does nothing at all — which would
      // strand the learner on a blank screen.
      context.go('/home');
      return;
    }
    // `pushReplacement`, so the back gesture out of the call leads home rather
    // than to this screen, which would immediately ask again.
    context.pushReplacement('/peer/call', extra: const PeerLaunchMatch());
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: AppLoader()));
}
