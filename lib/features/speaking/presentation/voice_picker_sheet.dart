import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../data/audio_playback.dart';
import '../data/device_tts.dart';
import '../domain/models.dart';

/// Open the voice picker as a modal bottom sheet. The chosen voice is persisted
/// by [selectedVoiceProvider]; nothing is returned (the caller watches the
/// provider).
///
/// [showAddVoices] gates the "where voices come from" panel. It defaults to
/// whether the device engine is the one speaking, because that is the only
/// case where the platform's own roster is what the learner is choosing from —
/// and it is named rather than inlined so a render test can show the panel on
/// a host that has no speech engine at all.
Future<void> showVoicePicker(BuildContext context, {bool? showAddVoices}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _VoicePickerSheet(
      showAddVoices: showAddVoices ?? DeviceTtsPlatform.supported,
    ),
  );
}

class _VoicePickerSheet extends ConsumerStatefulWidget {
  const _VoicePickerSheet({required this.showAddVoices});

  final bool showAddVoices;

  @override
  ConsumerState<_VoicePickerSheet> createState() => _VoicePickerSheetState();
}

class _VoicePickerSheetState extends ConsumerState<_VoicePickerSheet> {
  // A short, neutral line so the learner hears the voice's tone and accent.
  static const _sample =
      "Hi! I'm your speaking partner. Let's practise English together.";

  // Own preview player so it never collides with the live chat's TtsService.
  final AudioPlayback _preview = createAudioPlayback();
  String? _previewingId; // voice currently being previewed (spinner)
  bool _closed = false;

  @override
  void dispose() {
    _closed = true;
    unawaited(_preview.dispose());
    super.dispose();
  }

  Future<void> _play(Voice voice) async {
    final l = AppLocalizations.of(context);
    // Tapping the same row again stops the preview.
    if (_previewingId == voice.id) {
      await _preview.stop();
      if (mounted) setState(() => _previewingId = null);
      return;
    }
    await _preview.stop();
    DeviceTtsPlatform.stop();
    if (mounted) setState(() => _previewingId = voice.id);
    try {
      if (DeviceTtsPlatform.supported) {
        // Preview through the engine that will actually speak. Fetching a clip
        // here would demo a voice the learner is never going to hear — and pay
        // a provider to do it.
        DeviceTtsPlatform.select(voice.id);
        await DeviceTtsPlatform.speak(_sample);
        return;
      }
      final bytes = await ref
          .read(speakingRepositoryProvider)
          .synthesizeSpeech(_sample, voice.id);
      if (_closed) return;
      await _preview.play(bytes);
    } catch (_) {
      if (mounted && !_closed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.voicePreviewError)));
      }
    } finally {
      if (mounted && _previewingId == voice.id) {
        setState(() => _previewingId = null);
      }
    }
  }

  Future<void> _select(String voiceId) async {
    await ref.read(selectedVoiceProvider.notifier).select(voiceId);
    // The device engine holds the choice itself, so tell it now rather than
    // waiting for the chat screen to rebuild — the learner may preview and
    // close the sheet before that happens.
    if (DeviceTtsPlatform.supported) DeviceTtsPlatform.select(voiceId);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final voicesAsync = ref.watch(voicesProvider);
    final selected = ref.watch(selectedVoiceProvider).id;
    final media = MediaQuery.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                l.chooseVoice,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    voicesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l.voicesLoadError),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => ref.invalidate(voicesProvider),
                              child: Text(l.retry),
                            ),
                          ],
                        ),
                      ),
                      data: (voices) => voices.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(l.noVoices),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              // The sheet scrolls now, so the list must not: two
                              // nested scrollables fight each other and the drag
                              // lands on whichever one guesses first.
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: voices.length,
                              itemBuilder: (context, i) {
                                final v = voices[i];
                                // Default highlight: first voice when none chosen yet.
                                final isSelected = selected == null
                                    ? i == 0
                                    : selected == v.id;
                                return _VoiceTile(
                                  voice: v,
                                  selected: isSelected,
                                  previewing: _previewingId == v.id,
                                  onSelect: () => _select(v.id),
                                  onPreview: () => _play(v),
                                );
                              },
                            ),
                    ),
                    if (widget.showAddVoices) const _AddVoicesPanel(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What to do when none of the offered voices is good enough.
///
/// A web page cannot install a voice — there is no such API, and there should
/// not be: a page that could write to the system's speech engine could write
/// anywhere. Every voice here belongs to the operating system. So rather than
/// leave a learner with a short list and no explanation, this says where the
/// voices actually live and how to add one, in the words of the platform they
/// are holding — and then offers to look again, because a voice installed
/// while the app was open does not always announce itself.
class _AddVoicesPanel extends ConsumerWidget {
  const _AddVoicesPanel();

  String _steps(AppLocalizations l) {
    switch (DeviceTtsPlatform.platform) {
      case 'android':
        return l.voiceStepsAndroid;
      case 'ios':
        return l.voiceStepsIos;
      case 'windows':
        return l.voiceStepsWindows;
      case 'mac':
        return l.voiceStepsMac;
      default:
        return l.voiceStepsGeneric;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Card(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(Icons.library_add_rounded, color: scheme.primary),
          title: Text(
            l.voiceAddMore,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.voiceAddMoreIntro, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 12),
            Text(
              _steps(l),
              style: TextStyle(height: 1.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => ref.invalidate(voicesProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l.voiceRefresh),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceTile extends StatelessWidget {
  const _VoiceTile({
    required this.voice,
    required this.selected,
    required this.previewing,
    required this.onSelect,
    required this.onPreview,
  });

  final Voice voice;
  final bool selected;
  final bool previewing;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  String _subtitle(AppLocalizations l) {
    final parts = [
      if (voice.gender.isNotEmpty) _genderLabel(l, voice.gender),
      if (voice.accent.isNotEmpty) voice.accent,
    ];
    return parts.join(' · ');
  }

  static String _genderLabel(AppLocalizations l, String g) =>
      g == 'female' ? l.genderFemale : (g == 'male' ? l.genderMale : g);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final subtitle = _subtitle(l);
    return ListTile(
      onTap: onSelect,
      leading: CircleAvatar(
        backgroundColor: selected
            ? scheme.primary
            : scheme.surfaceContainerHighest,
        child: Icon(
          voice.gender == 'female' ? Icons.face_rounded : Icons.face_rounded,
          color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        voice.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onPreview,
            tooltip: l.voicePreview,
            icon: previewing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_circle_outline_rounded),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: scheme.primary)
          else
            const SizedBox(width: 24),
        ],
      ),
    );
  }
}
