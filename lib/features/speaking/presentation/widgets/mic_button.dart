import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/ui/tokens.dart';

/// The mic's stage in the turn cycle — drives the button's look + animation.
enum MicState { ready, recording, processing, aiSpeaking }

/// The focal control of the Speaking screen: a large circular mic with a glow
/// and state-driven pulse. Idle breathes softly; recording emits expanding
/// rings; processing spins; while the AI speaks it dims to an equaliser glyph.
class MicButton extends StatefulWidget {
  const MicButton({
    required this.state,
    required this.accent,
    required this.onTap,
    this.size = 84,
    super.key,
  });

  final MicState state;
  final Color accent;
  final VoidCallback? onTap;
  final double size;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.state) {
    MicState.recording => AppColors.danger,
    MicState.aiSpeaking => widget.accent.withValues(alpha: 0.6),
    _ => widget.accent,
  };

  IconData get _icon => switch (widget.state) {
    MicState.recording => Icons.stop_rounded,
    MicState.aiSpeaking => Icons.graphic_eq_rounded,
    MicState.processing => Icons.more_horiz_rounded,
    MicState.ready => Icons.mic_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final enabled = widget.onTap != null;
    final color = _color;
    return GestureDetector(
      onTap: enabled ? widget.onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: s * 1.8,
        height: s * 1.8,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final breathe = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.state == MicState.recording) ...[
                  _ring(s, color, t),
                  _ring(s, color, (t + 0.5) % 1.0),
                ],
                Container(
                  width: s * (1.18 + 0.06 * breathe),
                  height: s * (1.18 + 0.06 * breathe),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.16),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, Color.lerp(color, Colors.black, 0.22)!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 28,
                        spreadRadius: -4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.state == MicState.processing
                        ? SizedBox(
                            width: s * 0.34,
                            height: s * 0.34,
                            child: const CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_icon, color: Colors.white, size: s * 0.42),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _ring(double s, Color color, double t) => Container(
    width: s * (1.0 + t * 0.7),
    height: s * (1.0 + t * 0.7),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: color.withValues(alpha: (1 - t) * 0.5),
        width: 2,
      ),
    ),
  );
}
