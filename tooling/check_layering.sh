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

# Empty, and meant to stay that way. `PendingPortfolioStatsBuilder` used to be
# the one entry here — it read `AssetRegistrationModel`, a data model, because
# no domain-side type for a not-yet-saved registration existed — but it was
# deleted with `InvestmentConfigurationScreen`, its only caller, rather than
# given the domain type/mapper that would have fixed the layering violation
# properly.
#
# Known blind spot, recorded rather than papered over: this rule matches the
# *path* `features/*/data/`, so a data model that moves into a shared package
# stops tripping it. That is what happened to the four Academy domain services
# that used to be on this list — they still read `AcademyCatalogSnapshot`, a
# wire-shaped model, but it now lives in `petrimonium_shared_features` and the
# import no longer matches. Splitting the snapshot into a domain catalog type
# plus a mapper is what would actually fix that; the entries were dropped
# because leaving them would fail the not-stale check below and read as if the
# problem were solved.
ALLOW_DOMAIN_TO_DATA=()

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

# An allowlist is only honest while every entry still names a real violation.
# Checking mere existence is not enough: a file that was fixed, or whose
# offending import moved elsewhere, would sit here forever reading as
# outstanding debt and quietly covering any future violation in that same file.
echo "==> Allowlists are not stale"
for entry in "${ALLOW_MATERIAL[@]}"; do
  if [ ! -f "$entry" ]; then
    echo "ERROR: allowlisted path no longer exists: $entry" >&2
    status=1
  elif ! grep -qE "^import 'package:flutter/(material|widgets|cupertino)\.dart';" "$entry"; then
    echo "ERROR: $entry is allowlisted for importing a widget library but no longer does." >&2
    echo "       Delete the entry — the debt is paid." >&2
    status=1
  fi
done
for entry in "${ALLOW_DOMAIN_TO_DATA[@]}"; do
  if [ ! -f "$entry" ]; then
    echo "ERROR: allowlisted path no longer exists: $entry" >&2
    status=1
  elif ! grep -qE "^import 'package:petrimonium_(academy|wallet|health)/features/[a-z_]+/data/" "$entry"; then
    echo "ERROR: $entry is allowlisted for importing the data layer but no longer does." >&2
    echo "       Delete the entry — the debt is paid." >&2
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
