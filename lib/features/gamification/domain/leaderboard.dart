// The weekly XP standings (contract: GET /gamification/leaderboard).

/// One learner's place on the board.
class Standing {
  const Standing({
    required this.rank,
    required this.name,
    required this.xp,
    required this.avatarUrl,
    required this.streak,
    required this.isYou,
  });

  final int rank;
  final String name;
  final int xp;

  /// The learner's Telegram picture, or empty.
  ///
  /// Empty is a normal state and not a failure — a locked-down profile has no
  /// photo — so the UI draws initials for it. A grey silhouette would make a
  /// private person look like a broken record.
  final String avatarUrl;

  /// Days in a row. A week's XP says how much someone did; this says they keep
  /// coming back, which is the thing worth being seen for.
  final int streak;

  final bool isYou;

  bool get hasPhoto => avatarUrl.isNotEmpty;

  /// The letter shown when there is no picture.
  ///
  /// Taken by code point rather than by `substring(0, 1)`: names arrive from
  /// Telegram and a leading emoji or a non-Latin script is a surrogate pair,
  /// which slicing by index cuts in half into an unrenderable character.
  String get initial {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return String.fromCharCode(t.runes.first).toUpperCase();
  }

  factory Standing.fromJson(Map<String, dynamic> json) => Standing(
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '—',
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    avatarUrl: json['avatar_url'] as String? ?? '',
    streak: (json['streak'] as num?)?.toInt() ?? 0,
    isYou: json['is_you'] as bool? ?? false,
  );
}

class Leaderboard {
  const Leaderboard({
    required this.top,
    required this.you,
    required this.isPrevious,
  });

  final List<Standing> top;

  /// Where the learner stands, sent separately so it survives being outside
  /// the visible top. A board you cannot find yourself in is one you stop
  /// opening. Null only until they earn their first XP of the week.
  final Standing? you;

  final bool isPrevious;

  bool get isEmpty => top.isEmpty;

  /// Whether the learner's own row needs showing under the list because the
  /// list does not already contain it.
  bool get needsOwnRow =>
      you != null && !top.any((s) => s.rank == you!.rank);

  /// The first three, for the podium.
  List<Standing> get podium => top.take(3).toList();

  /// Everyone from fourth down — the podium already showed the rest.
  List<Standing> get rest => top.length > 3 ? top.sublist(3) : const [];

  /// How much XP would move the learner up one place, and onto whose rank.
  ///
  /// Computed here from the list we already have rather than asked of the
  /// server: it is the one number that turns a standing into something to do,
  /// and it costs nothing. Null when they are first, or not on the board yet.
  ({int xp, int rank})? get toNextPlace {
    final me = you;
    if (me == null || me.rank <= 1) return null;
    final ahead = top.where((s) => s.rank < me.rank).toList();
    if (ahead.isEmpty) return null;
    final target = ahead.reduce((a, b) => a.rank > b.rank ? a : b);
    final gap = target.xp - me.xp + 1;
    return (xp: gap < 1 ? 1 : gap, rank: target.rank);
  }

  /// How far the learner has come between the person behind them and the
  /// person ahead — 0 means they have only just been overtaken, 1 means they
  /// are about to take the place above.
  ///
  /// Not `xp / (xp + gap)`: that grows with the learner's total, so someone
  /// with 5 000 XP shows a nearly full bar while needing exactly the same 61
  /// points as someone with 200. The bar has to measure the gap it sits under.
  double get gapProgress {
    final me = you;
    final next = toNextPlace;
    if (me == null || next == null) return 0;
    final behind = top.where((s) => s.rank > me.rank);
    final floor = behind.isEmpty ? 0 : behind.first.xp;
    final ceiling = me.xp + next.xp;
    final span = ceiling - floor;
    if (span <= 0) return 0;
    return ((me.xp - floor) / span).clamp(0.0, 1.0);
  }

  factory Leaderboard.fromJson(Map<String, dynamic> json) => Leaderboard(
    top: ((json['top'] as List?) ?? const [])
        .map((e) => Standing.fromJson(e as Map<String, dynamic>))
        .toList(),
    you: json['you'] == null
        ? null
        : Standing.fromJson(json['you'] as Map<String, dynamic>),
    isPrevious: json['is_previous'] as bool? ?? false,
  );
}
