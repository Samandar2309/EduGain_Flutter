/// Non-web build: there is no browser speech engine, so the tutor falls back to
/// the server-rendered voice. `supported` being false is what routes it there.
class DeviceVoice {
  const DeviceVoice({
    required this.id,
    required this.name,
    required this.lang,
    required this.gender,
  });

  final String id;
  final String name;
  final String lang;
  final String gender;
}

class DeviceTtsPlatform {
  static bool get supported => false;
  static String get voiceName => '';
  static List<DeviceVoice> voices() => const [];
  static void select(String voiceId) {}
  static Future<void> speak(
    String text, {
    double rate = 1.0,
    void Function()? onStart,
    void Function(int charIndex)? onWord,
  }) async {}
  static void warmUp() {}
  static String get platform => '';
  static String get deviceKind => '';
  static void stop() {}
}
