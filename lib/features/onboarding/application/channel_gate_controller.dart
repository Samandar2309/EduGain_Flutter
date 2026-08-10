import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/channel_repository.dart';
import '../domain/channel_gate.dart';

/// Where the channel gate stands, and whether we are allowed to act on it yet.
///
/// Three states, not two, for the same reason the interface-language step
/// needs them: the router is synchronous and this answer arrives over the
/// network. Collapse "still asking" into "not required" and a learner who must
/// join flashes the home screen first and then gets yanked back — which looks
/// like a bug. Collapse it the other way and everyone sees the join screen for
/// a moment, including the people who already joined.
class ChannelGateState {
  const ChannelGateState._(this.gate, this.isLoaded);

  const ChannelGateState.unknown() : this._(null, false);
  const ChannelGateState.resolved(ChannelGate gate) : this._(gate, true);

  final ChannelGate? gate;
  final bool isLoaded;

  bool get mustJoin => isLoaded && (gate?.mustJoin ?? false);
}

class ChannelGateController extends StateNotifier<ChannelGateState> {
  ChannelGateController(this._repo) : super(const ChannelGateState.unknown());

  final ChannelRepository _repo;

  /// The router holds the splash while this is in flight, so it cannot be
  /// allowed to hang: past this the gate opens and the learner gets on with
  /// it. Generous enough for a cold server, short enough not to read as a
  /// broken app.
  static const deadline = Duration(seconds: 4);

  Future<void> refresh() async {
    try {
      state = ChannelGateState.resolved(await _repo.status().timeout(deadline));
    } on Object {
      // Fail open, exactly as the server does. A channel subscription is not
      // worth locking anyone out of the product they came for.
      state = const ChannelGateState.resolved(ChannelGate.open);
    }
  }

  void reset() => state = const ChannelGateState.unknown();
}

final channelRepositoryProvider = Provider<ChannelRepository>(
  (ref) => ChannelRepository(ref.read(apiClientProvider)),
);

final channelGateProvider =
    StateNotifierProvider<ChannelGateController, ChannelGateState>((ref) {
      final controller = ChannelGateController(
        ref.read(channelRepositoryProvider),
      );
      // The check needs a token, so it is driven by the auth status rather
      // than run on construction — asking before sign-in would only ever 401.
      ref.listen<AuthState>(authControllerProvider, (_, next) {
        if (next.status == AuthStatus.authenticated) {
          controller.refresh();
        } else if (next.status == AuthStatus.unauthenticated) {
          // Signing out has to clear it, or the next learner on this device
          // inherits the previous one's verdict.
          controller.reset();
        }
      }, fireImmediately: true);
      return controller;
    });
