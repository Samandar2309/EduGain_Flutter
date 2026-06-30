import 'package:flutter/material.dart';

/// A scenario's immersive look — a dark gradient pair, a vivid accent (used for
/// the avatar glow, status dot and header) and a faint background icon. Pure
/// colour + icon, so every scenario feels distinct with zero image assets.
@immutable
class ScenarioBackdrop {
  const ScenarioBackdrop({
    required this.key,
    required this.top,
    required this.bottom,
    required this.accent,
    required this.icon,
  });

  /// Asset key for the realistic character + background images, e.g. "coffee" →
  /// `assets/avatars/coffee.png` (+ optional `coffee_talk.png`) and
  /// `assets/backgrounds/coffee.jpg`. Missing files fall back gracefully to the
  /// procedural avatar / gradient.
  final String key;
  final Color top;
  final Color bottom;
  final Color accent;
  final IconData icon;

  String get avatarAsset => 'assets/avatars/$key.png';
  String get avatarTalkAsset => 'assets/avatars/${key}_talk.png';
  String get backgroundAsset => 'assets/backgrounds/$key.jpg';

  /// The rigged 3D model (a Ready Player Me GLB with viseme + ARKit blendshapes)
  /// rendered by the live avatar engine. Per-scenario casting is a pure data
  /// change — drop `assets/avatar3d/models/<key>.glb` in and add the key here.
  /// Every scenario shares the proven talking model until its own art lands.
  String get model3dAsset =>
      'assets/avatar3d/models/${_modelByKey[key] ?? 'brunette'}.glb';
}

/// Scenario key -> bundled model file (without extension). Extend freely.
const Map<String, String> _modelByKey = {};

class _Theme {
  const _Theme(this.keywords, this.backdrop);
  final List<String> keywords;
  final ScenarioBackdrop backdrop;
}

// Order matters: the first theme whose keyword appears in the scenario text wins.
const _default = ScenarioBackdrop(
  key: 'default',
  top: Color(0xFF131A2A),
  bottom: Color(0xFF0B1120),
  accent: Color(0xFF6366F1), // indigo
  icon: Icons.auto_awesome_rounded,
);

