import 'package:flutter/material.dart';

import '../../../core/telegram_webapp.dart';
import '../../../core/ui/tokens.dart';

/// Shown inside the Telegram Mini App when the learner reached the app WITHOUT
/// registering — they opened it via the menu button instead of completing the
/// bot's /start phone-share step, so no phone is on file. Registration lives in
/// the bot, so we send them back there rather than showing an in-app sign-up
/// form (the phone/Google/OTP flow stays hidden inside Telegram).
class RegisterInBotScreen extends StatelessWidget {
  const RegisterInBotScreen({super.key});

  // Deep link with a start payload so opening it triggers the bot's /start,
  // which shows the "share phone number" button straight away.
  static const _botUrl = 'https://t.me/edugain_bot?start=register';

  @override
  Widget build(BuildContext context) {
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
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                const Text(
                  "Ro'yxatdan o'tish",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                const Text(
                  "Davom etish uchun avval botda ro'yxatdan o'ting: "
                  "/start ni bosib, telefon raqamingizni yuboring. "
                  "Bu bir necha soniya oladi.",
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
                    onPressed: () => TelegramWebApp.openTelegramLink(_botUrl),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      "Botda ro'yxatdan o'tish",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
