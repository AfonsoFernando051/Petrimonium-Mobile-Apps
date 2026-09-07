// ignore_for_file: constant_identifier_names
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/utils/translator.dart';

// Uppercase values mirror the backend's Java enum wire format (see
// PetApp-Backend PetSpecieEnum) and must match exactly for (de)serialization.
enum PetSpecieEnum {
  DOG,
  CAT,
  WOLF,
  FOX,
  BEAR,
  LION,
  OWL
}

extension PetSpecieEnumExtension on PetSpecieEnum {
  String get name => toString().split('.').last;

  /// Localized display label — for pickers like `PetSetupScreen`'s species
  /// grid, where the wire-format [name] ("DOG") isn't user-facing copy.
  String get displayLabel {
    switch (this) {
      case PetSpecieEnum.DOG:
        return Translator.translate(AppStrings.petSpecieDog);
      case PetSpecieEnum.CAT:
        return Translator.translate(AppStrings.petSpecieCat);
      case PetSpecieEnum.WOLF:
        return Translator.translate(AppStrings.petSpecieWolf);
      case PetSpecieEnum.FOX:
        return Translator.translate(AppStrings.petSpecieFox);
      case PetSpecieEnum.BEAR:
        return Translator.translate(AppStrings.petSpecieBear);
      case PetSpecieEnum.LION:
        return Translator.translate(AppStrings.petSpecieLion);
      case PetSpecieEnum.OWL:
        return Translator.translate(AppStrings.petSpecieOwl);
    }
  }
}
