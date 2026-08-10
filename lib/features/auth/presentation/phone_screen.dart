import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config.dart';
import '../../../core/locale_controller.dart';
import '../../../core/providers.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/language_picker.dart';
import '../../../core/ui/tokens.dart';
import '../../../core/ui/error_handling.dart';
import '../../../l10n/app_localizations.dart';

/// Step 1 of passwordless login — enter the phone number, get an OTP.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController(text: '+998');
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final phone = _controller.text.trim();
    if (!AppConfig.phonePattern.hasMatch(phone)) {
      _snack(AppLocalizations.of(context).phoneInvalid);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).requestOtp(phone);
      if (mounted) context.push('/login/otp', extra: phone);
    } on ApiException catch (e) {
      _snack(e.localized(l));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    final l = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final idToken = await ref.read(googleSignInServiceProvider).signIn();
      if (idToken == null) return; // user cancelled
      final result = await ref
          .read(authRepositoryProvider)
          .signInWithGoogle(idToken);
      ref.read(authControllerProvider.notifier).onAuthenticated(result.user);
      // The router redirect handles navigation to /home.
    } on ApiException catch (e) {
      _snack(e.localized(l));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => showLanguagePicker(context),
                    icon: const Icon(Icons.translate_rounded, size: 20),
                    label: Text(
                      AppLanguage.fromCode(
                            Localizations.localeOf(context).languageCode,
                          )?.endonym ??
                          l.languageTitle,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: AppLogo(size: 76)),
                const SizedBox(height: AppSpace.xxl),
                Text(
                  l.welcomeTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  l.phoneSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.xxxl),
                Text(
                  l.phoneLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  enabled: !_loading,
                  style: theme.textTheme.titleMedium?.copyWith(
                    letterSpacing: 0.5,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    LengthLimitingTextInputFormatter(13),
                  ],
                  decoration: const InputDecoration(
                    hintText: '+998 90 123 45 67',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpace.xl),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const _BtnSpinner() : Text(l.sendCode),
                ),
                const SizedBox(height: AppSpace.xl),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        l.dividerOr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpace.xl),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _google,
                  icon: const Icon(Icons.account_circle_rounded, size: 22),
                  label: Text(l.googleSignIn),
                ),
                const SizedBox(height: AppSpace.xxl),
                Text(
                  l.termsNotice,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.inkFaint,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BtnSpinner extends StatelessWidget {
  const _BtnSpinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 22,
    width: 22,
    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
  );
}
