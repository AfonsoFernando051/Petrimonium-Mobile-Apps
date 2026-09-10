import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// What counts as "no connectivity", and the guarantee that a raw
/// `Exception: ...` never reaches a user, must not depend on which product
/// caught the error — this used to be a copy of the same heuristic in each app.
void main() {
  group('friendlyErrorCopy', () {
    test('a SocketException is the connectivity message', () {
      final copy = friendlyErrorCopy(const SocketException('boom'));
      expect(copy.key, SharedStrings.errorNoConnectionMessage);
      expect(copy.text, isNull);
    });

    test('an error whose text mentions a network failure is the connectivity message', () {
      for (final message in ['SocketException: failed', 'Connection refused', 'network unreachable']) {
        expect(friendlyErrorCopy(Exception(message)).key, SharedStrings.errorNoConnectionMessage, reason: message);
      }
    });

    test('the match is case-insensitive', () {
      expect(friendlyErrorCopy(Exception('NETWORK is down')).key, SharedStrings.errorNoConnectionMessage);
    });

    test('any other message is passed through with the Exception prefix stripped', () {
      final copy = friendlyErrorCopy(Exception('E-mail já cadastrado'));
      expect(copy.key, isNull);
      expect(copy.text, 'E-mail já cadastrado');
    });

    test('an error with nothing left to show falls back to the generic message', () {
      final copy = friendlyErrorCopy(Exception(''));
      expect(copy.key, SharedStrings.errorUnexpectedMessage);
      expect(copy.text, isNull);
    });

    test('exactly one of key and text is ever set', () {
      final errors = <Object>[
        const SocketException('x'),
        Exception('connection lost'),
        Exception('anything else'),
        Exception(''),
      ];
      for (final e in errors) {
        final copy = friendlyErrorCopy(e);
        expect((copy.key == null) != (copy.text == null), isTrue, reason: '$e');
      }
    });
  });
}
