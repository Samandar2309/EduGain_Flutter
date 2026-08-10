import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';

/// "How was that conversation?" — five stars at the foot of the result sheet.
///
/// Not a separate step and not a modal. Someone who has just finished speaking
/// wants their score, not a survey, so this rides along inside a screen they
/// already came to read, and costs one tap to answer or none to ignore.
///
/// The star is sent the moment it is tapped, before anything is typed. Most
/// people will never write a comment, and holding the rating until they do
/// would throw away every one of those votes. The comment, when it comes,
/// updates the same vote — the server upserts on (learner, session).
class SessionRatingStrip extends ConsumerStatefulWidget {
  const SessionRatingStrip({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<SessionRatingStrip> createState() => _SessionRatingStripState();
}

class _SessionRatingStripState extends ConsumerState<SessionRatingStrip> {
  static const _maxStars = 5;

  final _comment = TextEditingController();
  int? _stars;
  bool _commentSent = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _send({String comment = ''}) {
    final stars = _stars;
    if (stars == null) return;
    // Deliberately not awaited and never surfaced. A rating is a courtesy the
    // learner did us; an error about it, on the screen showing their result,
    // would be us charging them for it.
    ref
        .read(feedbackRepositoryProvider)
        .rateSession(
          sessionId: widget.sessionId,
          stars: stars,
          comment: comment,
          locale: ref.read(languageCodeProvider),
        )
        .catchError((_) {});
  }

  void _rate(int stars) {
    HapticFeedback.selectionClick();
    setState(() => _stars = stars);
    // Sent on the tap itself — see the class comment.
    _send(comment: _comment.text.trim());
  }

  void _sendComment() {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    setState(() => _commentSent = true);
    _send(comment: text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rated = _stars != null;

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rated ? l.rateSessionThanks : l.rateSessionQuestion,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= _maxStars; star++)
                _Star(
                  index: star,
                  filled: star <= (_stars ?? 0),
                  onTap: () => _rate(star),
                ),
            ],
          ),
          // Offered whatever the score. A five-star session can still have one
          // thing worth telling us, and a learner should not have to rate us
          // badly to earn the right to explain.
          if (rated) ...[
            const SizedBox(height: AppSpace.md),
            if (_commentSent)
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.rateSessionCommentSent,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              TextField(
                controller: _comment,
                minLines: 2,
                maxLines: 4,
                // Matches the server's cap, so a long note is trimmed while it
                // is written rather than rejected after sending.
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: l.rateSessionCommentHint,
                  counterText: '',
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _sendComment,
                  child: Text(l.feedbackSend),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.index,
    required this.filled,
    required this.onTap,
  });

  final int index;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: filled,
      // Screen readers get "3 stars", not "star, star, star".
      label: '$index',
      child: IconButton(
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          scale: filled ? 1.12 : 1,
          child: Icon(
            filled ? Icons.star : Icons.star_outline,
            size: 34,
            color: filled ? AppColors.xp : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
