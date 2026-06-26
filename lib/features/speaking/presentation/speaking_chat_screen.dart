import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../application/providers.dart';
import '../domain/models.dart';
import 'feedback_view.dart';

/// The live speaking chat. User turns stream the AI reply token-by-token over
/// SSE; reaching the turn limit (402) prompts to end and get feedback.
class SpeakingChatScreen extends ConsumerStatefulWidget {
  const SpeakingChatScreen({required this.started, super.key});

  final StartedSession started;

  @override
  ConsumerState<SpeakingChatScreen> createState() => _SpeakingChatScreenState();
}

class _SpeakingChatScreenState extends ConsumerState<SpeakingChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final List<ChatMessage> _messages = [widget.started.firstMessage];
  late SpeakingSession _session = widget.started.session;
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy || !_session.isActive) return;
    _input.clear();

    final base = _messages.length;
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _messages.add(const ChatMessage(role: 'assistant', content: ''));
      _busy = true;
    });
    _scrollDown();

    final assistantIdx = base + 1;
    final buffer = StringBuffer();
    try {
      await for (final event in ref
          .read(speakingRepositoryProvider)
          .streamReply(_session.id, text)) {
        switch (event) {
          case ChunkEvent(:final text):
            buffer.write(text);
            setState(() {
              _messages[assistantIdx] = ChatMessage(
                role: 'assistant',
                content: buffer.toString(),
              );
            });
            _scrollDown();
          case DoneEvent(:final session):
            setState(() => _session = session);
          case StreamErrorEvent(:final message):
            _snack(message.isEmpty ? 'AI vaqtincha mavjud emas' : message);
        }
      }
    } on ApiException catch (e) {
      setState(() => _messages.removeRange(base, _messages.length));
      if (e.statusCode == 402) {
        _snack('Suhbat limiti tugadi. Natijani oling.');
      } else {
        _snack(e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end() async {
    setState(() => _busy = true);
    try {
      final feedback = await ref
          .read(speakingRepositoryProvider)
          .endSession(_session.id);
      if (mounted) await showFeedbackSheet(context, feedback);
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = _session.isActive;
    return Scaffold(
      appBar: AppBar(
        title: Text('Suhbat · ${_session.turnCount}/${_session.maxTurns} navbat'),
        actions: [
          TextButton.icon(
            onPressed: _busy ? null : _end,
            icon: const Icon(Icons.flag_rounded),
            label: const Text('Yakunlash'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isStreaming =
                    _busy && i == _messages.length - 1 && !m.isUser;
                return _Bubble(message: m, showTyping: isStreaming && m.content.isEmpty);
              },
            ),
          ),
          if (!active)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.secondaryContainer,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Suhbat limiti tugadi — "Yakunlash" bilan natijani oling.',
                textAlign: TextAlign.center,
              ),
            ),
          _Composer(
            controller: _input,
            enabled: active && !_busy,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.showTyping});

  final ChatMessage message;
  final bool showTyping;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: showTyping
            ? const _TypingDots()
            : Text(
                message.content,
                style: TextStyle(
                  color: isUser ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 18,
      child: Center(
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                maxLength: 500,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => enabled ? onSend() : null,
                decoration: const InputDecoration(
                  hintText: 'Xabar yozing...',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
