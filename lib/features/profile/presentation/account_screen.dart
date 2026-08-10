import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/error_handling.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// What we know about this learner, and the one part of it they can correct.
///
/// Gender is editable here because the bot asks it once during onboarding and
/// never again — so before this screen existed, a mis-tap was permanent. It is
/// also the value another learner's "women only" search is matched against,
/// which makes a wrong one worse than a missing one.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const Scaffold(body: AppLoader());

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(l.accountTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xxxl,
        ),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, vertical: AppSpace.xs,
            ),
            child: Column(
              children: [
                _Field(label: l.accountName, value: user.fullName ?? '—'),
                const Divider(height: 1, color: AppColors.line),
                _Field(
                  label: l.accountUsername,
                  value: user.telegramUsername == null
                      ? l.accountNoUsername
                      : '@${user.telegramUsername}',
                ),
                const Divider(height: 1, color: AppColors.line),
                _Field(label: l.accountPhone, value: user.phone ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xxl),
          SectionHeader(title: l.accountGender),
          _GenderPicker(current: user.gender),
          const SizedBox(height: AppSpace.sm),
          Text(
            l.accountGenderWhy,
            style: const TextStyle(
              color: AppColors.inkFaint,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// One read-only line: what it is, then what it says.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Two choices, and no way to clear the answer.
///
/// "Not set" is shown when there is no answer on file, but it is not offered as
/// a choice: unsetting it would silently drop the learner out of every gendered
/// search with nothing on screen to explain why.
class _GenderPicker extends ConsumerStatefulWidget {
  const _GenderPicker({required this.current});

  final String? current;

  @override
  ConsumerState<_GenderPicker> createState() => _GenderPickerState();
}

class _GenderPickerState extends ConsumerState<_GenderPicker> {
  bool _saving = false;

  Future<void> _choose(String value) async {
    if (_saving || value == widget.current) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(gender: value);
      messenger.showSnackBar(SnackBar(content: Text(l.accountSaved)));
    } on ApiException catch (e) {
      // Verbatim, not "something went wrong": the learner can act on a real
      // message and cannot act on that one.
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _Choice(
            icon: Icons.woman_rounded,
            tint: const Color(0xFFDB2777),
            label: l.accountGenderFemale,
            selected: widget.current == 'female',
            busy: _saving,
            onTap: () => _choose('female'),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: _Choice(
            icon: Icons.man_rounded,
            tint: const Color(0xFF2563EB),
            label: l.accountGenderMale,
            selected: widget.current == 'male',
            busy: _saving,
            onTap: () => _choose('male'),
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.tint,
    required this.label,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? tint.withValues(alpha: 0.07) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? tint : AppColors.line,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, size: 26, color: tint),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? tint : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
