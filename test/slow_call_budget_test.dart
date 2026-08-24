import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:edugain/core/api/api_client.dart';
import 'package:edugain/core/api/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Waiting for an endpoint that has to think first.
///
/// The default fifteen seconds is a budget for getting a reply *started*. On
/// the web it is effectively the whole-request budget too: `dio_web_adapter`
/// arms its connect timer and only stands it down once response HEADERS
/// arrive — and an endpoint that computes before it responds sends no headers
/// until it has finished.
///
/// Ending a session is exactly that endpoint. Measured in production: nginx
/// logged `POST .../end 499 rt 15.060` twice, the learner was told to check
/// their internet, and the report they were owed was written and stored one
/// second later with nobody there to receive it.
class _FakeTokens implements TokenStorage {
  @override
  Future<String?> readAccess() async => 'token';
  @override
  Future<String?> readRefresh() async => null;
  @override
  Future<void> save({required String access, required String refresh}) async {}
  @override
  Future<void> clear() async {}
}

/// Answers nothing; it only records what the request was allowed to take.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? seen;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen = options;
    return ResponseBody.fromString('{"data":{}}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _CapturingAdapter adapter;
  late ApiClient api;

  setUp(() {
    dio = Dio();
    adapter = _CapturingAdapter();
    dio.httpClientAdapter = adapter;
    api = ApiClient(tokens: _FakeTokens(), dio: dio);
  });

  test('an ordinary call keeps the short connection budget', () async {
    await api.post('/speaking/sessions');
    expect(adapter.seen!.connectTimeout, const Duration(seconds: 15));
  });

  test('a slow call is given room to think', () async {
    await api.post('/speaking/sessions/abc/end', slow: true);
    final budget = adapter.seen!.connectTimeout!;
    expect(
      budget.inSeconds,
      greaterThan(20),
      reason: 'grading took 15.9s in production against a 15s ceiling',
    );
    // Both halves: the web adapter uses their sum as the hard XHR timeout and
    // the connect half as the "have headers arrived yet" deadline. Raising
    // only one leaves the other to cut the request off exactly as before.
    expect(adapter.seen!.receiveTimeout, budget);
  });

  test('one slow call does not stretch the next ordinary one', () async {
    await api.post('/speaking/sessions/abc/end', slow: true);
    await api.post('/speaking/sessions');
    expect(
      adapter.seen!.connectTimeout,
      const Duration(seconds: 15),
      reason: 'a dead connection would now hang for a minute and a half',
    );
  });
}
