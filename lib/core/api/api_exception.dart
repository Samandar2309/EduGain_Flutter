/// A typed error matching the backend's canonical envelope
/// `{"error": {"code", "message", "details"}}`. `code` comes from the shared
/// error catalog (e.g. OTP_INVALID, QUOTA_EXCEEDED, PAYWALL).
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.details = const {},
    this.statusCode,
  });

  final String code;
  final String message;
  final Map<String, dynamic> details;
  final int? statusCode;

  /// Paywall payload, when the backend attached one to a 402 (see $Paywall).
  Map<String, dynamic>? get paywall =>
      details['paywall'] as Map<String, dynamic>?;

  factory ApiException.network() => const ApiException(
    code: 'NETWORK_ERROR',
    message: 'Internetga ulanishda xatolik. Qaytadan urinib ko\'ring.',
  );

  @override
  String toString() => 'ApiException($code, $message)';
}
