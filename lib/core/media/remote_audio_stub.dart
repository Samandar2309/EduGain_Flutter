/// Native platforms route WebRTC audio through the OS audio unit, not through
/// an HTML element — there is no autoplay policy to satisfy and nothing to
/// unlock.
void unlockRemoteAudio() {}
