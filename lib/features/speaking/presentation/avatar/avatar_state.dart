/// The conversational state of the avatar, driving its expression, the mic
/// button and the status. Kept UI-agnostic so a 3D engine (Milestone 2) can map
/// these to its own animation clips behind the same contract.
enum AvatarState {
  idle,
  listening,
  thinking,
  talking;

  /// The expression to use when the turn carries no explicit coaching emotion.
  String get fallbackEmotion => switch (this) {
    AvatarState.listening => 'curious',
    AvatarState.thinking => 'thinking',
    AvatarState.talking => 'happy',
    AvatarState.idle => 'neutral',
  };
}
