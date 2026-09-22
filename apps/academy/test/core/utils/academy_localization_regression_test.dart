import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/utils/academy_formatters.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/portfolio/presentation/models/mission_display_catalog.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/models/investment_type_display.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

void main() {
  tearDown(() => Translator.currentLanguage = 'pt');
  test('visible category and mission copy follows language changes', () {
    Translator.currentLanguage = 'en';
    expect(InvestmentTypeEnum.STOCKS.label, 'Stocks');
    expect(MissionDisplayCatalog.forCode('daily_complete_lesson').title, 'Lesson of the Day');
    Translator.currentLanguage = 'es';
    expect(InvestmentTypeEnum.STOCKS.label, 'Acciones');
    expect(MissionDisplayCatalog.forCode('daily_complete_lesson').title, 'Lección del día');
    Translator.currentLanguage = 'pt';
    expect(InvestmentTypeEnum.STOCKS.label, 'Ações');
  });
  test('financial percentages and quantities follow the presentation locale', () {
    Translator.currentLanguage = 'pt';
    expect(AcademyFormatters.percent(16.67), '+16,67%');
    expect(AcademyFormatters.percent(-16.67), '-16,67%');
    expect(AcademyFormatters.quantity(1.25), '1,25');
    expect(AcademyFormatters.quantity(2), '2');
    Translator.currentLanguage = 'en';
    expect(AcademyFormatters.percent(16.67), '+16.67%');
    expect(AcademyFormatters.quantity(1.25), '1.25');
  });
  test('currency keeps denomination while respecting the selected locale', () {
    Translator.currentLanguage = 'pt';
    expect(AcademyFormatters.currency(1234.56), contains('1.234,56'));
    Translator.currentLanguage = 'en';
    expect(AcademyFormatters.currency(1234.56), contains('1,234.56'));
    expect(AcademyFormatters.currency(1234.56), contains('R\$'));
    expect(AcademyFormatters.currency(1234.56, currencyCode: 'EUR'), contains('€'));
    expect(AcademyFormatters.currency(1234.56, currencyCode: 'EUR'), isNot(contains('R\$')));
    Translator.currentLanguage = 'es';
    expect(AcademyFormatters.currency(-12345.67), contains('12.345,67'));
    Translator.currentLanguage = 'pt_PT';
    expect(AcademyFormatters.currency(1234.56, currencyCode: 'EUR'), contains(',56'));
  });
}
