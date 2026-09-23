import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

void main() {
  group('decodeObject', () {
    test('decodes a JSON object body', () {
      expect(decodeObject(http.Response('{"a":1}', 200)), {'a': 1});
    });

    // A 204 No Content is a success the callers here still route through decodeObject.
    test('returns an empty map for an empty body', () {
      expect(decodeObject(http.Response('', 204)), isEmpty);
    });
  });

  group('decodeList', () {
    test('decodes a JSON array of objects', () {
      expect(decodeList(http.Response('[{"a":1},{"a":2}]', 200)), [
        {'a': 1},
        {'a': 2},
      ]);
    });

    test('returns an empty list for an empty body', () {
      expect(decodeList(http.Response('', 200)), isEmpty);
    });
  });

  group('throwApiError', () {
    // The shape the backend's GlobalExceptionHandler produces for every handled error.
    test('carries detail and code from an RFC 7807 body', () {
      expect(
        () => throwApiError(
          http.Response('{"detail":"Quantity is out of the supported range","code":"VALIDATION_ERROR"}', 400),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.code, 'code', 'VALIDATION_ERROR')
              .having((e) => e.message, 'message', 'Quantity is out of the supported range'),
        ),
      );
    });

    // 401 and 403 are thrown inside the backend's security filter chain, never by
    // @ControllerAdvice — they only carry this shape because SecurityConfig registers an explicit
    // entry point and access-denied handler. A 401 in particular is what ApiClient turns into a
    // refresh-and-retry, so parsing it like any other error is what keeps that path legible.
    test('parses the security chain 401 the same as any other error', () {
      expect(
        () => throwApiError(
          http.Response('{"detail":"Authentication is required.","code":"UNAUTHENTICATED","status":401}', 401),
        ),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );
    });

    test('falls back through message and title when detail is absent', () {
      expect(
        () => throwApiError(http.Response('{"message":"from message"}', 500)),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'from message')),
      );
      expect(
        () => throwApiError(http.Response('{"title":"from title"}', 500)),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'from title')),
      );
    });

    // A proxy or load balancer in front of the API answers HTML, not ProblemDetail.
    test('falls back to the raw body when it is not JSON', () {
      expect(
        () => throwApiError(http.Response('<html>502 Bad Gateway</html>', 502)),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', '<html>502 Bad Gateway</html>')
              .having((e) => e.code, 'code', isNull),
        ),
      );
    });

    test('falls back to the status code when the body is empty', () {
      expect(
        () => throwApiError(http.Response('', 503)),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'HTTP 503')),
      );
    });

    test('tolerates a JSON body that is not an object', () {
      expect(() => throwApiError(http.Response('[1,2,3]', 400)), throwsA(isA<ApiException>()));
    });
  });
}
