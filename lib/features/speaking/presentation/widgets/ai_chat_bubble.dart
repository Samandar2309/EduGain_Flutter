import 'package:flutter/material.dart';

import '../../../../core/ui/tokens.dart';

/// The AI's current line, shown as a premium frosted-glass bubble that floats
/// near the avatar's head. Grows with its content; shows typing dots while the
/// reply is still being composed.
class AiChatBubble extends StatelessWidget {
  const AiChatBubble({
    required this.text,
    this.thinking = false,
    this.placeholder,
    this.onTap,
    this.hint,
    super.key,
  });

  final String text;
  final bool thinking;

  /// Shown instead of [text] when the line is deliberately hidden (listening
  /// mode). The bubble stays on screen so the learner can see there IS a line
  /// and that tapping will reveal it.
  final String? placeholder;

  /// Shows or hides the line. Null when there is no line yet.
  final VoidCallback? onTap;

  /// What tapping will do, for screen readers — the bubble carries no icon or
  /// label of its own when the text is visible.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty && placeholder == null && !thinking) {
      return const SizedBox.shrink();
    }
    // No BackdropFilter here, deliberately.
    //
    // This bubble sits directly over the avatar, which repaints from a Ticker —
    // every frame while the tutor is talking, because the mouth is animating.
    // A backdrop blur must re-read everything behind it, so with a moving
    // subject underneath it can never be cached: at sigma 16 that was a
    // full-width blur recomputed on every frame of every reply, and the reply
    // is exactly when the text is also streaming in and resizing the box.
    // Three of the most expensive things on the screen, all at once, at the
    // one moment the learner is watching most closely.
    //
    // What replaces it is a translucent dark fill. Over a dark, low-detail
    // avatar a sigma-16 blur resolves to more or less this anyway — and the
    // flatter ground makes the text on top of it easier to read, which is the
    // bubble's actual job.
    final bubble = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.82,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF141026).withValues(alpha: 0.82),
                  const Color(0xFF0C0A1C).withValues(alpha: 0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
              boxShadow: AppShadow.card,
            ),
            child: switch ((thinking && text.isEmpty, placeholder)) {
              (true, _) => const _TypingDots(),
              (false, final String hint) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_off,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hint,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              _ => Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            },
          ),
        ),
    );
    if (onTap == null) return bubble;
    return Semantics(
      button: true,
      label: hint ?? placeholder,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: bubble,
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_c.value + i * 0.2) % 1.0;
          final o = 0.3 + 0.7 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: o),
              ),
            ),
          );
        }),
      ),
    );
  }
}
