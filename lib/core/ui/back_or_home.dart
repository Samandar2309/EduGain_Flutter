import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The leading button for any screen a notification can open directly.
///
/// Flutter draws a back arrow only when there is something to pop. Arriving by
/// deep link there is not: the tapped route *is* the whole stack, so the app
/// bar came up bare and the only way out of the quiz — or a room, or the
/// partner search — was to close the Mini App and open it again.
///
/// So the button is always there, and what it does depends on how you got
/// here: pop when there is a screen behind, and otherwise go home, which is
/// where the back arrow would have led anyway.
class BackOrHome extends StatelessWidget {
  const BackOrHome({this.color, super.key});

  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(Icons.arrow_back_rounded, color: color),
    // `go` rather than `push`: this is a way out, and pushing home on top of
    // a deep-linked screen would leave that screen underneath to be found
    // again by the next back gesture.
    onPressed: () =>
        context.canPop() ? context.pop() : context.go('/home'),
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
  );
}

/// Leave the current screen, from anywhere it can be reached.
///
/// The same rule [BackOrHome] applies, for the buttons that are not app-bar
/// icons — a "Back" at the end of a call, a "Close" on a result panel. A bare
/// `context.pop()` in those places does nothing at all when a notification
/// opened the screen directly, which leaves the learner holding a button that
/// looks like the way out and is not.
void popOrHome(BuildContext context) =>
    context.canPop() ? context.pop() : context.go('/home');
