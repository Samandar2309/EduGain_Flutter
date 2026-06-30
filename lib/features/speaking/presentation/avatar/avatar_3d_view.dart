import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

import '../scenario_theme.dart';
import 'avatar_state.dart';
import 'avatar_view.dart';

/// The live 3D tutor. A transparent [WebView] hosts a three.js scene
/// (`assets/avatar3d/avatar.html`) that renders a rigged Ready Player Me model
/// and lip-syncs to the TTS amplitude in real time, so the character's mouth
/// moves with the words and its face carries the turn's emotion.
///
/// It shares the [AvatarView] contract (`backdrop` / `emotion` / `level`) plus a
/// conversational [state]. Until the engine reports `ready` — and forever if the
/// platform can't run it — the proven [AvatarView] is shown underneath, so the
/// stage always has a face and never blocks the conversation.
class Avatar3DView extends StatefulWidget {
  const Avatar3DView({
    required this.backdrop,
    required this.emotion,
    required this.state,
    required this.level,
    this.size = 230,
    this.fillScreen = false,
    this.onReady,
    super.key,
  });

  final ScenarioBackdrop backdrop;
  final String emotion;
  final AvatarState state;
  final ValueListenable<double> level;
  final double size;

  /// When true the avatar is the whole stage: a transparent, edge-to-edge scene
  /// composited over the scenario photo, framed head-and-chest like a person
  /// standing in front of you. When false it's the small framed bust.
  final bool fillScreen;

  /// Fires once the stage has settled — either the 3D engine reported `ready`
  /// or it fell back to the 2D avatar. The screen waits for this before playing
  /// the greeting, so the first words land while the hero's mouth is on screen.
  final VoidCallback? onReady;

  @override
  State<Avatar3DView> createState() => _Avatar3DViewState();
}

class _Avatar3DViewState extends State<Avatar3DView> {
  /// Full-screen avatars render the WebView at this fraction of the screen and
  /// upscale it, so the texture Android copies each frame stays small. 0.7 keeps
  /// the figure crisp enough while cutting that copy to ~half of full size.
  static const double _fullRenderScale = 0.7;

  WebViewController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _modelSent = false;
  bool _disposed = false;
  bool _readySignaled = false;
  double _lastLevel = -1;
  int _lastLevelSentMs = 0;
  Timer? _watchdog;

  /// `#RRGGBB` for the WebGL background, without the deprecated `Color.value`.
  static String _hex(Color c) {
    int b(double x) => (x * 255.0).round().clamp(0, 255);
    String h(int v) => v.toRadixString(16).padLeft(2, '0');
    return '#${h(b(c.r))}${h(b(c.g))}${h(b(c.b))}';
  }

  /// Tell the screen the stage is ready to be spoken to — exactly once, whether
  /// we arrived via a live 3D scene or a fallback.
  void _signalReady() {
    if (_readySignaled) return;
    _readySignaled = true;
    widget.onReady?.call();
  }

  @override
  void initState() {
    super.initState();
    _boot();
    widget.level.addListener(_onLevel);
  }

