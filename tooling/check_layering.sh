#!/usr/bin/env bash
# Enforces the layering rules inside an app:
#
#   1. features/*/domain/ must not import Flutter's widget libraries.
#      A domain layer that needs a widget binding to be instantiated cannot
#      be tested as plain Dart, and an IconData on an entity is how product
#      branding ends up deciding what a business rule can say.
#
#   2. features/*/domain/ must not import features/*/data/.
#      Dependencies point data -> domain, never the other way.
#
# Both rules have a known, enumerated backlog below. The allowlists exist so
# this check can run green today and so the remaining debt is a list someone
# can work through rather than a number in a report. Removing an entry is the
# definition of done; adding one needs a reason in the commit message.
#
# Run locally with `tooling/check_layering.sh`; CI runs the same script.
set -uo pipefail
cd "$(dirname "$0")/.."

# Academy curriculum content arrives as JSON carrying an icon *key*, which
# `AcademyCatalogSnapshot` resolves into a const `IconData` on the entity
# itself. Unwinding that means changing the data model's shape and the seed
# tooling that writes it (tool/generate_academy_seed_json.dart), so it is its
# own change rather than a line in someone else's.
ALLOW_MATERIAL=(
  "apps/academy/lib/features/academy/domain/entities/academy_domain.dart"
  "apps/academy/lib/features/academy/domain/entities/academy_module.dart"
  "apps/academy/lib/features/academy/domain/entities/school.dart"
  "apps/academy/lib/features/academy/domain/services/academy_icon_registry.dart"
  "apps/wallet/lib/features/academy/domain/entities/academy_domain.dart"
  "apps/wallet/lib/features/academy/domain/entities/academy_module.dart"
  "apps/wallet/lib/features/academy/domain/entities/school.dart"
  "apps/wallet/lib/features/academy/domain/services/academy_icon_registry.dart"
)

# Same root cause: these domain services read `AcademyCatalogSnapshot`, a data
# model, because no domain-side catalog type exists yet. Wallet's
# `PendingPortfolioStatsBuilder` reads `AssetRegistrationModel` for the same
# reason.
ALLOW_DOMAIN_TO_DATA=(
  "apps/academy/lib/features/academy/domain/services/academy_recommendation_service.dart"
  "apps/academy/lib/features/academy/domain/services/academy_progress_calculator.dart"
  "apps/academy/lib/features/academy/domain/services/mastery_calculator.dart"
  "apps/academy/lib/features/academy/domain/services/knowledge_progress_calculator.dart"
  "apps/wallet/lib/features/investment/domain/services/pending_portfolio_stats_builder.dart"
)

allowed() {
  local needle="$1"; shift
  local entry
  for entry in "$@"; do [ "$entry" = "$needle" ] && return 0; done
  return 1
}

status=0

echo "==> No domain file may import Flutter's widget libraries"
while IFS= read -r file; do
  [ -z "$file" ] && continue
  if ! allowed "$file" "${ALLOW_MATERIAL[@]}"; then
    echo "ERROR: $file imports a Flutter widget library from the domain layer." >&2
    echo "       Move the IconData/Color to presentation and keep the rule here." >&2
    status=1
  fi
done < <(grep -rl --include='*.dart' -E "^import 'package:flutter/(material|widgets|cupertino)\.dart';" apps/*/lib/features/*/domain 2>/dev/null)

echo "==> No domain file may import the data layer"
while IFS= read -r file; do
  [ -z "$file" ] && continue
  if ! allowed "$file" "${ALLOW_DOMAIN_TO_DATA[@]}"; then
    echo "ERROR: $file imports features/*/data from the domain layer." >&2
    echo "       Dependencies point data -> domain, never the reverse." >&2
    status=1
  fi
done < <(grep -rl --include='*.dart' -E "^import 'package:petrimonium_(academy|wallet|health)/features/[a-z_]+/data/" apps/*/lib/features/*/domain 2>/dev/null)

echo "==> Allowlists are not stale"
for entry in "${ALLOW_MATERIAL[@]}" "${ALLOW_DOMAIN_TO_DATA[@]}"; do
  if [ ! -f "$entry" ]; then
    echo "ERROR: allowlisted path no longer exists: $entry" >&2
    echo "       Delete the entry — a stale allowlist hides real violations." >&2
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "OK: layering is intact (with ${#ALLOW_MATERIAL[@]} + ${#ALLOW_DOMAIN_TO_DATA[@]} allowlisted, see the file header)."
fi
exit "$status"
