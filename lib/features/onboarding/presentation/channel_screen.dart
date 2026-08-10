import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/telegram_webapp.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/channel_gate_controller.dart';

/// "Join our channel" — the last onboarding step, and the only one a learner
/// has to leave the app to satisfy.
///
/// That round trip is what shapes the screen. There is no "skip", but there is
/// also no way to get stuck: the second button re-asks the server, and the
/// server never caches a no, so subscribing and coming straight back works the
/// first time. If the check itself is broken — the bot lost admin rights on
/// the channel, Telegram is unreachable — the router never routes here at all,
/// because the gate fails open.
class ChannelScreen extends ConsumerStatefulWidget {
  const ChannelScreen({super.key});

  @override
  ConsumerState<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends ConsumerState<ChannelScreen> {
  bool _checking = false;

  Future<void> _openChannel(String url) async {
    if (url.isEmpty) return;
    HapticFeedback.selectionClick();
    if (TelegramWebApp.isTelegram) {
      // Keeps the learner inside Telegram rather than bouncing them out to a
      // browser, which is where a plain t.me link would land them.
      TelegramWebApp.openTelegramLink(url);
      return;
    }
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on Object {
      // No Telegram installed and no handler for the link. The other button
      // still works, so there is nothing useful to say here.
    }
  }

  Future<void> _recheck() async {
    final l = AppLocalizations.of(context);
    setState(() => _checking = true);
    await ref.read(channelGateProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _checking = false);
    // Still here means the router did not move us on, so the server did not
    // see them in the channel. Saying so is the whole point — silence would
    // read as a dead button.
    if (ref.read(channelGateProvider).mustJoin) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.channelNotYet)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gate = ref.watch(channelGateProvider).gate;
    final handle = (gate?.username ?? '').isEmpty ? '' : '@${gate!.username}';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppGradients.accent(AppColors.brand),
                        shape: BoxShape.circle,
                        boxShadow: AppShadow.glow(AppColors.brand),
                      ),
                      child: const Icon(
                        Icons.campaign,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    Text(l.channelTitle, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      l.channelSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (handle.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xl),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.lg,
                          vertical: AppSpace.lg,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.line),
                          boxShadow: AppShadow.card,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.send,
                              color: AppColors.brand,
                              size: 28,
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Text(
                                handle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _checking
                        ? null
                        : () => _openChannel(gate?.url ?? ''),
                    icon: const Icon(Icons.open_in_new, size: 20),
                    label: Text(l.channelOpenAction),
                  ),
                  const SizedBox(height: AppSpace.md),
                  OutlinedButton(
                    onPressed: _checking ? null : _recheck,
                    child: _checking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Text(l.channelJoinedAction),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
