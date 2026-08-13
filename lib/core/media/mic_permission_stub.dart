import 'package:permission_handler/permission_handler.dart';

/// Native microphone permission state, from the OS.
///
/// Returns the same four strings the web implementation does, so the facade
/// above has one mapping rather than one per platform.
class MicPermissionPlatform {
  const MicPermissionPlatform._();

  /// 'granted' | 'prompt' | 'denied' | 'unsupported'
  ///
  /// `denied` is reserved for the states the learner cannot recover from
  /// inside the app — "don't ask again" on Android, restricted by policy on
  /// iOS. A plain `isDenied` is the *first-run* state on both, where the
  /// prompt has simply never been shown, so it maps to 'prompt'.
  static Future<String> query() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted || status.isLimited) return 'granted';
      if (status.isPermanentlyDenied || status.isRestricted) return 'denied';
      if (status.isDenied) return 'prompt';
      return 'unsupported';
    } catch (_) {
      // Never let a permission lookup be the thing that blocks a call: an
      // unknown answer sends the caller down the ask-and-see path, which is
      // what it would have done anyway.
      return 'unsupported';
    }
  }
}
