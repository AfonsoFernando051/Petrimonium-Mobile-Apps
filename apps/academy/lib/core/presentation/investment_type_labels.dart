import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import '../constants/app_strings.dart';
import '../utils/translator.dart';

class InvestmentTypeLabels {
  InvestmentTypeLabels._();
  static String label(InvestmentTypeEnum type) => switch (type) {
    InvestmentTypeEnum.STOCKS => Translator.translate(AppStrings.labInvestmentTypeStocks),
    InvestmentTypeEnum.FIXED_INCOME => Translator.translate(AppStrings.labInvestmentTypeFixedIncome),
    InvestmentTypeEnum.REAL_ESTATE => Translator.translate(AppStrings.labInvestmentTypeRealEstate),
    InvestmentTypeEnum.CRYPTO => Translator.translate(AppStrings.labInvestmentTypeCrypto),
    InvestmentTypeEnum.FUNDS => Translator.translate(AppStrings.labInvestmentTypeFunds),
    InvestmentTypeEnum.OTHERS => Translator.translate(AppStrings.labInvestmentTypeOthers),
  };

  static String shortLabel(InvestmentTypeEnum type) => switch (type) {
    InvestmentTypeEnum.STOCKS => Translator.translate(AppStrings.labInvestmentTypeStocks),
    InvestmentTypeEnum.FIXED_INCOME => Translator.translate(AppStrings.investmentShortFixed),
    InvestmentTypeEnum.REAL_ESTATE => Translator.translate(AppStrings.investmentShortRealEstate),
    InvestmentTypeEnum.CRYPTO => Translator.translate(AppStrings.labInvestmentTypeCrypto),
    InvestmentTypeEnum.FUNDS => 'ETFs',
    InvestmentTypeEnum.OTHERS => Translator.translate(AppStrings.labInvestmentTypeOthers),
  };
}
