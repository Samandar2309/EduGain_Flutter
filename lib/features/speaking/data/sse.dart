import 'dart:convert';

import '../domain/models.dart';

/// Parse one SSE block (`event: <name>\ndata: <json>`) into a [SpeakingEvent].
/// Returns null for unknown/malformed blocks (e.g. heartbeats).
SpeakingEvent? parseSseEvent(String block) {
  String? name;
  final dataLines = <String>[];
  for (final line in block.split('\n')) {
    if (line.startsWith('event:')) {
      name = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      dataLines.add(line.substring(5).trim());
    }
  }
  if (name == null || dataLines.isEmpty) return null;

  final Map<String, dynamic> payload;
  try {
    payload = jsonDecode(dataLines.join('\n')) as Map<String, dynamic>;
  } on FormatException {
    return null;
  }

  return switch (name) {
    'chunk' => ChunkEvent(payload['text'] as String? ?? ''),
    'done' => DoneEvent(
      SpeakingSession.fromJson(payload['session'] as Map<String, dynamic>),
    ),
    'error' => StreamErrorEvent(
      payload['code'] as String? ?? 'AI_UNAVAILABLE',
      payload['message'] as String? ?? '',
    ),
    _ => null,
  };
}
