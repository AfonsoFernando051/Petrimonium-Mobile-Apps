import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/features/portfolio/domain/entities/dividend_event.dart';

void main() {
  group('DividendEvent.fromJson', () {
    test('parses all fields from a full response', () {
      final event = DividendEvent.fromJson(const {
        'ticker': 'PETR4',
        'type': 'JCP',
        'rawLabel': 'Juros sobre capital próprio',
        'ratePerShare': 0.5,
        'dataCom': '2026-01-10',
        'paymentDate': '2026-01-20',
        'approvedOn': '2026-01-01',
        'userQuantity': 100.0,
        'estimatedGrossAmount': 50.0,
        'status': 'PAID',
      });

      expect(event.ticker, 'PETR4');
      expect(event.type, DividendType.JCP);
      expect(event.rawLabel, 'Juros sobre capital próprio');
      expect(event.ratePerShare, 0.5);
      expect(event.dataCom, DateTime.parse('2026-01-10'));
      expect(event.paymentDate, DateTime.parse('2026-01-20'));
      expect(event.approvedOn, DateTime.parse('2026-01-01'));
      expect(event.userQuantity, 100.0);
      expect(event.estimatedGrossAmount, 50.0);
      expect(event.status, DividendStatus.PAID);
    });

    test('unrecognized type falls back to OUTRO', () {
      final event = DividendEvent.fromJson(const {
        'ticker': 'PETR4',
        'type': 'SOMETHING_NEW',
        'userQuantity': 1.0,
        'estimatedGrossAmount': 1.0,
        'status': 'ANNOUNCED',
      });

      expect(event.type, DividendType.OUTRO);
    });

    test('null type falls back to OUTRO', () {
      final event = DividendEvent.fromJson(const {
        'ticker': 'PETR4',
        'userQuantity': 1.0,
        'estimatedGrossAmount': 1.0,
        'status': 'ANNOUNCED',
      });

      expect(event.type, DividendType.OUTRO);
    });

    test('status defaults to ANNOUNCED for anything other than PAID', () {
      final event = DividendEvent.fromJson(const {
        'ticker': 'PETR4',
        'type': 'DIVIDENDO',
        'userQuantity': 1.0,
        'estimatedGrossAmount': 1.0,
        'status': 'ANNOUNCED',
      });
      expect(event.status, DividendStatus.ANNOUNCED);

      final missingStatus = DividendEvent.fromJson(const {
        'ticker': 'PETR4',
        'type': 'DIVIDENDO',
        'userQuantity': 1.0,
        'estimatedGrossAmount': 1.0,
      });
      expect(missingStatus.status, DividendStatus.ANNOUNCED);
    });

    test('null/empty date strings parse to null rather than throwing', () {
      final event = DividendEvent.fromJson(const {
        'ticker': 'PETR4',
        'type': 'DIVIDENDO',
        'dataCom': '',
        'paymentDate': null,
        'userQuantity': 1.0,
        'estimatedGrossAmount': 1.0,
        'status': 'ANNOUNCED',
      });

      expect(event.dataCom, isNull);
      expect(event.paymentDate, isNull);
      expect(event.approvedOn, isNull);
    });

    test('missing numeric/label fields fall back to safe defaults', () {
      final event = DividendEvent.fromJson(const {'ticker': 'PETR4'});

      expect(event.rawLabel, '');
      expect(event.ratePerShare, 0.0);
      expect(event.userQuantity, 0.0);
      expect(event.estimatedGrossAmount, 0.0);
      expect(event.status, DividendStatus.ANNOUNCED);
    });
  });

  group('DividendRadar', () {
    test('isEmpty is true only when both lists are empty', () {
      expect(DividendRadar.empty.isEmpty, isTrue);
      expect(const DividendRadar(upcoming: [], history: []).isEmpty, isTrue);
    });

    test('nextPayment returns the first upcoming entry, or null when empty', () {
      expect(DividendRadar.empty.nextPayment, isNull);

      final event = DividendEvent.fromJson(const {
        'ticker': 'PETR4',
        'type': 'DIVIDENDO',
        'userQuantity': 1.0,
        'estimatedGrossAmount': 1.0,
        'status': 'ANNOUNCED',
      });
      final radar = DividendRadar(upcoming: [event], history: const []);
      expect(radar.nextPayment, event);
      expect(radar.isEmpty, isFalse);
    });

    test('fromJson parses both upcoming and history lists', () {
      final radar = DividendRadar.fromJson({
        'upcoming': [
          {
            'ticker': 'PETR4',
            'type': 'DIVIDENDO',
            'userQuantity': 1.0,
            'estimatedGrossAmount': 1.0,
            'status': 'ANNOUNCED',
          },
        ],
        'history': [
          {
            'ticker': 'VALE3',
            'type': 'JCP',
            'userQuantity': 2.0,
            'estimatedGrossAmount': 2.0,
            'status': 'PAID',
          },
        ],
      });

      expect(radar.upcoming, hasLength(1));
      expect(radar.history, hasLength(1));
      expect(radar.upcoming.first.ticker, 'PETR4');
      expect(radar.history.first.ticker, 'VALE3');
    });

    test('fromJson with missing lists yields empty lists', () {
      final radar = DividendRadar.fromJson(const {});
      expect(radar.upcoming, isEmpty);
      expect(radar.history, isEmpty);
    });

    group('receivedInLast12Months', () {
      final now = DateTime(2026, 9, 1);

      DividendEvent paidOn(DateTime date, double amount) => DividendEvent(
            ticker: 'PETR4',
            type: DividendType.DIVIDENDO,
            rawLabel: '',
            ratePerShare: 1,
            dataCom: null,
            paymentDate: date,
            approvedOn: null,
            userQuantity: 100,
            estimatedGrossAmount: amount,
            status: DividendStatus.PAID,
          );

      test('sums only history events within the trailing 12 months', () {
        final radar = DividendRadar(
          upcoming: const [],
          history: [
            paidOn(DateTime(2026, 8, 15), 100), // within window
            paidOn(DateTime(2025, 10, 1), 50), // within window (12 months back)
            paidOn(DateTime(2025, 8, 1), 30), // just outside the window
          ],
        );

        expect(radar.receivedInLast12Months(now: now), 150);
      });

      test('ignores upcoming (not-yet-paid) events entirely', () {
        final radar = DividendRadar(
          upcoming: [paidOn(DateTime(2026, 8, 15), 999)],
          history: const [],
        );

        expect(radar.receivedInLast12Months(now: now), 0);
      });

      test('skips history events with no usable date', () {
        final undated = DividendEvent(
          ticker: 'PETR4',
          type: DividendType.DIVIDENDO,
          rawLabel: '',
          ratePerShare: 1,
          dataCom: null,
          paymentDate: null,
          approvedOn: null,
          userQuantity: 100,
          estimatedGrossAmount: 500,
          status: DividendStatus.PAID,
        );
        final radar = DividendRadar(upcoming: const [], history: [undated]);

        expect(radar.receivedInLast12Months(now: now), 0);
      });

      test('returns 0 for an empty radar', () {
        expect(DividendRadar.empty.receivedInLast12Months(now: now), 0);
      });
    });

    group('receivedInLastDays', () {
      final now = DateTime(2026, 9, 1);

      DividendEvent paidOn(DateTime date, double amount) => DividendEvent(
            ticker: 'PETR4',
            type: DividendType.DIVIDENDO,
            rawLabel: '',
            ratePerShare: 1,
            dataCom: null,
            paymentDate: date,
            approvedOn: null,
            userQuantity: 100,
            estimatedGrossAmount: amount,
            status: DividendStatus.PAID,
          );

      test('sums only history events within the trailing N days', () {
        final radar = DividendRadar(
          upcoming: const [],
          history: [
            paidOn(DateTime(2026, 8, 20), 100), // within the last 30 days
            paidOn(DateTime(2026, 7, 1), 50), // outside the 30-day window
          ],
        );

        expect(radar.receivedInLastDays(30, now: now), 100);
      });

      test('returns 0 for an empty radar', () {
        expect(DividendRadar.empty.receivedInLastDays(30, now: now), 0);
      });
    });
  });
}
