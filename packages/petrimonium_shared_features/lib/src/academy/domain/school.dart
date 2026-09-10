/// A themed group of [AcademyModule]s (e.g. "Financial Life", "Fixed
/// Income") — the top level of the Academy curriculum. Mirrors
/// [AcademyModule]'s shape exactly: [contentAvailable] distinguishes real,
/// navigable schools from curriculum placeholders shown as "coming soon",
/// and [prerequisites] (school ids) gate a school behind others being
/// completed first. A school with no [prerequisites] is available as soon as
/// it has [contentAvailable] modules — existing schools never gain a new
/// prerequisite that would retroactively lock content a user can already
/// reach today.
class School {
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
  final List<String> prerequisites;
  final bool contentAvailable;

  const School({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.order,
    this.prerequisites = const [],
    this.contentAvailable = false,
  });
}
