import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Step 2 — enter the 6-digit code; on success the auth status flips to
/// authenticated and the router moves to /home.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({required this.phone, super.key});

  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  int _resendIn = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendIn = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendIn = 0);
      } else if (mounted) {
        setState(() => _resendIn--);
      }
    });
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.length != 6) {
      _snack(AppLocalizations.of(context).otpEnter6);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .verifyOtp(widget.phone, code);
      ref.read(authControllerProvider.notifier).onAuthenticated(result.user);
      // The router redirect handles navigation to /home.
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0) return;
    final resent = AppLocalizations.of(context).otpResent;
    try {
      await ref.read(authRepositoryProvider).requestOtp(widget.phone);
      _startCooldown();
      _snack(resent);
    } on ApiException catch (e) {
      _snack(e.message);
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
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.sms_rounded,
                  color: AppColors.brandDeep,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              Text(l.otpTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpace.sm),
              Text(
                l.otpSentTo(widget.phone),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.xxxl),
              _OtpBoxes(
                controller: _controller,
                focusNode: _focus,
                enabled: !_loading,
                onChanged: (v) {
                  setState(() {});
                  if (v.length == 6) _verify();
                },
              ),
              const SizedBox(height: AppSpace.xxxl),
              FilledButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.verify),
              ),
              const SizedBox(height: AppSpace.lg),
              Center(
                child: _resendIn > 0
                    ? Text(
                        l.resendCountdown(
                          '0:${_resendIn.toString().padLeft(2, '0')}',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.inkFaint,
                        ),
                      )
                    : TextButton(
                        onPressed: _resend,
                        child: Text(l.resendCode),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Six segmented digit boxes driven by a single hidden [TextField].
class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final code = controller.text;
    final theme = Theme.of(context);
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            final filled = i < code.length;
            final active = i == code.length && focusNode.hasFocus;
            return Container(
              width: 48,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: active
                      ? AppColors.brand
                      : filled
                      ? AppColors.brand.withValues(alpha: 0.4)
                      : theme.colorScheme.outlineVariant,
                  width: active ? 1.8 : 1.2,
                ),
                boxShadow: filled || active ? AppShadow.soft : null,
              ),
              child: Text(
                filled ? code[i] : '',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              showCursor: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
