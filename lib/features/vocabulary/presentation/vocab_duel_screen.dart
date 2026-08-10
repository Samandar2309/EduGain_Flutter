import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/ui/tokens.dart';
import '../../peer/data/peer_signaling.dart';
import '../application/providers.dart';
import '../domain/game.dart';
import 'widgets/game_widgets.dart';

/// Live human-vs-human vocabulary duel. Reuses the peer matchmaking + WebSocket
/// relay (`game=vocab`): once two learners are paired, the guest ships the
/// shared deck to the host over the relay, both race the same questions, and
/// live progress crosses the wire. Cold-start safety: if no opponent turns up,
/// the player can fall back to a bot duel with the same words.
class VocabDuelScreen extends ConsumerStatefulWidget {
  const VocabDuelScreen({required this.launch, super.key});

  final VocabGameLaunch launch;

  @override
  ConsumerState<VocabDuelScreen> createState() => _VocabDuelScreenState();
}

enum _Phase { connecting, searching, playing, waitingOpponent, finished, failed }

class _VocabDuelScreenState extends ConsumerState<VocabDuelScreen> {
  final _rng = Random();
  PeerSignaling? _sig;
  StreamSubscription<Map<String, dynamic>>? _sub;

  _Phase _phase = _Phase.connecting;
  String _opponentName = 'Raqib';
  bool _searchTimedOut = false;
  Timer? _searchTimer;

  List<GameQuestion> _deck = const [];
  int _index = 0;
  int? _picked;
  int _correct = 0;
  int _combo = 0;
  int _bestCombo = 0;
  final _results = <({String itemId, bool correct})>[];

  int _oppAnswered = 0;
  int _oppCorrect = 0;
  bool _oppFinished = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _sub?.cancel();
    _sig?.close();
    super.dispose();
  }

  Future<void> _connect() async {
    final token = await ref.read(tokenStorageProvider).readAccess();
    if (token == null) {
      setState(() => _phase = _Phase.failed);
      return;
    }
    final name = (ref.read(authControllerProvider).user?.fullName ?? '').trim();
    final sig = PeerSignaling.connect(
      token: token,
      name: name.isEmpty ? 'Oʻquvchi' : name,
      mode: 'match',
      game: 'vocab',
    );
    _sig = sig;
    _sub = sig.messages.listen(
      _onMessage,
      onError: (Object _) => _fail(),
      onDone: () {
        if (_phase != _Phase.finished) _fail();
      },
    );
  }

  void _fail() {
    if (!mounted || _phase == _Phase.finished) return;
    setState(() => _phase = _Phase.failed);
  }

  Future<void> _onMessage(Map<String, dynamic> msg) async {
    if (!mounted) return;
    switch (msg['type']) {
      case 'searching':
        setState(() => _phase = _Phase.searching);
        _searchTimer = Timer(const Duration(seconds: 18), () {
          if (mounted && _phase == _Phase.searching) {
            setState(() => _searchTimedOut = true);
          }
        });
      case 'hello':
        _searchTimer?.cancel();
        final role = msg['role'] as String? ?? 'guest';
        final partner = (msg['partner_name'] as String?)?.trim() ?? '';
        _opponentName = partner.isEmpty ? 'Raqib' : partner;
        if (role == 'guest') {
          // The guest builds the deck and ships it to the host.
          final deck = buildDeck(widget.launch.items, random: _rng);
          _sig?.send({
            'type': 'deck',
            'questions': deck.map((q) => q.toJson()).toList(),
          });
          setState(() {
            _deck = deck;
            _phase = _Phase.playing;
          });
        }
      // host waits for the deck to arrive
      case 'peer_joined':
        final n = (msg['name'] as String?)?.trim() ?? '';
        if (n.isNotEmpty) setState(() => _opponentName = n);
      case 'deck':
        final qs = (msg['questions'] as List? ?? const [])
            .map((e) => GameQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (qs.isNotEmpty) {
          setState(() {
            _deck = qs;
            _phase = _Phase.playing;
          });
        }
      case 'progress':
        setState(() {
          _oppAnswered = (msg['answered'] as num?)?.toInt() ?? _oppAnswered;
          _oppCorrect = (msg['correct'] as num?)?.toInt() ?? _oppCorrect;
        });
      case 'finish':
        _oppFinished = true;
        _oppCorrect = (msg['correct'] as num?)?.toInt() ?? _oppCorrect;
        if (_phase == _Phase.waitingOpponent) _finish();
      case 'peer_left' || 'hangup':
        // Opponent quit — end the duel with whatever scores stand.
        _oppFinished = true;
        if (_phase == _Phase.waitingOpponent || _phase == _Phase.playing) {
          _finish();
        }
    }
  }

  void _pick(int option) {
    if (_picked != null || _phase != _Phase.playing) return;
    final q = _deck[_index];
    final correct = option == q.correctIndex;
    HapticFeedback.lightImpact();
    setState(() {
      _picked = option;
      _results.add((itemId: q.itemId, correct: correct));
      if (correct) {
        _correct++;
        _combo++;
        _bestCombo = max(_bestCombo, _combo);
      } else {
        _combo = 0;
      }
    });
    // Silent, on purpose.
    //
    // The game used to chime on every answer and then read the word aloud a
    // third of a second later. Somebody playing on a bus, or beside a sleeping
    // child, had no way to stop it — and the pronunciation arrived while they
    // were already reading the next question, which is the moment it teaches
    // least. Hearing a word is worth a deliberate tap, and that is what the
    // word list is for.
    //
    // Haptics stay: they answer "did that register?" without making a sound.
    _sig?.send({'type': 'progress', 'answered': _index + 1, 'correct': _correct});
    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      if (_index + 1 >= _deck.length) {
        _sig?.send({'type': 'finish', 'correct': _correct});
        if (_oppFinished) {
          _finish();
        } else {
          setState(() => _phase = _Phase.waitingOpponent);
        }
      } else {
        setState(() {
          _index++;
          _picked = null;
        });
      }
    });
  }

  void _finish() {
    if (_phase == _Phase.finished) return;
    setState(() => _phase = _Phase.finished);
    _submit();
  }

  Future<void> _submit() async {
    if (_submitted || _results.isEmpty) return;
    _submitted = true;
    try {
      await ref.read(vocabularyRepositoryProvider).submitReview(_results);
    } on Object {
      // results still show; SRS just isn't updated
    }
  }

  GameResult get _result => GameResult(
    mode: GameMode.online,
    total: _deck.length,
    correct: _correct,
    bestCombo: _bestCombo,
    xpEarned: xpForRun(correct: _correct, bestCombo: _bestCombo),
    itemResults: _results,
    youWon: _correct >= _oppCorrect,
    opponentCorrect: _oppCorrect,
  );

  void _fallbackToBot() {
    _sub?.cancel();
    _sig?.close();
    context.pushReplacement(
      '/vocabulary/game',
      extra: VocabGameLaunch(
        items: widget.launch.items,
        mode: GameMode.duel,
        title: widget.launch.title,
        setId: widget.launch.setId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.connecting:
      case _Phase.searching:
        return _SearchingView(
          timedOut: _searchTimedOut,
          onCancel: () => context.pop(),
          onPlayBot: _fallbackToBot,
        );
      case _Phase.failed:
        return _FailedView(onBot: _fallbackToBot, onBack: () => context.pop());
      case _Phase.finished:
        return GameResultsView(
          result: _result,
          opponentName: _opponentName,
          onAgain: () => context.pushReplacement('/vocabulary/duel', extra: widget.launch),
          onDone: () => context.pop(),
        );
      case _Phase.playing:
      case _Phase.waitingOpponent:
        return _playView();
    }
  }

  Widget _playView() {
    final waiting = _phase == _Phase.waitingOpponent;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  _sig?.send({'type': 'hangup'});
                  context.pop();
                },
                icon: const Icon(Icons.close_rounded, color: AppColors.inkFaint),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: _deck.isEmpty ? 0 : _index / _deck.length,
                    minHeight: 10,
                    backgroundColor: AppColors.line,
                    valueColor: const AlwaysStoppedAnimation(AppColors.vocabulary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              ComboBadge(combo: _combo),
            ],
          ),
        ),
        RaceBar(
          youProgress: _deck.isEmpty ? 0 : _index / _deck.length,
          opponentProgress: _deck.isEmpty ? 0 : _oppAnswered / _deck.length,
          opponentName: _opponentName,
        ),
        Expanded(
          child: waiting
              ? _WaitingOpponent(name: _opponentName)
              : QuestionView(question: _deck[_index], picked: _picked, onPick: _pick),
        ),
      ],
    );
  }
}

