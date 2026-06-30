import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Onboarding step shown once, right after a new user signs up, to capture
/// their name. The router redirects here whenever an authenticated user has no
/// name yet, and moves on to /home as soon as one is saved.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final name = _controller.text.trim();
    if (name.isEmpty) {
      _snack(l.nameEmpty);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(fullName: name);
      // The router redirect moves to /home once the name is set.
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
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
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
                  Icons.emoji_emotions_rounded,
                  color: AppColors.brandDeep,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              Text(l.nameTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpace.sm),
              Text(
                l.nameSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.xxxl),
              Text(
                l.nameLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              TextField(
                controller: _controller,
                enabled: !_loading,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                maxLength: 60,
                decoration: InputDecoration(
                  hintText: l.nameHint,
                  counterText: '',
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpace.xl),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.continueAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
