import 'package:flutter/material.dart';

import '../config.dart';

/// A learner's profile picture, wherever it is drawn.
///
/// The server stores the avatar as a **relative** path
/// (`/api/v1/auth/avatar/{id}.jpg`) so it survives the deployment moving. That is correct for the
/// Mini App, which is served from the same origin as the API, and wrong for the
/// Android build, whose API lives on another host entirely — so the path is
/// resolved against the configured API base here, once, rather than at nine
/// call sites.
///
/// Everything about this is best-effort: a learner may have no Telegram photo,
/// may have hidden it, or may be offline. Every one of those has to end in the
/// initial-letter circle the app has always drawn, never a broken-image glyph
/// and never an exception.
class UserPhoto extends StatelessWidget {
  const UserPhoto({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
  });

  /// Absolute, or relative to the API host, or empty.
  final String url;
  final double size;

  /// Drawn while loading, when there is no photo, and when fetching fails.
  final Widget fallback;

  /// The absolute URL to fetch, or null when there is nothing to fetch.
  static String? resolve(String? url) {
    final raw = (url ?? '').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (!raw.startsWith('/')) return null;

    final base = AppConfig.apiBaseUrl;
    // A relative API base means the app is served from the same origin as the
    // API, so a root-relative path already points at the right place.
    if (base.startsWith('/')) return raw;

    final origin = Uri.tryParse(base);
    if (origin == null) return raw;
    return origin.replace(path: raw, query: null).toString();
  }

  @override
  Widget build(BuildContext context) {
    final src = resolve(url);
    if (src == null) return fallback;
    return ClipOval(
      child: Image.network(
        src,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // The letter circle, not a spinner: a room of fifty people should not
        // flicker with fifty spinners on the way in.
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (context, error, stack) => fallback,
      ),
    );
  }
}
