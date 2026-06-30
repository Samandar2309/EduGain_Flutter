import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/presentation/profile_screen.dart';
import 'home_screen.dart';

/// Root authenticated shell: a [NavigationBar] over three tabs kept alive via
/// an [IndexedStack]. Deeper flows (speaking, vocabulary…) are pushed on top.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [HomeTab(), LessonsTab(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded),
            label: l.navLessons,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l.navProfile,
          ),
        ],
      ),
    );
  }
}

/// "Darslar" tab — the full catalogue of learning modules.
class LessonsTab extends StatelessWidget {
  const LessonsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, 100),
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: Text(l.lessonsTitle, style: theme.textTheme.headlineSmall),
          ),
        ),
        _LessonCard(
          icon: Icons.record_voice_over_rounded,
          color: AppColors.speaking,
          title: 'Speaking',
          subtitle: l.lessonSpeakingSubtitle,
          onTap: () => context.push('/speaking'),
        ),
        const SizedBox(height: AppSpace.md),
        _LessonCard(
          icon: Icons.style_rounded,
          color: AppColors.vocabulary,
          title: 'Vocabulary',
          subtitle: l.lessonVocabSubtitle,
          onTap: () => context.push('/vocabulary'),
        ),
        const SizedBox(height: AppSpace.md),
        _LessonCard(
          icon: Icons.menu_book_rounded,
          color: AppColors.grammar,
          title: 'Grammar',
          subtitle: l.lessonGrammarSubtitle,
          onTap: () => context.push('/grammar'),
        ),
        const SizedBox(height: AppSpace.md),
        _LessonCard(
          icon: Icons.assignment_turned_in_rounded,
          color: AppColors.placement,
          title: l.lessonPlacementTitle,
          subtitle: l.lessonPlacementSubtitle,
          onTap: () => context.push('/placement'),
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          IconChip(icon: icon, color: color, size: 52, iconSize: 26),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
