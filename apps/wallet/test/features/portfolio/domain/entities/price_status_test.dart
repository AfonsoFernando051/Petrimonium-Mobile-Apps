import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/features/investment/data/models/investment_type_enum.dart';
import 'package:petrimonium/features/portfolio/domain/entities/holding.dart';
import 'package:petrimonium/features/portfolio/domain/entities/investment_lot.dart';
import 'package:petrimonium/features/portfolio/domain/entities/price_status.dart';

InvestmentLot _lot({
  required double purchasePrice,
  required double currentPrice,
  PriceStatus status = PriceStatus.live,
  String ticker = 'PETR4',
  InvestmentTypeEnum type = InvestmentTypeEnum.STOCKS,
}) {
  const quantity = 10.0;
  return InvestmentLot(
    id: 1,
    ticker: ticker,
    type: type,
    quantity: quantity,
    purchasePrice: purchasePrice,
    purchaseDate: DateTime(2026, 1, 1),
    currentPrice: currentPrice,
    investedValue: quantity * purchasePrice,
    currentValue: quantity * currentPrice,
    priceStatus: status,
  );
}

void main() {
  group('PriceStatus.fromWire', () {
    test('parses the backend enum values', () {
      expect(PriceStatus.fromWire('LIVE'), PriceStatus.live);
      expect(PriceStatus.fromWire('STALE_PURCHASE_PRICE'), PriceStatus.stalePurchasePrice);
      expect(PriceStatus.fromWire('NOT_QUOTED'), PriceStatus.notQuoted);
    });

    test('treats a missing or unknown value as stale, never as live', () {
      // A client that can't tell where a price came from must not present it
      // as a confirmed one — defaulting to `live` would reintroduce the bug.
      expect(PriceStatus.fromWire(null), PriceStatus.stalePurchasePrice);
      expect(PriceStatus.fromWire('SOMETHING_NEW'), PriceStatus.stalePurchasePrice);
    });
  });

  group('InvestmentLot.fromJson', () {
    test('reads priceStatus off the wire', () {
      final lot = InvestmentLot.fromJson({
        'id': 1,
        'name': 'PETR4',
        'type': 'STOCKS',
        'quantity': 10,
        'purchasePrice': 30.0,
        'purchaseDate': '2026-01-01',
        'currentPrice': 30.0,
        'investedValue': 300.0,
        'currentValue': 300.0,
        'priceStatus': 'STALE_PURCHASE_PRICE',
      });

      expect(lot.priceStatus, PriceStatus.stalePurchasePrice);
    });

    test('a payload without priceStatus is treated as stale', () {
      final lot = InvestmentLot.fromJson({
        'id': 1,
        'name': 'PETR4',
        'type': 'STOCKS',
        'quantity': 10,
        'purchasePrice': 30.0,
        'purchaseDate': '2026-01-01',
        'currentPrice': 30.0,
        'investedValue': 300.0,
        'currentValue': 300.0,
      });

      expect(lot.priceStatus, PriceStatus.stalePurchasePrice);
      expect(lot.gainPercent, 0.0, reason: 'the 0% that must not be shown as a real return');
    });
  });

  group('Holding price provenance', () {
    test('a holding priced from a real quote is live', () {
      final holding = Holding.fromLots([_lot(purchasePrice: 30.0, currentPrice: 35.0)]).single;

      expect(holding.priceStatus, PriceStatus.live);
      expect(holding.hasLiveQuote, isTrue);
      expect(holding.gainPercent, closeTo(16.67, 0.01));
    });

    /// The regression: a stale price makes currentValue == investedValue, so
    /// gainPercent is a flat 0% that reads exactly like "hasn't moved".
    test('a stale fallback price yields 0% but is not reported as live', () {
      final holding = Holding.fromLots([
        _lot(purchasePrice: 30.0, currentPrice: 30.0, status: PriceStatus.stalePurchasePrice),
      ]).single;

      expect(holding.gainPercent, 0.0);
      expect(holding.hasLiveQuote, isFalse);
      expect(holding.priceStatus, PriceStatus.stalePurchasePrice);
    });

    test('fixed income is notQuoted rather than stale', () {
      final holding = Holding.fromLots([
        _lot(
          purchasePrice: 100.0,
          currentPrice: 100.0,
          status: PriceStatus.notQuoted,
          ticker: 'TESOURO',
          type: InvestmentTypeEnum.FIXED_INCOME,
        ),
      ]).single;

      expect(holding.priceStatus, PriceStatus.notQuoted);
      expect(holding.hasLiveQuote, isFalse);
    });

    test('the least-trustworthy lot decides the holding: one stale lot makes it stale', () {
      final holding = Holding.fromLots([
        _lot(purchasePrice: 30.0, currentPrice: 35.0),
        _lot(purchasePrice: 31.0, currentPrice: 31.0, status: PriceStatus.stalePurchasePrice),
      ]).single;

      expect(holding.priceStatus, PriceStatus.stalePurchasePrice);
      expect(holding.hasLiveQuote, isFalse);
    });
  });
}
