import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// Pick a scenario (or a free topic) to start a speaking session.
class ScenarioListScreen extends ConsumerStatefulWidget {
  const ScenarioListScreen({super.key});

  @override
  ConsumerState<ScenarioListScreen> createState() => _ScenarioListScreenState();
}

class _ScenarioListScreenState extends ConsumerState<ScenarioListScreen> {
  bool _starting = false;

  Future<void> _start({String? scenarioId, String? freeTopic}) async {
    setState(() => _starting = true);
    try {
      final started = await ref
          .read(speakingRepositoryProvider)
          .startSession(scenarioId: scenarioId, freeTopic: freeTopic);
      if (mounted) context.push('/speaking/chat', extra: started);
    } on ApiException catch (e) {
      if (mounted) _handleError(e);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _handleError(ApiException e) {
    if (e.statusCode == 402) {
      final cta = (e.paywall?['cta'] as String?) ?? 'Premium bilan davom eting';
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Limit tugadi'),
          content: Text(cta),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Yopish'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx), // TODO: route to paywall
              child: const Text('Premium'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _askFreeTopic() async {
    final controller = TextEditingController();
    final topic = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erkin mavzu'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(hintText: 'Masalan: sayohat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Boshlash'),
          ),
        ],
      ),
    );
    if (topic != null && topic.isNotEmpty) {
      await _start(freeTopic: topic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = ref.watch(scenariosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Speaking')),
      body: Stack(
        children: [
          scenarios.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const _ErrorState(),
            data: (list) => _ScenarioList(
              scenarios: list,
              onFreeTopic: _askFreeTopic,
              onScenario: (s) => s.isLocked
                  ? _handleError(
                      const ApiException(
                        code: 'PAYWALL',
                        message: '',
                        statusCode: 402,
                      ),
                    )
                  : _start(scenarioId: s.id),
            ),
          ),
          if (_starting)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _ScenarioList extends StatelessWidget {
  const _ScenarioList({
    required this.scenarios,
    required this.onFreeTopic,
    required this.onScenario,
  });

  final List<Scenario> scenarios;
  final VoidCallback onFreeTopic;
  final void Function(Scenario) onScenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: theme.colorScheme.primaryContainer,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.auto_awesome_rounded),
            title: const Text('Erkin mavzu', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Istalgan mavzuda suhbat quring'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onFreeTopic,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text('Ssenariylar', style: theme.textTheme.titleMedium),
        ),
        ...scenarios.map(
          (s) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${s.description}\n${s.cefrMin}–${s.cefrMax}'),
              isThreeLine: true,
              trailing: Icon(
                s.isLocked ? Icons.lock_rounded : Icons.chevron_right_rounded,
              ),
              onTap: () => onScenario(s),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Ssenariylarni yuklab bo\'lmadi. Internetni tekshiring.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
