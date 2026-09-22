import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';

/// How long the user expects to keep investing before needing the money
/// back, chosen during onboarding's "Para quando é esse objetivo?" step.
/// Matches the Notion mockup's 4 concrete options exactly (a "not sure yet"
/// option, not just three abstract terms).
enum InvestmentHorizonEnum { upToOneYear, oneToFiveYears, moreThanFiveYears, notSureYet }

extension InvestmentHorizonEnumDisplay on InvestmentHorizonEnum {
  String get label => switch (this) {
    InvestmentHorizonEnum.upToOneYear => Translator.translate(AppStrings.investmentHorizonUpToOneYear),
    InvestmentHorizonEnum.oneToFiveYears => Translator.translate(AppStrings.investmentHorizonOneToFiveYears),
    InvestmentHorizonEnum.moreThanFiveYears => Translator.translate(AppStrings.investmentHorizonMoreThanFiveYears),
    InvestmentHorizonEnum.notSureYet => Translator.translate(AppStrings.investmentHorizonNotSureYet),
  };

  static InvestmentHorizonEnum fromName(String? name) {
    return InvestmentHorizonEnum.values.firstWhere(
      (h) => h.name == name,
      orElse: () => InvestmentHorizonEnum.oneToFiveYears,
    );
  }
}
