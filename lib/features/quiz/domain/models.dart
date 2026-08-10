/// The live quiz, as the screen needs it.
///
/// `remaining` is a duration and never a deadline. The server sends seconds
/// left rather than an instant to subtract from this phone's clock, because a
/// device whose time is slightly off would otherwise draw a timer that is
/// wrong by exactly that much — which this app has already shipped once.
library;

enum QuizPhase {
  /// Nobody has opened a game.
  idle,

  /// A game is open and waiting for enough people to say they are ready.
  lobby,
  answer,
  reveal,
  result,
}

QuizPhase _phase(String raw) => switch (raw) {
  'lobby' => QuizPhase.lobby,
  'reveal' => QuizPhase.reveal,
  'result' => QuizPhase.result,
  'answer' => QuizPhase.answer,
  _ => QuizPhase.idle,
};

class QuizQuestion {
  const QuizQuestion({
    required this.kind,
    required this.prompt,
    required this.options,
    this.correct,
    this.note = '',
  });

  final String kind;
  final String prompt;
  final List<String> options;

  /// Null while the round is open — the server does not send it until the
  /// answering window has closed, so there is nothing to read early.
  final int? correct;
  final String note;

  static const none = QuizQuestion(kind: '', prompt: '', options: []);

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    kind: json['kind'] as String? ?? '',
    prompt: json['prompt'] as String? ?? '',
    options: ((json['options'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    correct: (json['correct'] as num?)?.toInt(),
    note: json['note'] as String? ?? '',
  );
}

class QuizPlayer {
  const QuizPlayer({
    required this.rank,
    required this.name,
    required this.points,
    required this.isYou,
  });

  final int rank;
  final String name;
  final int points;
  final bool isYou;

  /// The letter shown when there is no picture — which is most of the time.
  ///
  /// Taken by code point rather than by UTF-16 unit: real display names in
  /// this app include "🖤" and "Akhmedova🤍", and `name[0]` on those yields
  /// half a surrogate pair, which renders as a broken box.
  String get initial => _initialOf(name);

  factory QuizPlayer.fromJson(Map<String, dynamic> json) => QuizPlayer(
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    points: (json['points'] as num?)?.toInt() ?? 0,
    isYou: json['you'] as bool? ?? false,
  );
}

class QuizBoard {
  const QuizBoard({required this.top, this.you});

  final List<QuizPlayer> top;

  /// Where the caller stands even when they are outside the top ten — the
  /// eleventh player is the one still deciding whether to keep playing.
  final QuizPlayer? you;

  static const empty = QuizBoard(top: []);

  factory QuizBoard.fromJson(Map<String, dynamic> json) => QuizBoard(
    top: ((json['top'] as List?) ?? const [])
        .map((e) => QuizPlayer.fromJson(e as Map<String, dynamic>))
        .toList(),
    you: json['you'] == null
        ? null
        : QuizPlayer.fromJson(json['you'] as Map<String, dynamic>),
  );
}

String _initialOf(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
}

/// Somebody sitting in the lobby, before any score exists.
class QuizSeat {
  const QuizSeat({required this.name, required this.isYou});

  final String name;
  final bool isYou;

  String get initial => _initialOf(name);

  factory QuizSeat.fromJson(Map<String, dynamic> json) => QuizSeat(
    name: json['name'] as String? ?? '',
    isYou: json['you'] as bool? ?? false,
  );
}

class QuizState {
  const QuizState({
    required this.match,
    required this.phase,
    required this.remaining,
    required this.index,
    required this.total,
    required this.players,
    required this.needed,
    required this.hostName,
    required this.youReady,
    required this.minPlayers,
    required this.question,
    required this.matchBoard,
  });

  final int match;
  final QuizPhase phase;

  /// Seconds left in the current phase, as the server counted them.
  final double remaining;
  final int index;
  final int total;

  /// Who is in the lobby. Real presence, pruned — never a counter, and never
  /// padded out with names nobody is behind.
  final List<QuizSeat> players;

  /// How many more have to say they are ready before the match begins.
  final int needed;
  final String hostName;
  final bool youReady;
  final int minPlayers;

  final QuizQuestion question;
  final QuizBoard matchBoard;

  bool get isPlaying =>
      phase == QuizPhase.answer ||
      phase == QuizPhase.reveal ||
      phase == QuizPhase.result;

  factory QuizState.fromJson(Map<String, dynamic> json) {
    final boards = (json['boards'] as Map?)?.cast<String, dynamic>() ?? const {};
    return QuizState(
      match: (json['match'] as num?)?.toInt() ?? 0,
      phase: _phase(json['phase'] as String? ?? 'idle'),
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      index: (json['index'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      players: ((json['players'] as List?) ?? const [])
          .map((e) => QuizSeat.fromJson(e as Map<String, dynamic>))
          .toList(),
      needed: (json['needed'] as num?)?.toInt() ?? 0,
      hostName: json['host_name'] as String? ?? '',
      youReady: json['you_ready'] as bool? ?? false,
      minPlayers: (json['min_players'] as num?)?.toInt() ?? 2,
      question: json['question'] == null
          ? QuizQuestion.none
          : QuizQuestion.fromJson(
              (json['question'] as Map).cast<String, dynamic>(),
            ),
      matchBoard: QuizBoard.fromJson(
        (boards['match'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

class QuizVerdict {
  const QuizVerdict({
    required this.correct,
    required this.correctIndex,
    required this.points,
  });

  final bool correct;
  final int correctIndex;
  final int points;

  factory QuizVerdict.fromJson(Map<String, dynamic> json) => QuizVerdict(
    correct: json['correct'] as bool? ?? false,
    correctIndex: (json['correct_index'] as num?)?.toInt() ?? -1,
    points: (json['points'] as num?)?.toInt() ?? 0,
  );
}

/// What the games hub card needs: is anything happening, and who is in it.
///
/// Read without joining. A card that counted everyone glancing at the menu as
/// a waiting player would be inventing a crowd, which is the one thing this
/// feature must not do.
class QuizLive {
  const QuizLive({
    required this.playing,
    required this.live,
    required this.running,
    required this.hostName,
    required this.needed,
  });

  final int playing;

  /// A lobby exists (whether or not a match has begun).
  final bool live;

  /// A match is actually in progress.
  final bool running;
  final String hostName;
  final int needed;

  static const none = QuizLive(
    playing: 0,
    live: false,
    running: false,
    hostName: '',
    needed: 2,
  );

  factory QuizLive.fromJson(Map<String, dynamic> json) => QuizLive(
    playing: (json['playing'] as num?)?.toInt() ?? 0,
    live: json['live'] as bool? ?? false,
    running: json['running'] as bool? ?? false,
    hostName: json['host_name'] as String? ?? '',
    needed: (json['needed'] as num?)?.toInt() ?? 2,
  );
}
