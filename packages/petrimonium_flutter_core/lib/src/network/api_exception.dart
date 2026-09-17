import 'dart:convert';
import 'package:http/http.dart' as http;

/// A non-2xx response translated into a typed exception, carrying whatever
/// the backend's `GlobalExceptionHandler` put in its RFC 7807 `ProblemDetail`
/// body instead of just the HTTP status code.
final class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message, this.code});

  final int statusCode;
  final String message;
  final String? code;

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}

/// A 401 that means "the credential you just supplied is wrong", as opposed to "your session
/// expired" — [ApiClient] has already tried to refresh and replayed the request by the time a
/// 401 reaches a caller, so what is left is the credential itself.
///
/// Its own type, not an [ApiException] the caller has to pattern-match on a status code, because
/// it is the one failure in a re-authentication flow the user can fix on the spot: the UI needs
/// to tell "wrong password, try again" apart from "something went wrong".
final class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();

  @override
  String toString() => 'InvalidCredentialsException';
}

/// Decodes a JSON object body, or an empty map for an empty body (e.g. a
/// 204 No Content).
Map<String, dynamic> decodeObject(http.Response response) {
  if (response.body.isEmpty) return <String, dynamic>{};
  return jsonDecode(response.body) as Map<String, dynamic>;
}

/// Decodes a JSON array body of objects, or an empty list for an empty body.
List<Map<String, dynamic>> decodeList(http.Response response) {
  if (response.body.isEmpty) return const [];
  return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
}

/// Throws an [ApiException] built from [response]'s RFC 7807 body — the
/// same `detail`/`message`/`title`/`code` shape [extractErrorDetail] reads —
/// falling back to the raw body or the status code when it isn't that shape.
Never throwApiError(http.Response response) {
  String message = 'HTTP ${response.statusCode}';
  String? code;
  try {
    final body = decodeObject(response);
    message = (body['detail'] ?? body['message'] ?? body['title'] ?? message).toString();
    code = body['code'] as String?;
  } catch (_) {
    if (response.body.isNotEmpty) message = response.body;
  }
  throw ApiException(statusCode: response.statusCode, message: message, code: code);
}