// ── searching ────────────────────────────────────────────────────────────────
class _SearchingView extends StatefulWidget {
  const _SearchingView({
    required this.timedOut,
    required this.onCancel,
    required this.onPlayBot,
  });

  final bool timedOut;
  final VoidCallback onCancel;
  final VoidCallback onPlayBot;

  @override
  State<_SearchingView> createState() => _SearchingViewState();
}

class _SearchingViewState extends State<_SearchingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _ring((_pulse.value) % 1.0),
                  _ring((_pulse.value + 0.5) % 1.0),
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.accent(AppColors.vocabulary),
                    ),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 44),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xxl),
          const Text(
            'Raqib qidirilmoqda…',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.sm),
          const Text(
            "Boshqa o'quvchi shu o'yinni tanlashi bilan avtomatik ulanasiz",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkFaint, fontSize: 13, height: 1.4),
          ),
          const Spacer(),
          if (widget.timedOut) ...[
            Container(
              padding: const EdgeInsets.all(AppSpace.lg),
              decoration: BoxDecoration(
                color: AppColors.speaking.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  const Text(
                    "Hozircha onlayn raqib topilmadi.",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpace.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.speaking,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: widget.onPlayBot,
                      icon: const Icon(Icons.sports_esports_rounded),
                      label: const Text('Gainsy bilan o‘ynash'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('Bekor qilish', style: TextStyle(color: AppColors.inkFaint)),
          ),
        ],
      ),
    );
  }

  Widget _ring(double t) {
    return Container(
      width: 108 + t * 110,
      height: 108 + t * 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.vocabulary.withValues(alpha: (1 - t) * 0.45),
          width: 2,
        ),
      ),
    );
  }
}

class _WaitingOpponent extends StatelessWidget {
  const _WaitingOpponent({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 34, height: 34, child: CircularProgressIndicator()),
          const SizedBox(height: AppSpace.lg),
          Text('$name javob beryapti…',
              style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({required this.onBot, required this.onBack});
  final VoidCallback onBot;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.inkFaint),
          const SizedBox(height: AppSpace.lg),
          const Text(
            'Ulanishda muammo. Gainsy bilan o‘ynab turasizmi?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: AppSpace.xl),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.vocabulary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxxl, vertical: 13),
            ),
            onPressed: onBot,
            child: const Text('Gainsy bilan o‘ynash'),
          ),
          TextButton(onPressed: onBack, child: const Text('Orqaga')),
        ],
      ),
    );
  }
}
