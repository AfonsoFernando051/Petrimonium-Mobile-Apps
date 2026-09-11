/// The user's self-reported investing experience — one of the three signals
/// the investor-profile step asks for (see `InvestorProfileScreen`). Values
/// and `wireValue` mirror the backend's `ExperienceLevel` enum (and Academy's
/// own `ExperienceLevelEnum`, which asks the same investor-profile question)
/// one-to-one. Wallet has no pre-existing, differently-scoped enum with this
/// name to collide with (unlike goal/horizon), but kept under this feature's
/// own `InvestorProfile*` naming for consistency with the other two.
enum InvestorProfileExperienceEnum { novice, curious, practitioner }

extension InvestorProfileExperienceEnumDisplay on InvestorProfileExperienceEnum {
  String get label => switch (this) {
    InvestorProfileExperienceEnum.novice => 'Nunca investi',
    InvestorProfileExperienceEnum.curious => 'Já ouvi falar, nunca pratiquei',
    InvestorProfileExperienceEnum.practitioner => 'Já invisto',
  };

  /// The backend's `ExperienceLevel` enum constant this maps to — see
  /// `core/domain/assessment/ExperienceLevel.java`.
  String get wireValue => switch (this) {
    InvestorProfileExperienceEnum.novice => 'NOVICE',
    InvestorProfileExperienceEnum.curious => 'CURIOUS',
    InvestorProfileExperienceEnum.practitioner => 'PRACTITIONER',
  };
}
