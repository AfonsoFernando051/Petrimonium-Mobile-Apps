import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

// Re-exported so this file stays the single import for "pet species in this
// app": the shared enum plus this app's labels. Call sites did not have to
// learn that the enum moved packages.
export 'package:petrimonium_shared_features/petrimonium_shared_features.dart'
    show PetSpecieEnum, PetSpecieEnumExtension;

import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';

/// The product-copy half of [PetSpecieEnum]. The enum, its wire format and
/// its display order are ecosystem facts and live in
/// `petrimonium_shared_features`; the label is this app's wording, resolved
/// through this app's own string catalog.
extension PetSpecieDisplay on PetSpecieEnum {
  /// Localized display label — for the species picker, where the wire-format
  /// [name] ("DOG") isn't user-facing copy.
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
