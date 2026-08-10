import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Thin HTTP layer over Dio. It speaks the backend's canonical envelope
/// (`{data}` / `{error}`), attaches the bearer token, and transparently
/// refreshes it once on a 401 before retrying the original request.
class ApiClient {
  ApiClient({
    required TokenStorage tokens,
    Dio? dio,
  }) : _tokens = tokens,
       _dio = dio ?? Dio(),
       _refreshDio = Dio() {
    _dio.options
      ..baseUrl = AppConfig.apiBaseUrl
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 60); // SSE-ish AI calls
    _refreshDio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final TokenStorage _tokens;
  final Dio _dio;
  final Dio _refreshDio;

  /// Wired by the auth controller; called when a token refresh fails so the
  /// app can route back to login.
  void Function()? onAuthFailure;

  /// The language the learner reads the app in, sent as `Accept-Language` on
  /// every request.
  ///
  /// The server needs it to write feedback and corrections in a language the
  /// learner actually understands — an explanation of an English mistake is
  /// worthless to a beginner if it is itself in English. A header (rather than
  /// a parameter on each endpoint) keeps it out of every call site and means
  /// anything else that becomes language-aware later gets it for free.
  String Function()? languageCode;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final access = await _tokens.readAccess();
    if (access != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    final lang = languageCode?.call();
    if (lang != null && lang.isNotEmpty) {
      options.headers['Accept-Language'] = lang;
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthError = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;
    if (!isAuthError || alreadyRetried) {
      handler.next(err);
      return;
    }
    final refreshed = await _tryRefresh();
    if (!refreshed) {
      await _tokens.clear();
      onAuthFailure?.call();
      handler.next(err);
      return;
    }
    try {
      final req = err.requestOptions;
      req.extra['retried'] = true;
      req.headers['Authorization'] = 'Bearer ${await _tokens.readAccess()}';
      handler.resolve(await _dio.fetch<dynamic>(req));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _tokens.readRefresh();
    if (refresh == null) return false;
    try {
      final resp = await _refreshDio.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final tokens = (resp.data['data'] as Map)['tokens'] as Map;
      await _tokens.save(
        access: tokens['access_token'] as String,
        refresh: tokens['refresh_token'] as String,
      );
      return true;
    } on DioException {
      return false;
    }
  }

  // ── verbs (return the unwrapped `data` payload) ──────────────────────────
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) => _send(
    () => _dio.post<dynamic>(path, data: body, options: Options(headers: headers)),
  );

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<dynamic>(path, data: body));

  /// Open a Server-Sent Events stream (speaking/writing). On a non-200
  /// pre-check (402 paywall, 404, ...) the JSON body is read and thrown as an
  /// [ApiException] — the stream never starts (REQ-23-006).
  Future<Stream<List<int>>> postStream(String path, {Object? body}) async {
    final Response<ResponseBody> resp;
    try {
      resp = await _dio.post<ResponseBody>(
        path,
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    }
    if (resp.statusCode == 200) return resp.data!.stream;
    return _throwStreamError(resp);
  }

  /// Upload a file and read a plain JSON reply.
  ///
  /// Separate from [postMultipartStream], which expects SSE back: a profile
  /// picture is one request and one answer, and borrowing a streaming path for
  /// it would mean parsing an event stream that carries a single event.
  Future<Map<String, dynamic>> putMultipart(
    String path, {
    required Uint8List bytes,
    required String filename,
    String field = 'photo',
  }) async {
    // `fromBytes`, not `fromFile`: dio's web adapter has no filesystem to read
    // a path from, and this app's main platform is the browser.
    final form = FormData.fromMap({
      field: MultipartFile.fromBytes(bytes, filename: filename),
    });
    // Through `_send` like every other call, so the 401-refresh-and-retry
    // interceptor and the error envelope behave identically here.
    return _send(() => _dio.put<dynamic>(path, data: form));
  }

  /// Like [postStream] but uploads a file as multipart form-data (audio
  /// Speaking). The reply still streams back as SSE; pre-stream errors (422
  /// empty/silent audio, 402 paywall, ...) arrive as JSON and are thrown.
  Future<Stream<List<int>>> postMultipartStream(
    String path, {
    required Uint8List bytes,
    required String filename,
    String field = 'audio',
    // Bytes sent / total, while the body uploads. A spoken turn can be a few
    // megabytes on a slow mobile connection, and silence there reads as a
    // frozen app.
    void Function(int sent, int total)? onProgress,
  }) async {
    // `fromBytes` (not `fromFile`) so this works identically on native and
    // web — dio's web adapter has no filesystem to read a path from.
    final form = FormData.fromMap({
      field: MultipartFile.fromBytes(bytes, filename: filename),
    });
    final Response<ResponseBody> resp;
    try {
      resp = await _dio.post<ResponseBody>(
        path,
        data: form,
        onSendProgress: onProgress,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    }
    if (resp.statusCode == 200) return resp.data!.stream;
    return _throwStreamError(resp);
  }

  /// Drain a non-200 streamed response body and throw it as an [ApiException].
  Future<Never> _throwStreamError(Response<ResponseBody> resp) async {
    final bytes = await resp.data!.stream.fold<List<int>>(
      <int>[],
      (acc, chunk) => acc..addAll(chunk),
    );
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      decoded = null;
    }
    throw _errorFromBody(decoded, resp.statusCode);
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) =>
      _send(() => _dio.put<dynamic>(path, data: body));

  Future<Map<String, dynamic>> delete(String path) =>
      _send(() => _dio.delete<dynamic>(path));

  /// POST returning a raw binary body (e.g. TTS audio), not the JSON envelope.
  /// Goes through the same Dio (so the 401-refresh-and-retry interceptor still
  /// applies). Error responses surface as [ApiException].
  Future<Uint8List> postBytes(String path, {Object? body}) async {
    try {
      final resp = await _dio.post<List<int>>(
        path,
        data: body,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data ?? const <int>[]);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final resp = await call();
      final data = resp.data;
      if (data is Map && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      if (data is Map && data['data'] is List) {
        return {'items': data['data'], 'meta': data['meta']};
      }
      return {};
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['error'] is Map) {
      return _errorFromBody(body, e.response?.statusCode);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException.network();
    }
    return ApiException(
      code: 'UNKNOWN',
      message: e.message ?? 'Kutilmagan xatolik',
      statusCode: e.response?.statusCode,
    );
  }

  ApiException _errorFromBody(dynamic body, int? statusCode) {
    if (body is Map && body['error'] is Map) {
      final error = body['error'] as Map;
      return ApiException(
        code: error['code'] as String? ?? 'UNKNOWN',
        message: error['message'] as String? ?? 'Xatolik yuz berdi',
        details: Map<String, dynamic>.from(error['details'] as Map? ?? {}),
        statusCode: statusCode,
      );
    }
    return ApiException(
      code: 'UNKNOWN',
      message: 'Kutilmagan xatolik',
      statusCode: statusCode,
    );
  }
}
