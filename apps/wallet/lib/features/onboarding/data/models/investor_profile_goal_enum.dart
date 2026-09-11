/// The user's main financial-life objective — one of the three signals the
/// investor-profile step asks for (see `InvestorProfileScreen`). Deliberately
/// a distinct type from `features/pet/data/models/pet_goal_enum.dart`'s
/// `PetGoalEnum`: that one drives Mentor personalization with its own,
/// differently-scoped options and predates this feature — the two are not
/// interchangeable. Values and `wireValue` mirror the backend's
/// `FinancialGoal` enum (and Academy's own `PetGoalEnum`, which asks the same
/// investor-profile question) one-to-one.
enum InvestorProfileGoalEnum { emergencyFund, getOutOfDebt, buyImportantThing, investWithConfidence, justWantToLearn }

extension InvestorProfileGoalEnumDisplay on InvestorProfileGoalEnum {
  String get label => switch (this) {
    InvestorProfileGoalEnum.emergencyFund => 'Reserva de emergência',
    InvestorProfileGoalEnum.getOutOfDebt => 'Sair das dívidas',
    InvestorProfileGoalEnum.buyImportantThing => 'Comprar algo importante',
    InvestorProfileGoalEnum.investWithConfidence => 'Investir com mais confiança',
    InvestorProfileGoalEnum.justWantToLearn => 'Entender melhor meus investimentos',
  };

  /// The backend's `FinancialGoal` enum constant this maps to — see
  /// `core/domain/assessment/FinancialGoal.java`.
  String get wireValue => switch (this) {
    InvestorProfileGoalEnum.emergencyFund => 'EMERGENCY_FUND',
    InvestorProfileGoalEnum.getOutOfDebt => 'GET_OUT_OF_DEBT',
    InvestorProfileGoalEnum.buyImportantThing => 'BUY_IMPORTANT_THING',
    InvestorProfileGoalEnum.investWithConfidence => 'INVEST_WITH_CONFIDENCE',
    InvestorProfileGoalEnum.justWantToLearn => 'JUST_WANT_TO_LEARN',
  };
}
