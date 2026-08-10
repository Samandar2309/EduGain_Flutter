import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/ui/error_handling.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';

/// "Tell us anything" — reached deliberately, from the profile.
///
/// The counterpart to the one-tap rating on a finished session: this is for
/// someone who went looking for the form because something is on their mind,
/// so here a text box is the right shape.
///
/// One box, no categories. Asking someone to decide whether their problem is
/// a bug or an idea before they may describe it is a toll charged on the
/// person doing us a favour. The platform and locale are attached silently
/// instead, because those are the questions triage actually starts with — and
/// unlike the category, the app already knows the answers.
class FeedbackFormScreen extends ConsumerStatefulWidget {
  const FeedbackFormScreen({super.key});

  @override
  ConsumerState<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends ConsumerState<FeedbackFormScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    final message = _controller.text.trim();
    if (message.isEmpty) {
      _snack(l.feedbackEmpty);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      await ref
          .read(feedbackRepositoryProvider)
          .report(message: message, locale: ref.read(languageCodeProvider));
      if (!mounted) return;
      _snack(l.feedbackThanks);
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      // The cap is generous enough that meeting it means something other than
      // having a lot to say, but the learner still deserves a real sentence
      // rather than the server's English one.
      _snack(e.statusCode == 429 ? l.feedbackTooMany : e.localized(l));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(l.feedbackSendTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.feedbackSendSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: _controller,
                enabled: !_sending,
                autofocus: true,
                minLines: 5,
                maxLines: 10,
                // Matches the server's cap, so a long report is trimmed while
                // it is being written rather than rejected after sending.
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l.feedbackHint),
              ),
              const SizedBox(height: AppSpace.lg),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.feedbackSend),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
