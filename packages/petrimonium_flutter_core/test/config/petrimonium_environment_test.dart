import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

void main() {
  group('PetrimoniumEnvironment', () {
    test('baseUrl defaults to localhost when API_BASE_URL is not provided', () {
      expect(PetrimoniumEnvironment.baseUrl, 'http://localhost:8081');
    });

    test('assertConfiguredForRelease does not throw in debug/profile test builds', () {
      // kReleaseMode is false when running `flutter test`, so the release-only
      // guard never fires here — this just documents the call is safe to make
      // unconditionally at startup.
      expect(PetrimoniumEnvironment.assertConfiguredForRelease, returnsNormally);
    });

    group('releaseConfigurationError (release-mode guard, exercised directly)', () {
      // kReleaseMode itself is a compile-time constant that is always false
      // under `flutter test`, so the only way to exercise the release-only
      // branches is through this pure seam that takes isRelease explicitly.
      test('is null outside release mode regardless of baseUrl', () {
        expect(
          PetrimoniumEnvironment.releaseConfigurationError(baseUrl: 'http://localhost:8081', isRelease: false),
          isNull,
        );
      });

      test('flags the unconfigured dev default in release mode', () {
        final error = PetrimoniumEnvironment.releaseConfigurationError(
          baseUrl: PetrimoniumEnvironment.devDefaultBaseUrl,
          isRelease: true,
        );

        expect(error, isNotNull);
      });

      test('flags a configured but non-HTTPS baseUrl in release mode', () {
        final error = PetrimoniumEnvironment.releaseConfigurationError(
          baseUrl: 'http://api.example.com',
          isRelease: true,
        );

        expect(error, isNotNull);
        expect(error!.message, contains('https://'));
      });

      test('accepts a configured HTTPS baseUrl in release mode', () {
        final error = PetrimoniumEnvironment.releaseConfigurationError(
          baseUrl: 'https://api.example.com',
          isRelease: true,
        );

        expect(error, isNull);
      });
    });
  });
}
