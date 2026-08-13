import 'dart:js_interop';

@JS('navigator')
external _JSNavigator? get _navigator;

extension type _JSNavigator._(JSObject _) implements JSObject {
  external _JSPermissions? get permissions;
}

extension type _JSPermissions._(JSObject _) implements JSObject {
  external JSPromise<_JSPermissionStatus> query(
    _JSPermissionDescriptor descriptor,
  );
}

/// `{name: 'microphone'}`, built as a typed object literal.
///
/// Not `jsify()`: that returns `JSAny?`, and narrowing it back to `JSObject`
/// is a runtime check between two interop types that the analyzer rightly
/// flags as not platform-consistent. A literal constructor needs no check.
extension type _JSPermissionDescriptor._(JSObject _) implements JSObject {
  external factory _JSPermissionDescriptor({String name});
}

extension type _JSPermissionStatus._(JSObject _) implements JSObject {
  external String? get state;
}

/// Browser microphone permission state, via the Permissions API.
///
/// `navigator.permissions.query({name: 'microphone'})` is the only way to learn
/// the stored decision WITHOUT prompting — which is the whole point: a learner
/// who already allowed the microphone must not meet a second dialog.
///
/// It is deliberately treated as optional. Safari has historically not
/// supported the `microphone` descriptor and rejects the query, and Telegram's
/// WebViews inherit whatever their platform engine does. Every failure path
/// answers 'unsupported', which the caller reads as "ask and find out" — the
/// behaviour we would have had anyway, never a blocked call.
class MicPermissionPlatform {
  const MicPermissionPlatform._();

  /// 'granted' | 'prompt' | 'denied' | 'unsupported'
  static Future<String> query() async {
    try {
      final permissions = _navigator?.permissions;
      if (permissions == null) return 'unsupported';
      final status = await permissions
          .query(_JSPermissionDescriptor(name: 'microphone'))
          .toDart;
      return switch (status.state) {
        'granted' => 'granted',
        'denied' => 'denied',
        'prompt' => 'prompt',
        // A state the spec does not define, or none at all. Not an error, and
        // not a reason to refuse: ask and find out.
        _ => 'unsupported',
      };
    } catch (_) {
      // Safari rejects the `microphone` descriptor outright with a TypeError,
      // and some WebViews have no Permissions API at all. Both are ordinary.
      return 'unsupported';
    }
  }
}
