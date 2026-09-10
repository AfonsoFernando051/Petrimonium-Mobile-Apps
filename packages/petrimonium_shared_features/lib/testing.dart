/// Test-only builders for this package's shared types.
///
/// Separate entrypoint rather than part of the main barrel: nothing in a
/// production build should reach these, and keeping them off
/// `petrimonium_shared_features.dart` makes that explicit at the import
/// site. They live under `lib/` (not `test/`) for the ordinary Dart reason —
/// one package cannot import another package's `test/` directory, and both
/// this package's own tests and the three apps' tests need the same builders
/// to describe a portfolio the same way.
library;

export 'src/portfolio/testing/portfolio_fixtures.dart';
