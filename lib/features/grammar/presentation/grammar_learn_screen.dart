import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../domain/models.dart';

/// "Qoidani o'rganish" — a calm, premium reading of one grammar rule before
/// practising it. Renders the topic's lightweight-markdown explanation
/// (**bold**, `- ` bullets, blank-line paragraphs) as styled cards, then a CTA
/// straight into the practice games.
class GrammarLearnScreen extends StatelessWidget {
  const GrammarLearnScreen({required this.topic, super.key});

  final GrammarTopic topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(topic.title),
        backgroundColor: AppColors.canvas,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xxl),
        children: [
          _Header(topic: topic),
          const SizedBox(height: AppSpace.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadow.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _renderMarkdown(topic.explanationMd),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.grammar,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: () =>
                  context.pushReplacement('/grammar/practice', extra: topic),
              icon: const Icon(Icons.sports_esports_rounded),
              label: const Text('Mashq qilishni boshlash',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.topic});
  final GrammarTopic topic;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppGradients.accent(AppColors.grammar),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadow.glow(AppColors.grammar),
          ),
          child: Center(
            child: Text(
              topic.cefrLevel,
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.title,
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const Text('Qoida',
                  style: TextStyle(color: AppColors.inkFaint, fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }
}

/// A tiny markdown subset: blank-line paragraphs, `- ` bullets, `**bold**`.
List<Widget> _renderMarkdown(String md) {
  final widgets = <Widget>[];
  final lines = md.trim().split('\n');
  var first = true;
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) {
      widgets.add(const SizedBox(height: AppSpace.md));
      continue;
    }
    if (!first) widgets.add(const SizedBox(height: 6));
    first = false;
    if (line.startsWith('- ')) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 7, right: 8),
                child: Icon(Icons.circle, size: 6, color: AppColors.grammar),
              ),
              Expanded(child: _boldRich(line.substring(2))),
            ],
          ),
        ),
      );
    } else {
      widgets.add(_boldRich(line));
    }
  }
  return widgets;
}

/// Splits a line on `**bold**` markers into normal/bold spans.
Widget _boldRich(String text) {
  final spans = <TextSpan>[];
  final parts = text.split('**');
  for (var i = 0; i < parts.length; i++) {
    if (parts[i].isEmpty) continue;
    spans.add(TextSpan(
      text: parts[i],
      style: TextStyle(
        fontWeight: i.isOdd ? FontWeight.w800 : FontWeight.w500,
        color: i.isOdd ? AppColors.ink : AppColors.inkSoft,
      ),
    ));
  }
  return RichText(
    text: TextSpan(
      style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.inkSoft),
      children: spans,
    ),
  );
}
