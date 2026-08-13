/// The course path, as the server describes it.
///
/// Every state on this screen is decided on the server and read here. Nothing
/// in this file works out whether a unit is unlocked — two clients that each
/// computed that would eventually disagree, and the one that said yes is the
/// one the learner would be looking at.
library;

enum UnitState {
  done,
  current,
  locked,

  /// Reachable, but not on this learner's plan. Kept apart from [locked] so the
  /// screen can offer the upgrade instead of drawing a padlock, which reads as
  /// "you are not far enough yet" and is a different, discouraging message.
  premium;

  static UnitState from(String? raw) => switch (raw) {
    'done' => UnitState.done,
    'current' => UnitState.current,
    'premium' => UnitState.premium,
    _ => UnitState.locked,
  };

  bool get isOpen => this == UnitState.current || this == UnitState.done;
}

class UnitNode {
  const UnitNode({
    required this.id,
    required this.number,
    required this.title,
    required this.grammar,
    required this.vocab,
    required this.state,
    required this.mastery,
    required this.maxMastery,
    required this.lessonsDone,
    required this.lessonCount,
    required this.isPremium,
  });

  final String id;
  final String number;
  final String title;

  /// What the unit teaches, named before it is opened. A node that only says
  /// "Unit 7" gives nobody a reason to tap it.
  final String grammar;
  final String vocab;

  final UnitState state;
  final int mastery;
  final int maxMastery;
  final int lessonsDone;
  final int lessonCount;
  final bool isPremium;

  factory UnitNode.fromJson(Map<String, dynamic> j) => UnitNode(
    id: j['id'] as String,
    number: j['number'] as String? ?? '',
    title: j['title'] as String? ?? '',
    grammar: j['grammar'] as String? ?? '',
    vocab: j['vocab'] as String? ?? '',
    state: UnitState.from(j['state'] as String?),
    mastery: (j['mastery'] as num?)?.toInt() ?? 0,
    maxMastery: (j['max_mastery'] as num?)?.toInt() ?? 5,
    lessonsDone: (j['lessons_done'] as num?)?.toInt() ?? 0,
    lessonCount: (j['lesson_count'] as num?)?.toInt() ?? 0,
    isPremium: j['is_premium'] as bool? ?? false,
  );
}

class CourseLevel {
  const CourseLevel({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.cefrLevel,
    required this.percent,
    required this.units,
  });

  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final String cefrLevel;

  /// How far through, counted in units finished — the number a learner can
  /// verify by looking at the path.
  final int percent;
  final List<UnitNode> units;

  factory CourseLevel.fromJson(Map<String, dynamic> j) => CourseLevel(
    id: j['id'] as String,
    slug: j['slug'] as String? ?? '',
    title: j['title'] as String? ?? '',
    subtitle: j['subtitle'] as String? ?? '',
    cefrLevel: j['cefr_level'] as String? ?? '',
    percent: (j['percent'] as num?)?.toInt() ?? 0,
    units: ((j['units'] as List?) ?? const [])
        .map((u) => UnitNode.fromJson(u as Map<String, dynamic>))
        .toList(),
  );
}

enum LessonState { done, current, locked }

class LessonRef {
  const LessonRef({
    required this.id,
    required this.index,
    required this.itemCount,
    required this.state,
  });

  final String id;
  final int index;
  final int itemCount;
  final LessonState state;

  factory LessonRef.fromJson(Map<String, dynamic> j) => LessonRef(
    id: j['id'] as String,
    index: (j['index'] as num?)?.toInt() ?? 0,
    itemCount: (j['item_count'] as num?)?.toInt() ?? 0,
    state: switch (j['state'] as String?) {
      'done' => LessonState.done,
      'current' => LessonState.current,
      _ => LessonState.locked,
    },
  );
}

class UnitDetail {
  const UnitDetail({
    required this.id,
    required this.number,
    required this.title,
    required this.grammar,
    required this.explanation,
    required this.vocab,
    required this.mastery,
    required this.lessons,
    this.nextUnit,
  });

  final String id;
  final String number;
  final String title;
  final String grammar;

  /// The rule itself, in the learner's language, so a unit can be read before
  /// it is practised.
  final String explanation;
  final String vocab;
  final int mastery;
  final List<LessonRef> lessons;

  /// What to do after this unit, or null when there is nothing after it — the
  /// course is finished, or the rest is premium.
  ///
  /// The server decides this. A finished unit has no `current` lesson (every
  /// state comes back `done`), and a screen left to work out "what next" from
  /// that on its own picked the last lesson and offered it again, forever.
  final UnitLink? nextUnit;

