/// Species offered by the Pet creation screen. Values mirror the shared
/// backend's `PetSpecieEnum` (DOG, CAT, WOLF, FOX, BEAR, LION, OWL) and the
/// declaration order here is the order the picker shows them in — the one in
/// the design canvas's `PetHealth` artboard, shared by all three apps.
///
/// All seven are offered. The account is shared across Wallet, Academy and
/// Health, so a catalog that were narrower here would leave a Pet created in
/// another app unrepresentable in this one.
enum PetSpecies {
  fox('FOX', 'assets/pets/fox.png'),
  dog('DOG', 'assets/pets/dog.png'),
  cat('CAT', 'assets/pets/cat.png'),
  owl('OWL', 'assets/pets/owl.png'),
  wolf('WOLF', 'assets/pets/wolf.png'),
  bear('BEAR', 'assets/pets/bear.png'),
  lion('LION', 'assets/pets/lion.png');

  const PetSpecies(this.apiValue, this.assetPath);

  /// Value accepted by `POST /api/pets/configure` (`PetSpecieEnum`).
  final String apiValue;
  final String assetPath;

  static PetSpecies? fromApiValue(String? value) {
    if (value == null) return null;
    for (final species in values) {
      if (species.apiValue == value.toUpperCase()) return species;
    }
    return null;
  }
}
