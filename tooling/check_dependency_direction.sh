#!/usr/bin/env bash
# Enforces the architecture's one non-negotiable rule set:
#
#   1. No shared package may import an application.
#   2. No application may import another application.
#
# Both are cheap to check and catastrophic to lose. If a package imports an
# app, the products stop being independently releasable and the workspace
# collapses back into a single application wearing three names.
#
# Run locally with `tooling/check_dependency_direction.sh`; CI runs the same
# script, so there is one definition of the rule rather than two.
set -uo pipefail
cd "$(dirname "$0")/.."

APPS=(academy wallet health)
status=0

echo "==> No package may import an app"
for app in "${APPS[@]}"; do
  if grep -rn --include='*.dart' "package:petrimonium_${app}/" packages/ 2>/dev/null; then
    echo "ERROR: a package under packages/ imports petrimonium_${app}." >&2
    echo "       Dependencies must only ever point apps -> packages." >&2
    status=1
  fi
done

echo "==> No app may import another app"
for app in "${APPS[@]}"; do
  for other in "${APPS[@]}"; do
    [ "$app" = "$other" ] && continue
    if grep -rn --include='*.dart' "package:petrimonium_${other}/" "apps/${app}" 2>/dev/null; then
      echo "ERROR: apps/${app} imports petrimonium_${other}." >&2
      echo "       Products integrate through the backend and deep links, never each other's Dart." >&2
      status=1
    fi
  done
done

if [ "$status" -eq 0 ]; then
  echo "OK: dependency direction is intact."
fi
exit "$status"
