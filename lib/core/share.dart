import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api/api_client.dart';
import 'telegram_webapp.dart';

/// What actually happened when the learner tapped "invite a friend". The caller
/// tells them — a share button that silently does nothing is the bug this
/// return value exists to make impossible.
enum ShareOutcome {
  /// Telegram's own chat picker opened over the still-running Mini App.
  sheetOpened,

  /// The share link opened in the Telegram app (outside a Mini App).
  linkOpened,

  /// Nothing could be opened, so the invite is on the clipboard instead.
  copied,
}

/// Register the invite with Telegram so it can be shared without navigating.
///
/// Null on any failure — no bot token, no linked Telegram account, Bot API
/// refusal. Inviting a friend is never worth an error dialog mid-call, so the
/// caller just falls back.
Future<String?> prepareInvite(
  ApiClient api, {
  required String text,
  String title = 'EduGain',
}) async {
  try {
    final data = await api.post(
      '/invite/prepare',
      body: {'text': text, 'title': title},
    );
    final id = data['prepared_message_id'];
    return (id is String && id.isNotEmpty) ? id : null;
  } catch (_) {
    return null;
  }
}

/// Hand an invite to Telegram's share sheet, keeping the Mini App alive.
///
/// Inside a Mini App the only route that does NOT tear the app down is
/// `shareMessage` (Bot API 8.0): Telegram draws its chat picker on top and the
/// call the learner is sitting in keeps running. `openTelegramLink` and
/// `url_launcher` both steer the WebView away, which Telegram treats as leaving
/// the app — so neither is used there, not even as a fallback. When the native
/// sheet is unavailable the invite goes to the clipboard, which keeps the
/// learner exactly where they are.
///
/// Outside Telegram (a browser, or the native mobile build) there is no bridge
/// and nothing to lose, so the ordinary external launch is correct.
Future<ShareOutcome> shareInvite(
  String text, {
  Future<String?> Function()? prepare,
}) async {
  if (TelegramWebApp.isTelegram) {
    if (prepare != null && TelegramWebApp.canShareMessage) {
      final id = await prepare();
      if (id != null && TelegramWebApp.shareMessage(id)) {
        return ShareOutcome.sheetOpened;
      }
    }
    await Clipboard.setData(ClipboardData(text: text));
    return ShareOutcome.copied;
  }

  final uri = Uri.parse(
    'https://t.me/share/url?url=&text=${Uri.encodeComponent(text)}',
  );
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return ShareOutcome.linkOpened;
    }
  } catch (_) {
    // No Telegram installed / no handler — fall through to the clipboard.
  }
  await Clipboard.setData(ClipboardData(text: text));
  return ShareOutcome.copied;
}

/// Open somebody's Telegram profile — ours, from the profile screen.
///
/// Inside a Mini App this deliberately uses `openTelegramLink`, the one call
/// [shareInvite] refuses: it steers the WebView to the chat, which Telegram
/// treats as leaving the app. That is wrong mid-call and exactly right here —
/// someone tapping "message the developer" is asking to be taken to a chat.
///
/// Returns false when nothing could be opened, so the caller can put the
/// username on the clipboard rather than appearing to do nothing.
Future<bool> openTelegramProfile(String username) async {
  final handle = username.startsWith('@') ? username.substring(1) : username;
  if (TelegramWebApp.isTelegram) {
    TelegramWebApp.openTelegramLink('https://t.me/$handle');
    return true;
  }
  try {
    return await launchUrl(
      Uri.parse('https://t.me/$handle'),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    // No Telegram, no browser handler — the caller copies instead.
    return false;
  }
}
