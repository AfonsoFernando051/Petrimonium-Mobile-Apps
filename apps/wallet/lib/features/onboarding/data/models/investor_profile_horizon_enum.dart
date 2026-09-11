/// How long the user expects to keep investing before needing the money
/// back — one of the three signals the investor-profile step asks for (see
/// `InvestorProfileScreen`). Deliberately a distinct type from
/// `features/pet/data/models/investment_horizon_enum.dart`'s
/// `InvestmentHorizonEnum`: that one drives Mentor personalization with its
/// own, differently-scoped options and predates this feature — the two are
/// not interchangeable. Values and `wireValue` mirror the backend's
/// `InvestmentHorizon` enum (and Academy's own `InvestmentHorizonEnum`, which
/// asks the same investor-profile question) one-to-one.
enum InvestorProfileHorizonEnum { upToOneYear, oneToFiveYears, moreThanFiveYears, notSureYet }

extension InvestorProfileHorizonEnumDisplay on InvestorProfileHorizonEnum {
  String get label => switch (this) {
    InvestorProfileHorizonEnum.upToOneYear => 'Até 1 ano',
    InvestorProfileHorizonEnum.oneToFiveYears => '1 a 5 anos',
    InvestorProfileHorizonEnum.moreThanFiveYears => 'Mais de 5 anos',
    InvestorProfileHorizonEnum.notSureYet => 'Ainda não sei',
  };

  /// The backend's `InvestmentHorizon` enum constant this maps to — see
  /// `core/domain/assessment/InvestmentHorizon.java`.
  String get wireValue => switch (this) {
    InvestorProfileHorizonEnum.upToOneYear => 'UP_TO_ONE_YEAR',
    InvestorProfileHorizonEnum.oneToFiveYears => 'ONE_TO_FIVE_YEARS',
    InvestorProfileHorizonEnum.moreThanFiveYears => 'MORE_THAN_FIVE_YEARS',
    InvestorProfileHorizonEnum.notSureYet => 'NOT_SURE_YET',
  };
}
