/// A themed group of [School]s (e.g. "Investimentos" grouping "Renda Fixa",
/// "Ações e Renda Variável", "Fundos, ETFs e FIIs", ...) — the top level of
/// the Academy catalog, one step above [School]. Purely a client-side
/// navigation/grouping concept (see `docs/DECISIONS.md` DECISION-019): it
/// does not own lessons or progress itself, only groups existing schools by
/// [schoolIds] — status and mastery are always derived from those member
/// schools (`AcademyProgressCalculator.domainStatus`,
/// `KnowledgeProgressCalculator.percentForDomain`), never stored here.
class AcademyDomain {
  final String id;
  final String title;
  final String description;

  /// Registry key for this entry's icon (e.g. `"savings_outlined"`), not the
  /// `IconData` itself. The catalog arrives as JSON carrying this key; only
  /// presentation turns it into a const `Icons.xxx`, through
  /// `AcademyIconRegistry`. Keeping the key here is what lets this layer be
  /// plain Dart with no widget binding.
  final String iconKey;
  final int order;
  final List<String> schoolIds;

  const AcademyDomain({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.order,
    this.schoolIds = const [],
  });
}
