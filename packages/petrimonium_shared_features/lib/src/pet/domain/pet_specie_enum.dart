// ignore_for_file: constant_identifier_names

/// The Pet species catalog.
///
/// Uppercase values mirror the backend's Java enum wire format (see
/// Petrimonium-Backend `PetSpecieEnum`) and must match exactly for
/// (de)serialization. That is also why this is shared rather than copied: one
/// account owns one Pet, and all three products read and write it through the
/// same route, so a species the products disagree about is a species one of
/// them cannot render.
///
/// What is deliberately *not* here: the localized label. That is product copy
/// and is bound to each app's own string catalog — see each app's
/// `PetSpecieDisplay` extension. Same split as `LevelTier` (ecosystem
/// boundaries shared, product wording local).
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
  /// ordem do canvas de design, partilhada pelos três apps. Mudar a ordem do
  /// enum quebraria a serialização; esta não.
  static const List<PetSpecieEnum> displayOrder = [
    PetSpecieEnum.FOX,
    PetSpecieEnum.DOG,
    PetSpecieEnum.CAT,
    PetSpecieEnum.OWL,
    PetSpecieEnum.WOLF,
    PetSpecieEnum.BEAR,
    PetSpecieEnum.LION,
  ];
}