  /// True once every lesson here is behind the learner.
  bool get isFinished =>
      lessons.isNotEmpty && lessons.every((l) => l.state == LessonState.done);

  factory UnitDetail.fromJson(Map<String, dynamic> j) => UnitDetail(
    id: j['id'] as String,
    number: j['number'] as String? ?? '',
    title: j['title'] as String? ?? '',
    grammar: j['grammar'] as String? ?? '',
    explanation: j['explanation'] as String? ?? '',
    vocab: j['vocab'] as String? ?? '',
    mastery: (j['mastery'] as num?)?.toInt() ?? 0,
    lessons: ((j['lessons'] as List?) ?? const [])
        .map((l) => LessonRef.fromJson(l as Map<String, dynamic>))
        .toList(),
    nextUnit: j['next_unit'] == null
        ? null
        : UnitLink.fromJson(j['next_unit'] as Map<String, dynamic>),
  );
}

/// Just enough of another unit to offer it: where to go and what to call it.
class UnitLink {
  const UnitLink({required this.id, required this.number, required this.title});

  final String id;
  final String number;
  final String title;

  factory UnitLink.fromJson(Map<String, dynamic> j) => UnitLink(
    id: j['id'] as String,
    number: j['number'] as String? ?? '',
    title: j['title'] as String? ?? '',
  );
}

/// One thing to answer.
///
/// Deliberately loose: the server names the drill and carries whatever that
/// drill needs, so a new exercise type is a new widget here and no change at
/// all to this class. It never carries the correct answer — that is checked on
/// the server, and an exercise whose answer reached the device is solved.
class Drill {
  const Drill({required this.itemId, required this.type, required this.data});

  final String itemId;
  final String type;
  final Map<String, dynamic> data;

  /// Carried forward from an earlier unit rather than taught by this one.
  bool get isReview => data['is_review'] as bool? ?? false;

  String get prompt => data['prompt'] as String? ?? '';
  String get example => data['example'] as String? ?? '';
  List<String> get options =>
      ((data['options'] as List?) ?? const []).map((o) => '$o').toList();
  List<String> get tiles =>
      ((data['tiles'] as List?) ?? const []).map((t) => '$t').toList();

  List<({String id, String text})> _side(String key) =>
      ((data[key] as List?) ?? const [])
          .map((e) => (
                id: (e as Map)['id'] as String,
                text: e['text'] as String,
              ))
          .toList();

  List<({String id, String text})> get left => _side('left');
  List<({String id, String text})> get right => _side('right');

  factory Drill.fromJson(Map<String, dynamic> j) => Drill(
    itemId: j['item_id'] as String,
    type: j['type'] as String? ?? '',
    data: j,
  );
}

class LessonResult {
  const LessonResult({
    required this.correct,
    required this.total,
    required this.passed,
    required this.wrongItemIds,
    required this.mastery,
    required this.masteryGained,
    required this.unitCompleted,
    required this.xp,
  });

  final int correct;
  final int total;
  final bool passed;
  final List<String> wrongItemIds;
  final int mastery;
  final bool masteryGained;
  final bool unitCompleted;
  final int xp;

  factory LessonResult.fromJson(Map<String, dynamic> j) => LessonResult(
    correct: (j['correct'] as num?)?.toInt() ?? 0,
    total: (j['total'] as num?)?.toInt() ?? 0,
    passed: j['passed'] as bool? ?? false,
    wrongItemIds:
        ((j['wrong_item_ids'] as List?) ?? const []).map((e) => '$e').toList(),
    mastery: (j['mastery'] as num?)?.toInt() ?? 0,
    masteryGained: j['mastery_gained'] as bool? ?? false,
    unitCompleted: j['unit_completed'] as bool? ?? false,
    xp: (j['xp'] as num?)?.toInt() ?? 0,
  );
}

/// The outcome of a jump.
///
/// Carries `xp` explicitly even though it is always zero. A learner who finds
/// out afterwards that skipping earned nothing will feel caught out by a rule
/// nobody told them; the screen can only say it if the response does.
class TestOutResult {
  const TestOutResult({
    required this.correct,
    required this.total,
    required this.passed,
    required this.unlocked,
    required this.xp,
  });

  final int correct;
  final int total;
  final bool passed;

  /// How many units this opened.
  final int unlocked;
  final int xp;

  factory TestOutResult.fromJson(Map<String, dynamic> j) => TestOutResult(
    correct: (j['correct'] as num?)?.toInt() ?? 0,
    total: (j['total'] as num?)?.toInt() ?? 0,
    passed: j['passed'] as bool? ?? false,
    unlocked: (j['unlocked'] as num?)?.toInt() ?? 0,
    xp: (j['xp'] as num?)?.toInt() ?? 0,
  );
}
