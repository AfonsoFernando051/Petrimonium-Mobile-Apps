import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_wallet/features/investment/data/datasources/investment_remote_datasource.dart';
import 'package:petrimonium_wallet/features/investment/data/models/asset_registration_model.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/investment/data/repositories/investment_repository.dart';

class MockInvestmentRemoteDataSource extends Mock implements InvestmentRemoteDataSource {}

void main() {
  late MockInvestmentRemoteDataSource mockDataSource;
  late InvestmentRepository repository;

  setUpAll(() {
    registerFallbackValue(<AssetRegistrationModel>[]);
    registerFallbackValue(
      AssetRegistrationModel(
        name: 'FALLBACK',
        quantity: 1,
        purchasePrice: 1,
        purchaseDate: '2024-01-01',
        type: InvestmentTypeEnum.STOCKS,
      ),
    );
  });

  setUp(() {
    mockDataSource = MockInvestmentRemoteDataSource();
    repository = InvestmentRepository(remoteDataSource: mockDataSource);
  });

  group('configureInvestments', () {
    test('forwards the asset list to the data source unchanged', () async {
      final assets = [
        AssetRegistrationModel(
          name: 'PETR4',
          quantity: 10,
          purchasePrice: 20,
          purchaseDate: '2024-01-01',
          type: InvestmentTypeEnum.STOCKS,
        ),
      ];
      when(
        () => mockDataSource.configureInvestments(any(), confirmReplace: any(named: 'confirmReplace')),
      ).thenAnswer((_) async {});

      await repository.configureInvestments(assets);

      verify(() => mockDataSource.configureInvestments(assets, confirmReplace: false)).called(1);
    });

    test('propagates a failure', () async {
      when(
        () => mockDataSource.configureInvestments(any(), confirmReplace: any(named: 'confirmReplace')),
      ).thenThrow(Exception('save failed'));
      expect(() => repository.configureInvestments([]), throwsException);
    });
  });

  group('addInvestment', () {
    final asset = AssetRegistrationModel(
      name: 'PETR4',
      quantity: 10,
      purchasePrice: 20,
      purchaseDate: '2024-01-01',
      type: InvestmentTypeEnum.STOCKS,
    );

    test('forwards the asset to the data source unchanged', () async {
      when(() => mockDataSource.addInvestment(any())).thenAnswer((_) async {});

      await repository.addInvestment(asset);

      verify(() => mockDataSource.addInvestment(asset)).called(1);
    });

    test('propagates a failure', () async {
      when(() => mockDataSource.addInvestment(any())).thenThrow(Exception('save failed'));
      expect(() => repository.addInvestment(asset), throwsException);
    });
  });

  group('fetchQuote', () {
    test('returns null when the data source finds no match', () async {
      when(() => mockDataSource.fetchQuote(any())).thenAnswer((_) async => null);
      expect(await repository.fetchQuote('ZZZZ'), isNull);
    });

    test('returns the raw quote map unchanged', () async {
      when(
        () => mockDataSource.fetchQuote(any()),
      ).thenAnswer((_) async => {'symbol': 'PETR4', 'regularMarketPrice': 30.5});

      final quote = await repository.fetchQuote('PETR4');

      expect(quote?['symbol'], 'PETR4');
    });
  });

  group('searchQuotes', () {
    test('forwards the query and returns the raw results list', () async {
      when(() => mockDataSource.searchQuotes(any())).thenAnswer(
        (_) async => [
          {'symbol': 'PETR4'},
          {'symbol': 'PETR3'},
        ],
      );

      final results = await repository.searchQuotes('PETR');

      expect(results.length, 2);
      verify(() => mockDataSource.searchQuotes('PETR')).called(1);
    });
  });
}
