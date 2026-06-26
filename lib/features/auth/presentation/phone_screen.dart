import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config.dart';
import '../../../core/providers.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';

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
    final phone = _controller.text.trim();
    if (!AppConfig.phonePattern.hasMatch(phone)) {
      _snack('Telefon raqamini to\'g\'ri kiriting (+998XXXXXXXXX)');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).requestOtp(phone);
      if (mounted) context.push('/login/otp', extra: phone);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
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
      _snack(e.message);
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(child: AppLogo(size: 76)),
                const SizedBox(height: AppSpace.xxl),
                Text(
                  'Xush kelibsiz 👋',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Davom etish uchun telefon raqamingizni kiriting',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.xxxl),
                Text(
                  'Telefon raqam',
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
                  child: _loading
                      ? const _BtnSpinner()
                      : const Text('Kod yuborish'),
                ),
                const SizedBox(height: AppSpace.xl),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'yoki',
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
                  label: const Text('Google bilan kirish'),
                ),
                const SizedBox(height: AppSpace.xxl),
                Text(
                  'Davom etish orqali siz Foydalanish shartlari va '
                  'Maxfiylik siyosatiga rozilik bildirasiz',
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
