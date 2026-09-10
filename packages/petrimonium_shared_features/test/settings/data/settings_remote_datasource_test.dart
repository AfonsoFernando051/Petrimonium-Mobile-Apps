import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late SettingsRemoteDataSource dataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = SettingsRemoteDataSource(apiClient: mockApiClient);
  });

  group('getLanguage', () {
    test('returns the language from the decoded body on 200', () async {
      when(() => mockApiClient.get(any())).thenAnswer((_) async => http.Response(jsonEncode({'language': 'en'}), 200));

      final result = await dataSource.getLanguage();

      expect(result, 'en');
      verify(() => mockApiClient.get(SettingsRemoteDataSource.languageEndpoint)).called(1);
    });

    test('throws an Exception on a non-200 response', () async {
      when(() => mockApiClient.get(any())).thenAnswer((_) async => http.Response('', 401));

      await expectLater(
        () => dataSource.getLanguage(),
        throwsA(predicate((e) => e is Exception && e.toString().contains('401'))),
      );
    });
  });

  group('updateLanguage', () {
    test('puts the new language and returns the confirmed value on 200', () async {
      when(
        () => mockApiClient.put(any(), any()),
      ).thenAnswer((_) async => http.Response(jsonEncode({'language': 'es'}), 200));

      final result = await dataSource.updateLanguage('es');

      expect(result, 'es');
      verify(() => mockApiClient.put(SettingsRemoteDataSource.languageEndpoint, {'language': 'es'})).called(1);
    });

    test('throws an Exception on a non-200 response', () async {
      when(() => mockApiClient.put(any(), any())).thenAnswer((_) async => http.Response('', 400));

      await expectLater(
        () => dataSource.updateLanguage('es'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('400'))),
      );
    });
  });
}
