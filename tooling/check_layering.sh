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

# Empty, and meant to stay that way. The Academy catalog entities used to hold
# a const IconData resolved at parse time; they hold the icon *key* now and
# only presentation resolves it, so no domain file needs a widget library.
ALLOW_MATERIAL=()

# These domain services read `AcademyCatalogSnapshot`, a data model, because
# no domain-side catalog type exists yet — the snapshot is both the wire shape
# and the in-memory catalog. Wallet's `PendingPortfolioStatsBuilder` reads
# `AssetRegistrationModel` for the same reason. Splitting either into a domain
# type plus a mapper is the remaining work here.
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
  if [ "${#ALLOW_MATERIAL[@]}" -eq 0 ] && [ "${#ALLOW_DOMAIN_TO_DATA[@]}" -eq 0 ]; then
    echo "OK: layering is intact, with nothing allowlisted."
  else
    echo "OK: layering is intact (${#ALLOW_MATERIAL[@]} widget-library + ${#ALLOW_DOMAIN_TO_DATA[@]} domain->data allowlisted, see the file header)."
  fi
fi
exit "$status"
