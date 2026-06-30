import 'package:flutter/material.dart';

import '../../../../core/ui/glass.dart';
import '../../../../core/ui/tokens.dart';

/// A small frosted-glass action chip (Translate / Hint) flanking the mic.
class GlassAction extends StatelessWidget {
  const GlassAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.accent = AppColors.brand,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tint = active ? accent : Colors.white;
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: GlassPanel(
          radius: AppRadius.lg,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.md,
          ),
          opacity: active ? 0.18 : 0.10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: tint, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: tint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
