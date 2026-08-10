import 'package:flutter/material.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Who the learner is willing to be matched with, for one search.
///
/// The values are the server's, verbatim — a client-side spelling that has to
/// be translated on the way out is a place for the two to drift apart.
enum PartnerFilter {
  female('female'),
  male('male'),
  any('any');

  const PartnerFilter(this.wire);
  final String wire;
}

/// Asks before the search starts, not after.
///
/// A sheet rather than a settings row: this is a decision about *this*
/// conversation, and someone who is comfortable talking to anyone on Monday
/// may not be on Friday. Asking each time costs one tap and never assumes.
///
/// Returns null when dismissed — the search must not start on a swipe-away.
Future<PartnerFilter?> showPartnerFilterSheet(
  BuildContext context, {
  required int online,
  PartnerFilter initial = PartnerFilter.any,
}) {
  return showModalBottomSheet<PartnerFilter>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _Sheet(online: online, initial: initial),
  );
}

class _Sheet extends StatefulWidget {
  const _Sheet({required this.online, required this.initial});
  final int online;
  final PartnerFilter initial;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  late PartnerFilter _choice = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xl, AppSpace.md, AppSpace.xl, AppSpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The grab handle, so the sheet reads as dismissible before
            // anybody has to try it.
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              l.peerWhoTitle,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.ink,
              ),
            ),
            if (widget.online > 0) ...[
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  l.peerWhoOnline(widget.online),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ],
            const SizedBox(height: AppSpace.lg),

            // Three rows, in the order the product asked for. `any` is last
            // and pre-selected: it is the default, and putting the widest
            // option at the bottom means the two deliberate choices are read
            // before the one that skips the decision.
            for (final option in PartnerFilter.values) ...[
              _Option(
                selected: _choice == option,
                // Figures, not the ♀/♂ symbols. At 22px the symbols read as
                // a circle with a stroke and an arrow — recognisable once you
                // know what they are, which is the wrong test for a choice
                // somebody makes in a second.
                icon: switch (option) {
                  PartnerFilter.female => Icons.woman_rounded,
                  PartnerFilter.male => Icons.man_rounded,
                  PartnerFilter.any => Icons.groups_2_rounded,
                },
                tint: switch (option) {
                  PartnerFilter.female => const Color(0xFFDB2777),
                  PartnerFilter.male => const Color(0xFF2563EB),
                  PartnerFilter.any => AppColors.brand,
                },
                title: switch (option) {
                  PartnerFilter.female => l.peerWhoFemale,
                  PartnerFilter.male => l.peerWhoMale,
                  PartnerFilter.any => l.peerWhoAny,
                },
                subtitle: switch (option) {
                  PartnerFilter.female => l.peerWhoFemaleSub,
                  PartnerFilter.male => l.peerWhoMaleSub,
                  PartnerFilter.any => l.peerWhoAnySub,
                },
                onTap: () => setState(() => _choice = option),
              ),
              const SizedBox(height: AppSpace.sm),
            ],

            // Said before the wait, not during it. Somebody who narrowed the
            // search and then sat looking at a spinner would reasonably
            // conclude the feature was broken.
            if (_choice != PartnerFilter.any) ...[
              const SizedBox(height: 2),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.schedule_rounded,
                    size: 14, color: AppColors.inkFaint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.peerWhoNarrowHint,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: AppSpace.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.speaking,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: () => Navigator.pop(context, _choice),
              child: Text(
                l.peerWhoStart,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One choice: a tinted glyph, the label, what it means, and a mark.
///
/// The whole row is the target rather than a radio dot at the end — the dot is
/// four millimetres wide and the row is the full width of the phone.
class _Option extends StatelessWidget {
  const _Option({
    required this.selected,
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? tint.withValues(alpha: 0.07) : AppColors.canvas,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? tint : AppColors.line,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: tint, size: 22),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 140),
              scale: selected ? 1 : 0.6,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 140),
                opacity: selected ? 1 : 0,
                child: Icon(Icons.check_circle_rounded, color: tint, size: 22),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