const List<_Theme> _themes = [
  _Theme(
    ['airport', 'flight', 'check-in', 'boarding', 'travel', 'sayohat'],
    ScenarioBackdrop(
      key: 'airport',
      top: Color(0xFF13233F),
      bottom: Color(0xFF0A0F1C),
      accent: Color(0xFF38BDF8), // sky
      icon: Icons.flight_takeoff_rounded,
    ),
  ),
  _Theme(
    ['coffee', 'cafe', 'café', 'barista'],
    ScenarioBackdrop(
      key: 'coffee',
      top: Color(0xFF2A1C14),
      bottom: Color(0xFF120C08),
      accent: Color(0xFFF59E0B), // amber
      icon: Icons.local_cafe_rounded,
    ),
  ),
  _Theme(
    ['restaurant', 'order', 'food', 'waiter', 'menu', 'taom'],
    ScenarioBackdrop(
      key: 'restaurant',
      top: Color(0xFF2A1416),
      bottom: Color(0xFF120A0B),
      accent: Color(0xFFF43F5E), // rose
      icon: Icons.restaurant_rounded,
    ),
  ),
  _Theme(
    ['hotel', 'booking', 'reception', 'check in', 'mehmonxona'],
    ScenarioBackdrop(
      key: 'hotel',
      top: Color(0xFF0F2A2A),
      bottom: Color(0xFF081414),
      accent: Color(0xFF2DD4BF), // teal
      icon: Icons.hotel_rounded,
    ),
  ),
  _Theme(
    ['interview', 'job', 'work', 'office', 'hr', 'suhbat'],
    ScenarioBackdrop(
      key: 'interview',
      top: Color(0xFF1A1F33),
      bottom: Color(0xFF0B0E1A),
      accent: Color(0xFF818CF8), // indigo-light
      icon: Icons.work_rounded,
    ),
  ),
  _Theme(
    ['doctor', 'clinic', 'health', 'hospital', 'shifokor', 'klinika'],
    ScenarioBackdrop(
      key: 'doctor',
      top: Color(0xFF0E2630),
      bottom: Color(0xFF081318),
      accent: Color(0xFF22D3EE), // cyan
      icon: Icons.medical_services_rounded,
    ),
  ),
  _Theme(
    ['ielts', 'exam', 'test', 'academic', 'imtihon'],
    ScenarioBackdrop(
      key: 'ielts',
      top: Color(0xFF211A3A),
      bottom: Color(0xFF0F0B1C),
      accent: Color(0xFFA78BFA), // violet
      icon: Icons.school_rounded,
    ),
  ),
  _Theme(
    ['shop', 'store', 'mall', 'shopping', 'cashier', 'xarid', 'do\'kon'],
    ScenarioBackdrop(
      key: 'shopping',
      top: Color(0xFF2A1430),
      bottom: Color(0xFF120818),
      accent: Color(0xFFE879F9), // fuchsia
      icon: Icons.shopping_bag_rounded,
    ),
  ),
  _Theme(
    ['taxi', 'driver', 'cab', 'ride', 'haydovchi'],
    ScenarioBackdrop(
      key: 'taxi',
      top: Color(0xFF2A2410),
      bottom: Color(0xFF14110A),
      accent: Color(0xFFFBBF24), // taxi yellow
      icon: Icons.local_taxi_rounded,
    ),
  ),
  _Theme(
    ['police', 'officer', 'cop', 'militsiya'],
    ScenarioBackdrop(
      key: 'police',
      top: Color(0xFF14203A),
      bottom: Color(0xFF0A0F1C),
      accent: Color(0xFF60A5FA), // police blue
      icon: Icons.local_police_rounded,
    ),
  ),
  _Theme(
    ['bank', 'account', 'teller', 'card'],
    ScenarioBackdrop(
      key: 'bank',
      top: Color(0xFF0F2A22),
      bottom: Color(0xFF08140F),
      accent: Color(0xFF34D399), // bank green
      icon: Icons.account_balance_rounded,
    ),
  ),
  _Theme(
    ['university', 'lecture', 'teacher', 'class', 'student', 'campus', 'dars'],
    ScenarioBackdrop(
      key: 'university',
      top: Color(0xFF2A1E12),
      bottom: Color(0xFF140E08),
      accent: Color(0xFFFB923C), // warm academic orange
      icon: Icons.menu_book_rounded,
    ),
  ),
  _Theme(
    ['business', 'meeting', 'partner', 'negotiat', 'biznes'],
    ScenarioBackdrop(
      key: 'business',
      top: Color(0xFF1A1F33),
      bottom: Color(0xFF0B0E1A),
      accent: Color(0xFF818CF8), // corporate indigo
      icon: Icons.business_center_rounded,
    ),
  ),
  _Theme(
    ['daily', 'friend', 'casual', 'conversation', 'chat', 'do\'st', 'suhbat'],
    ScenarioBackdrop(
      key: 'daily',
      top: Color(0xFF1A2233),
      bottom: Color(0xFF0B1018),
      accent: Color(0xFF22D3EE), // friendly cyan
      icon: Icons.sentiment_satisfied_rounded,
    ),
  ),
];

/// Direct backdrop lookup by its theme `key` (used by track lessons, which carry
/// an explicit backdrop key from the catalogue). Falls back to the indigo default.
ScenarioBackdrop backdropForKey(String key) {
  for (final theme in _themes) {
    if (theme.backdrop.key == key) return theme.backdrop;
  }
  return _default;
}

/// Resolve a scenario's backdrop from whatever text we know (slug/title/category
/// for a scenario session, or the learner's free topic). Falls back to a clean
/// indigo theme when nothing matches.
ScenarioBackdrop backdropFor({
  String? slug,
  String? title,
  String? category,
  String? freeTopic,
}) {
  final haystack = [slug, title, category, freeTopic]
      .whereType<String>()
      .join(' ')
      .toLowerCase();
  if (haystack.trim().isEmpty) return _default;
  for (final theme in _themes) {
    for (final kw in theme.keywords) {
      if (haystack.contains(kw)) return theme.backdrop;
    }
  }
  return _default;
}
