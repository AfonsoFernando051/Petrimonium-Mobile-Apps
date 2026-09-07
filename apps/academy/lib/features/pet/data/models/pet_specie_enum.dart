// ignore_for_file: constant_identifier_names
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';

// Uppercase values mirror the backend's Java enum wire format (see
// Petrimonium-Backend PetSpecieEnum) and must match exactly for (de)serialization.
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

  /// Ordem em que o seletor apresenta as espécies. Deliberadamente diferente
  /// de [PetSpecieEnum.values], que segue o wire format do backend: esta é a
  /// ordem do canvas de design (artboard `PetAcademy`), partilhada pelos três
  /// apps. Mudar a ordem do enum quebraria a serialização; esta não.
  static const List<PetSpecieEnum> displayOrder = [
    PetSpecieEnum.FOX,
    PetSpecieEnum.DOG,
    PetSpecieEnum.CAT,
    PetSpecieEnum.OWL,
    PetSpecieEnum.WOLF,
    PetSpecieEnum.BEAR,
    PetSpecieEnum.LION,
  ];

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
