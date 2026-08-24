/// Reading a voice's gender off its name, because the Web Speech API does
/// not report one.
///
/// Its own file so it can be tested without a browser: the picker shows men
/// only (the tutor has a boy's face), which makes this guess decide whether a
/// learner is offered a voice at all.
library;

/// Personal names that give the gender away on the common engines (Windows'
/// Microsoft voices, Apple's, Android's older roster). Only used when the name
/// carries no explicit marker.
const _maleNames = <String>[
  'aaron', 'alex', 'daniel', 'fred', 'guy', 'david', 'mark', 'james',
  'george', 'oliver', 'ryan', 'thomas', 'arthur', 'eric', 'brian', 'liam',
  'noah', 'ethan', 'nathan', 'roger', 'tony', 'christopher', 'steffan',
  // Apple's roster, which is most of what an iPhone offers. Without these the
  // picker labels them "unknown" and ranks them below voices it can name —
  // on an iPhone that is the difference between a modern voice and a novelty
  // one from the nineties.
  'evan', 'rishi', 'gordon', 'reed', 'rocko', 'albert', 'bruce', 'ralph',
];
const _femaleNames = <String>[
  'samantha', 'karen', 'zira', 'ava', 'susan', 'victoria', 'moira', 'tessa',
  'fiona', 'emily', 'sonia', 'libby', 'aria', 'jenny', 'michelle', 'hazel',
  'catherine', 'linda', 'heather', 'nicky', 'clara', 'amber', 'ana',
  'allison', 'serena', 'shelley', 'kate', 'nora', 'joelle', 'veena', 'isha',
  'zoe', 'flo', 'sandy',
];

/// Which gender a voice's name claims, or "" when it says nothing.
///
/// The order of the checks is load-bearing: **"female" contains "male"**, so a
/// naive substring test labels "Microsoft Zira — English (Female)" a man. The
/// explicit markers are therefore read female-first, and only then do the
/// personal names get a turn.
String guessGender(String name) {
  final n = name.toLowerCase();
  // Android's Google engine encodes it outright: `en-us-x-sfg#male_1-local`.
  if (n.contains('#female') || n.contains('female')) return 'female';
  if (n.contains('#male') || n.contains('male')) return 'male';
  for (final m in _maleNames) {
    if (n.contains(m)) return 'male';
  }
  for (final f in _femaleNames) {
    if (n.contains(f)) return 'female';
  }
  return '';
}