  Future<void> _boot() async {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..addJavaScriptChannel('Bridge', onMessageReceived: _onBridge);
      await controller.loadFlutterAsset(
        'assets/avatar3d/avatar.html',
      );
      if (_disposed) return;
      setState(() => _controller = controller);
      // If the engine never reports ready (old WebView / no WebGL), fall back.
      _watchdog = Timer(const Duration(seconds: 12), () {
        if (!_ready && mounted) setState(() => _failed = true);
        _signalReady();
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      _signalReady();
    }
  }

  void _onBridge(JavaScriptMessage message) {
    Map<String, dynamic> msg;
    try {
      msg = json.decode(message.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (msg['type']) {
      case 'need-model':
        unawaited(_sendModel());
      case 'ready':
        _watchdog?.cancel();
        if (mounted) setState(() => _ready = true);
        _pushView(); // portrait bust vs full-screen framing
        // Full-screen composites over the Flutter scenario photo, so it stays
        // transparent; the framed bust paints its own themed stage.
        if (!widget.fillScreen) _pushBackground();
        _push(); // apply current state/emotion immediately
        _signalReady();
      case 'error':
        _watchdog?.cancel();
        if (mounted) setState(() => _failed = true);
        _signalReady();
    }
  }

  /// Stream the GLB to the engine as chunked base64 (avoids any file:// fetch
  /// and keeps each JS call small), then ask it to parse.
  Future<void> _sendModel() async {
    final c = _controller;
    if (c == null || _modelSent) return;
    _modelSent = true;
    try {
      final data = await rootBundle.load(widget.backdrop.model3dAsset);
      final b64 = base64Encode(data.buffer.asUint8List());
      const chunk = 256 * 1024;
      for (var i = 0; i < b64.length; i += chunk) {
        if (_disposed) return;
        final part = b64.substring(i, min(i + chunk, b64.length));
        await c.runJavaScript("window.AV.feedChunk('$part')");
      }
      if (_disposed) return;
      await c.runJavaScript('window.AV.feedDone()');
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onLevel() {
    if (!_ready || _disposed) return;
    final v = widget.level.value;
    // Hard-cap bridge traffic to ~15 messages/sec: each runJavaScript is a
    // platform-channel hop that contends with the WebView's compositing, so a
    // flood of amplitude ticks is a real jank source. The JS side smooths and
    // fills detail with its own oscillator, so 15Hz is plenty.
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastLevelSentMs < 66) return;
    if ((v - _lastLevel).abs() < 0.01) return;
    _lastLevelSentMs = now;
    _lastLevel = v;
    unawaited(
      _controller?.runJavaScript('window.AV.setLevel(${v.toStringAsFixed(3)})'),
    );
  }

  void _push() {
    final c = _controller;
    if (c == null || !_ready) return;
    unawaited(c.runJavaScript("window.AV.setState('${widget.state.name}')"));
    unawaited(c.runJavaScript("window.AV.setEmotion('${widget.emotion}')"));
  }

  void _pushView() {
    final c = _controller;
    if (c == null) return;
    unawaited(c.runJavaScript(
        "window.AV.setView('${widget.fillScreen ? 'full' : 'portrait'}')"));
  }

  void _pushBackground() {
    final c = _controller;
    if (c == null) return;
    final b = widget.backdrop;
    unawaited(c.runJavaScript(
      "window.AV.setBackground('${_hex(b.top)}','${_hex(b.bottom)}',"
      "'${_hex(b.accent)}')",
    ));
  }

  @override
  void didUpdateWidget(Avatar3DView old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state || old.emotion != widget.emotion) _push();
  }

  @override
  void dispose() {
    _disposed = true;
    _watchdog?.cancel();
    widget.level.removeListener(_onLevel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = AvatarView(
      backdrop: widget.backdrop,
      emotion: widget.emotion,
      level: widget.level,
      size: widget.size,
    );

    if (_failed) {
      return widget.fillScreen ? Center(child: fallback) : fallback;
    }

    // Full-screen immersive stage: a transparent, edge-to-edge scene over the
    // scenario photo. The WebView is rendered below native size (FittedBox) so
    // the per-frame texture copy — the jank driver at full screen — stays
    // bounded; the upscale is free on the GPU and reads fine for a head-and-
    // chest figure over a softened backdrop.
    if (widget.fillScreen) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null)
            _DownscaledWebView(
              controller: _controller!,
              scale: _fullRenderScale,
            ),
          if (!_ready) Center(child: fallback),
        ],
      );
    }

    final accent = widget.backdrop.accent;
    return Container(
      width: widget.size,
      height: widget.size * 1.18, // a touch taller for head-and-shoulders framing
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.26),
            blurRadius: 32,
            spreadRadius: -10,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      // A rounded, themed "portrait stage": the WebGL scene now paints its own
      // background, so the WebView is opaque (cheaper to composite than a
      // translucent one) and reads as a premium framed window.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller != null) WebViewWidget(controller: _controller!),
            // The proven 2D avatar covers the WebView until the 3D scene paints,
            // so the stage is never empty and the swap is seamless. No Opacity
            // wrapper (it forces an expensive offscreen layer over a platform
            // view) — we just drop the cover once ready.
            if (!_ready) fallback,
          ],
        ),
      ),
    );
  }
}

/// Hosts the [WebViewWidget] at a fraction of the available size and scales it
/// back up to fill, so the platform view's surface (and the texture Android
/// copies every frame) is smaller than the screen. The 3D scene keeps the right
/// aspect ratio because the reduced box is the same shape as the full one.
class _DownscaledWebView extends StatelessWidget {
  const _DownscaledWebView({required this.controller, required this.scale});

  final WebViewController controller;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: w * scale,
              height: h * scale,
              child: WebViewWidget(controller: controller),
            ),
          ),
        );
      },
    );
  }
}
