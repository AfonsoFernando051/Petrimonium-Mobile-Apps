import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';

/// The user's self-reported investing experience, chosen during onboarding's
/// "Como está sua experiência hoje?" step — lets the Academy skip content
/// the user already knows instead of a one-size-fits-all track. Matches the
/// Notion mockup's 3 options exactly.
enum ExperienceLevelEnum { novice, curious, practitioner }

extension ExperienceLevelEnumDisplay on ExperienceLevelEnum {
  String get label => switch (this) {
    ExperienceLevelEnum.novice => Translator.translate(AppStrings.experienceLevelNoviceLabel),
    ExperienceLevelEnum.curious => Translator.translate(AppStrings.experienceLevelCuriousLabel),
    ExperienceLevelEnum.practitioner => Translator.translate(AppStrings.experienceLevelPractitionerLabel),
  };

  String get description => switch (this) {
    ExperienceLevelEnum.novice => Translator.translate(AppStrings.experienceLevelNoviceDescription),
    ExperienceLevelEnum.curious => Translator.translate(AppStrings.experienceLevelCuriousDescription),
    ExperienceLevelEnum.practitioner => Translator.translate(AppStrings.experienceLevelPractitionerDescription),
  };

  String get emoji => switch (this) {
    ExperienceLevelEnum.novice => '🌱',
    ExperienceLevelEnum.curious => '👀',
    ExperienceLevelEnum.practitioner => '📊',
  };

  static ExperienceLevelEnum fromName(String? name) {
    return ExperienceLevelEnum.values.firstWhere((e) => e.name == name, orElse: () => ExperienceLevelEnum.novice);
  }
}
