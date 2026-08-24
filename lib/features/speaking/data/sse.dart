import 'dart:convert';
import 'dart:typed_data';

import '../domain/models.dart';

/// Audio rides the stream base64-encoded, because SSE is a text protocol.
/// Absent (the server could not render the sentence) or corrupt both mean "no
/// audio for this one" — the caller falls back to asking for it, so a bad
/// frame costs a round trip rather than the line.
Uint8List? _decodeAudio(Object? b64) {
  if (b64 is! String || b64.isEmpty) return null;
  try {
    return base64Decode(b64);
  } on FormatException {
    return null;
  }
}

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
    'transcript' => TranscriptEvent(
      payload['text'] as String? ?? '',
      clarity: (payload['clarity'] as num?)?.toDouble(),
    ),
    'chunk' => ChunkEvent(payload['text'] as String? ?? ''),
    'audio' => AudioEvent(
      (payload['seq'] as num?)?.toInt() ?? 0,
      payload['text'] as String? ?? '',
      _decodeAudio(payload['b64']),
    ),
    'coaching' => CoachingEvent(
      Coaching.fromJson(payload['coaching'] as Map<String, dynamic>),
    ),
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
