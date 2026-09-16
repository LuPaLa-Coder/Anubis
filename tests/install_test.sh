#!/usr/bin/env bash
# =============================================================================
#  Anubis suite — installer regression test
#  Installs into a temporary directory (never touches the real installation),
#  verifies the package contents, references and schemas, runs the installer
#  twice and checks idempotency, and asserts that a broken source fails.
#
#  Usage: bash tests/install_test.sh
#  Exit:  0 = all checks pass, 1 = at least one failure
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

INSTALL_FAIL=0
IDEMPOTENT_FAIL=0
REFERENCE_FAIL=0
SCHEMA_FAIL=0

TMP="$(mktemp -d)"
BROKEN_SRC="$(mktemp -d)"
cleanup() { rm -rf "$TMP" "$BROKEN_SRC"; }
trap cleanup EXIT

ok()  { printf '  \033[0;32mPASS\033[0m %s\n' "$1"; }
bad() { printf '  \033[0;31mFAIL\033[0m %s\n' "$1"; }

head() { printf '\n\033[1m%s\033[0m\n' "$1"; }

REQUIRED_FILES=(
  Anubis.agent.md
  Anubis.devops.md
  references/review-protocol.md
  references/dotnet.md
  references/security.md
  references/architecture.md
  references/performance.md
  references/efcore.md
  references/testing.md
  references/msbuild.md
  references/azure-devops-rules.md
  schemas/finding.schema.json
  schemas/review.schema.json
  schemas/handoff.schema.json
)

snapshot() {
  # Stable file list + content hashes, excluding the package marker line version.
  ( cd "$1" && find . -type f | sort | while IFS= read -r f; do
      printf '%s %s\n' "$(shasum "$f" | awk '{print $1}')" "$f"
    done ) | shasum | awk '{print $1}'
}

# ── 1. Installation ──────────────────────────────────────────────────────────
head "Installation into temporary directory"
if bash install.sh --dest "$TMP" >/dev/null 2>&1; then
  ok "installer exited 0"
else
  bad "installer exited non-zero"
  INSTALL_FAIL=1
fi

MISSING=0
for f in "${REQUIRED_FILES[@]}"; do
  if [[ ! -s "$TMP/$f" ]]; then
    bad "missing required file: $f"
    MISSING=$((MISSING + 1))
  fi
done
if [[ "$MISSING" -eq 0 ]]; then
  ok "all required files installed"
else
  INSTALL_FAIL=1
fi

# ── 2. Idempotency ───────────────────────────────────────────────────────────
head "Idempotency"
SNAP1="$(snapshot "$TMP")"
if bash install.sh --dest "$TMP" >/dev/null 2>&1; then
  ok "second install exited 0"
else
  bad "second install exited non-zero"
  IDEMPOTENT_FAIL=1
fi
SNAP2="$(snapshot "$TMP")"
if [[ "$SNAP1" == "$SNAP2" ]]; then
  ok "second install produced identical tree"
else
  bad "second install changed the installed tree"
  IDEMPOTENT_FAIL=1
fi

# ── 3. Reference + schema validation on the installed package ────────────────
head "Validation of installed package"
VALIDATE_OUT="$(bash tests/validate.sh "$TMP" 2>&1)"
if grep -q 'REFERENCE TEST: PASS' <<<"$VALIDATE_OUT"; then
  ok "reference validation on installed package"
else
  bad "reference validation on installed package"
  printf '%s\n' "$VALIDATE_OUT"
  REFERENCE_FAIL=1
fi
if grep -q 'SCHEMA TEST: PASS' <<<"$VALIDATE_OUT"; then
  ok "schema validation on installed package"
else
  bad "schema validation on installed package"
  printf '%s\n' "$VALIDATE_OUT"
  SCHEMA_FAIL=1
fi

# ── 4. Missing runtime file must fail the installation ───────────────────────
head "Broken source must fail installation"
BROKEN_DEST="$(mktemp -d)"
cp Anubis.agent.md Anubis.devops.md "$BROKEN_SRC/"
cp -R references schemas examples "$BROKEN_SRC/"
rm -f "$BROKEN_SRC/references/review-protocol.md"
if ANUBIS_SOURCE_DIR="$BROKEN_SRC" bash install.sh --dest "$BROKEN_DEST" >/dev/null 2>&1; then
  bad "installer exited 0 despite a missing runtime file"
  INSTALL_FAIL=1
else
  ok "installer failed when a runtime file was missing"
fi
rm -rf "$BROKEN_DEST"

# ── Result ───────────────────────────────────────────────────────────────────
printf '\n'
[[ "$INSTALL_FAIL" -eq 0 ]]    && echo "INSTALLATION TEST: PASS" || echo "INSTALLATION TEST: FAIL"
[[ "$IDEMPOTENT_FAIL" -eq 0 ]] && echo "IDEMPOTENCY TEST: PASS"  || echo "IDEMPOTENCY TEST: FAIL"
[[ "$REFERENCE_FAIL" -eq 0 ]]  && echo "REFERENCE TEST: PASS"    || echo "REFERENCE TEST: FAIL"
[[ "$SCHEMA_FAIL" -eq 0 ]]     && echo "SCHEMA TEST: PASS"       || echo "SCHEMA TEST: FAIL"

if [[ "$INSTALL_FAIL" -eq 0 && "$IDEMPOTENT_FAIL" -eq 0 && \
      "$REFERENCE_FAIL" -eq 0 && "$SCHEMA_FAIL" -eq 0 ]]; then
  printf '\n\033[0;32mINSTALLER TESTS OK\033[0m\n'
  exit 0
fi
printf '\n\033[0;31mINSTALLER TESTS FAILED\033[0m\n'
exit 1
