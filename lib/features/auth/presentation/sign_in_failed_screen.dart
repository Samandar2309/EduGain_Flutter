import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/telegram_webapp.dart';
import '../../../core/ui/tokens.dart';

/// Shown inside the Telegram Mini App when signing in genuinely failed.
///
/// This used to double as a "go and register in the bot" screen, and that was
/// the problem: a learner who HAD registered but whose silent sign-in hiccuped
/// was told to press /start, which cannot mint a Mini App session — so the
/// advice sent them in a circle they could not leave. Registration is now the
/// bot's job alone and no longer routes anyone here, which leaves exactly one
/// reason to be on this screen and exactly one useful thing to offer: try
/// again.
///
/// The details panel stays. When sign-in fails inside Telegram there is
/// nothing in any server log to look at — the request never arrives — so the
/// client has to be able to say what it saw.
class SignInFailedScreen extends ConsumerStatefulWidget {
  const SignInFailedScreen({super.key});

  @override
  ConsumerState<SignInFailedScreen> createState() =>
      _SignInFailedScreenState();
}

class _SignInFailedScreenState extends ConsumerState<SignInFailedScreen> {
  bool _busy = false;
  bool _showDetails = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    await ref.read(authControllerProvider.notifier).retrySignIn();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(authControllerProvider).signInReport;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppGradients.accent(AppColors.speaking),
                    shape: BoxShape.circle,
                    boxShadow: AppShadow.glow(AppColors.speaking),
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                const Text(
                  "Kira olmadik",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                const Text(
                  "Ulanishda muammo bo'ldi. Qayta urinib ko'ring — "
                  "odatda shu yetarli.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.speaking,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: _busy ? null : _retry,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text(
                      'Qayta urinish',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                // Kept quiet by default, but reachable: when sign-in fails
                // inside Telegram there is nothing else to go on, for the
                // learner or for whoever they report it to.
                TextButton(
                  onPressed: () =>
                      setState(() => _showDetails = !_showDetails),
                  child: Text(
                    _showDetails ? 'Tafsilotlarni yashirish' : 'Tafsilotlar',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ),
                if (_showDetails)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: SelectableText(
                      'Telegram SDK: ${TelegramWebApp.sdkPresent ? "bor" : "yo‘q"}\n'
                      'initData: ${TelegramWebApp.initData?.length ?? 0} belgi\n'
                      '${report ?? "—"}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        color: AppColors.inkSoft,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
