import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// A card that is finished, visible, and not open yet.
///
/// Blurred rather than removed, because the two say different things. A card
/// that vanishes leaves nothing to look forward to; a card you can almost read
/// says the work exists and is on its way. The learner can see the shape of
/// what is coming without being able to reach a half-open door.
///
/// So the blur is deliberately light. The first version was heavy enough to
/// turn both cards into coloured mush: you could tell something was disabled
/// but not what, which is the one thing this is supposed to communicate. Soft
/// enough to read, strong enough that nobody mistakes it for live — and the
/// badge sits in a corner rather than across the headline it belongs to.
class ComingSoonVeil extends StatelessWidget {
  const ComingSoonVeil({
    super.key,
    required this.child,
    required this.label,
    this.enabled = true,
    this.radius = AppRadius.xl,
    this.blur,
    this.dark = false,
    this.compact = false,
  });

  final Widget child;

  /// What the pill says — "Tez kunda", in the learner's language.
  final String label;

  /// False leaves the child completely untouched: no blur, no overlay, no
  /// wrapper in the way of its taps. One flag flips the whole app on launch
  /// day, and until then this is the only place that decides how a locked
  /// card looks.
  final bool enabled;

  final double radius;

  /// Blur strength. Null picks a default from `dark`, which is the right rule
  /// rather than one number for both: the hero's headline is large, bold and
  /// pure white, so at a setting that suits the small grey text on a tile it
  /// stays fully readable and the half of it not covered by the badge reads as
  /// a broken word. Large light type needs more veil to become texture.
  final double? blur;

  /// A pill for a dark card (the hero) rather than a white one.
  final bool dark;

  /// A smaller badge for a tile in a grid rather than a full-width card.
  ///
  /// Still carries the words. A bare padlock was tried and looked like a glyph
  /// that had landed on the title by accident; the same two words at a smaller
  /// size read as a label somebody put there on purpose, and a 178-wide tile
  /// has room for them.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final sigma = blur ?? (dark ? 3.4 : 2.4);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          // Taps die here, not on the card. Absorbing rather than ignoring:
          // a locked card must not pass the tap through to whatever sits
          // behind it in the list.
          AbsorbPointer(child: child),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: Container(
                // Enough wash that the badge is plainly the subject and the
                // card behind it is plainly dimmed. Too little and the headline
                // competes with the badge sitting on top of it, which reads as
                // a rendering fault rather than a locked card.
                color: (dark ? Colors.black : Colors.white).withValues(
                  alpha: dark ? 0.34 : 0.30,
                ),
              ),
            ),
          ),
          // Centred. It sits over the headline, which was the reason it was
          // pushed into a corner first — but a badge in the corner reads as a
          // sticker someone slapped on a working card, while a centred one is
          // obviously the state of the card itself. The wash below is what buys
          // the room for it: enough separation that both the badge and the
          // sentence behind it stay legible.
          Positioned.fill(child: Center(child: _pill(context))),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context) {
    final fg = dark ? Colors.white : AppColors.ink;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 20,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        // Frosted, not flat. A solid chip on a card that is already blurred
        // looks pasted on; a translucent one with a lit top edge belongs to the
        // glass in front of the artwork. The gradient is barely there and is
        // most of what separates this from a grey rectangle.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  Colors.white.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: 0.16),
                ]
              : [AppColors.surface, AppColors.surface.withValues(alpha: 0.90)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (dark ? Colors.white : AppColors.ink).withValues(
            alpha: dark ? 0.42 : 0.14,
          ),
          width: dark ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.34 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The padlock gets its own disc. At this size a bare glyph next to
          // bold text reads as a bullet point; in a disc it reads as a state.
          Container(
            padding: EdgeInsets.all(compact ? 4 : 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (dark ? Colors.white : AppColors.ink).withValues(
                alpha: dark ? 0.22 : 0.06,
              ),
            ),
            child: Icon(
              Icons.lock_rounded,
              size: compact ? 12.5 : 15,
              color: fg,
            ),
          ),
          SizedBox(width: compact ? 6 : 9),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: compact ? 12 : 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
