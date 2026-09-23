import 'package:intl/intl.dart';

import 'translator.dart';

/// Presentation locale never changes the denomination of simulated money.
class AcademyFormatters {
  AcademyFormatters._();

  static String get _locale => switch (Translator.currentLanguage) {
    'en' => 'en_US',
    'es' => 'es_ES',
    'pt_PT' => 'pt_PT',
    _ => 'pt_BR',
  };

  // Academy's portfolio and editable lab scenarios are denominated in BRL.
  // Quotes supply their own ISO currency code explicitly.
  static double rounded(double value, {int decimals = 2}) {
    final result = double.parse(value.toStringAsFixed(decimals));
    return result == 0 ? 0 : result;
  }

  static String currency(double value, {bool showCents = true, String currencyCode = 'BRL'}) {
    value = rounded(value, decimals: showCents ? 2 : 0);
    return NumberFormat.simpleCurrency(
      locale: _locale,
      name: currencyCode,
      decimalDigits: showCents ? 2 : 0,
    ).format(value).replaceAll('\u00a0', ' ');
  }

  static String compactCurrency(double value, {String currencyCode = 'BRL'}) {
    return NumberFormat.compactSimpleCurrency(
      locale: _locale,
      name: currencyCode,
    ).format(value).replaceAll('\u00a0', ' ');
  }

  static String percent(double value, {bool showSign = true}) =>
      '${showSign && rounded(value) > 0 ? '+' : ''}${percentPlain(value, decimals: 2)}';

  static String percentPlain(double value, {int decimals = 1}) =>
      '${NumberFormat.decimalPatternDigits(locale: _locale, decimalDigits: decimals).format(rounded(value, decimals: decimals))}%';

  static String quantity(double value) => NumberFormat.decimalPatternDigits(
    locale: _locale,
    decimalDigits: value == value.truncateToDouble() ? 0 : 2,
  ).format(value);

  /// dd/MM/yyyy in every language. The simulated wallet is denominated and
  /// dated in the Brazilian market's terms (see [currency]'s note on BRL),
  /// and the order form has always shown trade dates this way — a history
  /// row that reordered the fields per locale would disagree with the very
  /// screen that produced it.
  static String date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String multiplier(double value) =>
      '${NumberFormat.decimalPatternDigits(locale: _locale, decimalDigits: 1).format(value)}x';
}
