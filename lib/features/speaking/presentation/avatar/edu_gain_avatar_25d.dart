import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../scenario_theme.dart';
import 'avatar_state.dart';

/// A premium 2.5D Hero Avatar for EduGain.
/// It uses a layered approach (Parallax) to create a 3D feel with 2D assets.
/// Supports idle breathing, blinking, and real-time lip-sync.
class EduGainAvatar25D extends StatefulWidget {
  const EduGainAvatar25D({
    required this.backdrop,
    required this.emotion,
    required this.state,
    required this.level,
    this.size = 350,
    this.fillScreen = false,
    this.onReady,
    this.avatarKey = 'aria',
    super.key,
  });

  final ScenarioBackdrop backdrop;
  final String emotion;
  final AvatarState state;
  final ValueListenable<double> level;
  final double size;
  final bool fillScreen;
  final VoidCallback? onReady;
  final String avatarKey;

  @override
  State<EduGainAvatar25D> createState() => _EduGainAvatar25DState();
}

class _EduGainAvatar25DState extends State<EduGainAvatar25D> with TickerProviderStateMixin {
  late final AnimationController _idleController;
  double _blinkOpacity = 0.0;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _startBlinkCycle();

    // 2.5D avatar is ready immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onReady?.call();
    });
  }

  void _startBlinkCycle() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2500 + _random.nextInt(3500)));
      if (!mounted) return;
      setState(() => _blinkOpacity = 1.0);
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() => _blinkOpacity = 0.0);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basePath = 'assets/avatars/${widget.avatarKey}';
    
    // In fullScreen mode, we scale the avatar to fill height but keep it centered
    final displaySize = widget.fillScreen ? MediaQuery.of(context).size.shortestSide * 1.2 : widget.size;

    return Center(
      child: SizedBox(
        width: displaySize,
        height: displaySize,
        child: AnimatedBuilder(
          animation: _idleController,
          builder: (context, _) {
            final t = _idleController.value;
            final breathe = math.sin(t * math.pi);
            final headSway = math.cos(t * math.pi) * 0.015;

            return ValueListenableBuilder<double>(
              valueListenable: widget.level,
              builder: (context, lvl, _) {
                final mouthScale = 0.4 + (lvl * 1.1).clamp(0.0, 1.0);

                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Layer 1: Hair Back (lowest parallax)
                    _buildLayer('$basePath/hair_back.png', displaySize,
                        offset: Offset(0, breathe * 2), rotation: headSway * 0.5),

                    // Layer 2: Body (stable base)
                    _buildLayer('$basePath/body.png', displaySize,
                        offset: Offset(0, breathe * 4 + (widget.fillScreen ? 40 : 0))),

                    // Layer 3: Head Base
                    _buildLayer('$basePath/head.png', displaySize,
                        offset: Offset(0, breathe * 6 - 5), rotation: headSway),

                    // Layer 4: Eyes (Open)
                    _buildLayer('$basePath/eyes_open.png', displaySize,
                        offset: Offset(0, breathe * 6 - 5), rotation: headSway),
                    
                    // Layer 4b: Eyes (Closed/Blink)
                    Opacity(
                      opacity: _blinkOpacity,
                      child: _buildLayer('$basePath/eyes_closed.png', displaySize,
                          offset: Offset(0, breathe * 6 - 5), rotation: headSway),
                    ),

                    // Layer 5: Eyebrows
                    _buildLayer('$basePath/brows_${widget.emotion}.png', displaySize,
                        offset: Offset(0, breathe * 6 - 5), rotation: headSway),

                    // Layer 6: Mouth (Lip-sync)
                    _buildMouthLayer('$basePath/mouth.png', displaySize,
                        offset: Offset(0, breathe * 6 - 5), 
                        rotation: headSway, 
                        scaleY: mouthScale),

                    // Layer 7: Hair Front (highest parallax)
                    _buildLayer('$basePath/hair_front.png', displaySize,
                        offset: Offset(0, breathe * 9 - 10), rotation: headSway * 1.3),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLayer(String path, double size, {Offset offset = Offset.zero, double rotation = 0}) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotation,
        child: Image.asset(
          path,
          width: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildMouthLayer(String path, double size, {required Offset offset, required double rotation, required double scaleY}) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scaleY: scaleY,
          alignment: const Alignment(0, 0.2), // Anchor to the upper lip area
          child: Image.asset(
            path,
            width: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
