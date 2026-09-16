#!/usr/bin/env bash
# =============================================================================
#  Anubis suite — regression test
#  Verifies that the skills refactoring did not lose rules, severities, modes,
#  handoffs, output structure, schemas or internal references.
#
#  Usage: bash tests/regression.sh
#  Exit:  0 = all checks pass, 1 = at least one failure
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

ok()   { printf '  \033[0;32mPASS\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  \033[0;31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
head() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# has <file> <pattern> <label>
has() {
  if grep -qE -- "$2" "$1" 2>/dev/null; then ok "$3"; else bad "$3 (missing: $2 in $1)"; fi
}
# file_exists <path> <label>
file_exists() {
  if [[ -f "$1" ]]; then ok "$2"; else bad "$2 (missing file: $1)"; fi
}

head "Gate 1 — Repository / files"
for f in \
  Anubis.agent.md Anubis.devops.md README.md \
  references/review-protocol.md references/dotnet.md references/security.md \
  references/architecture.md references/performance.md references/efcore.md \
  references/testing.md references/msbuild.md references/azure-devops-rules.md \
  schemas/finding.schema.json schemas/review.schema.json schemas/handoff.schema.json \
  examples/dotnet-review.md examples/security-review.md \
  examples/performance-review.md examples/devops-review.md \
  tests/regression.md \
  tests/anubis/security.md tests/anubis/architecture.md \
  tests/anubis/performance.md tests/anubis/testing.md tests/anubis/false-positive.md \
  tests/devops/secrets.md tests/devops/identity.md \
  tests/devops/supply-chain.md tests/devops/pipeline.md tests/devops/false-positive.md \
  docs/refactoring-baseline.md docs/refactoring-report.md; do
  file_exists "$f" "exists: $f"
done

head "Gate 2 — Skill operating contracts"
has Anubis.agent.md '^## Mission' "Anubis has Mission"
has Anubis.agent.md '^## Scope' "Anubis has Scope"
has Anubis.agent.md '^## Non-Scope' "Anubis has Non-Scope"
has Anubis.agent.md '^## Review Workflow' "Anubis has Review Workflow"
has Anubis.agent.md 'Quick Pass' "Anubis preserves Quick Pass"
has Anubis.agent.md 'Full Review' "Anubis preserves Full Review"
has Anubis.agent.md 'BLOCKED' "Anubis preserves BLOCKED review status"
has Anubis.devops.md '^## Mission' "DevOps has Mission"
has Anubis.devops.md '^## Scope' "DevOps has Scope"
has Anubis.devops.md '^## Non-Scope' "DevOps has Non-Scope"
has Anubis.devops.md '^## Detection' "DevOps has Detection"
has Anubis.devops.md 'STRUCTURAL PARSING FIRST|Structural YAML parsing first' "DevOps prefers structural parsing"

head "Gate 3 — Output contract preserved (both skills)"
for section in 'Decisioni chiave' 'Assunzioni' 'Rischi' 'Blocchi' 'Artefatti prodotti' 'Handoff al prossimo agente'; do
  has Anubis.agent.md "$section" "Anubis output: $section"
  has Anubis.devops.md "$section" "DevOps output: $section"
done

head "Gate 4 — Handoff preserved"
has Anubis.agent.md 'anubis-devops' "Anubis → anubis-devops handoff"
has Anubis.agent.md 'human' "Anubis → human handoff"
has Anubis.agent.md 'nessuno|`none`' "Anubis → none handoff"
has Anubis.devops.md '`anubis`|→ `Anubis`' "DevOps → Anubis handoff"
has Anubis.devops.md 'human' "DevOps → human handoff"

head "Gate 5 — Azure DevOps rules preserved (41 ids)"
AZDO_IDS="001 002 003 004 005 006 007 008 010 011 012 013 014 015 016 017 018 019 020 021 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 038 039 040 041 042"
for n in $AZDO_IDS; do
  has references/azure-devops-rules.md "AZDO-SEC${n}" "rule AZDO-SEC${n} preserved"
done
COUNT=$(grep -oE '^\| `AZDO-SEC[0-9]{3}`' references/azure-devops-rules.md | sort -u | wc -l | tr -d ' ')
if [[ "$COUNT" == "41" ]]; then ok "exactly 41 unique AZDO rule ids (found $COUNT)"; else bad "expected 41 AZDO ids, found $COUNT"; fi

head "Gate 6 — .NET / MSBuild knowledge preserved"
MSBUILD_IDS="AP-01 AP-02 AP-03 AP-04 AP-05 AP-06 AP-07 AP-08 AP-09"
for ap in $MSBUILD_IDS; do
  has references/msbuild.md "$ap" "MSBuild $ap preserved"
done
has references/dotnet.md 'async void' "dotnet: async void"
has references/dotnet.md '\.Result' "dotnet: .Result"
has references/dotnet.md 'Wait\(\)' "dotnet: .Wait()"
has references/performance.md 'WhenAll' "performance: WhenAll concurrency"
has references/performance.md 'StringBuilder' "performance: StringBuilder"
has references/efcore.md 'AsNoTracking' "efcore: AsNoTracking"
has references/efcore.md 'FromSqlRaw' "efcore: FromSqlRaw"
has references/testing.md 'MSTest' "testing: MSTest"
has references/testing.md 'CRAP' "testing: CRAP score"
has references/testing.md 'ThrowsExactly' "testing: ThrowsExactly"

head "Gate 7 — Security score formula preserved (secondary metric)"
has Anubis.devops.md 'CRITICAL × 20 \+ HIGH × 10 \+ MEDIUM × 3 \+ LOW × 1' "score formula present"
has Anubis.devops.md 'secondary metric' "score explicitly secondary"

head "Gate 8 — BLOCKER is not a severity"
if grep -qE '\| *`BLOCKER`' Anubis.agent.md; then bad "Anubis severity table still contains BLOCKER"; else ok "Anubis severity table has no BLOCKER row"; fi
has Anubis.devops.md 'not a severity' "DevOps states BLOCKED is not a severity"

head "Gate 9 — JSON schemas valid"
if command -v python3 >/dev/null 2>&1; then
  for s in schemas/finding.schema.json schemas/review.schema.json schemas/handoff.schema.json; do
    if python3 -c "import json,sys; json.load(open('$s'))" 2>/dev/null; then ok "valid JSON: $s"; else bad "invalid JSON: $s"; fi
  done
else
  echo "  SKIP python3 not available"
fi
has schemas/review.schema.json '"COMPLETE", "PARTIAL", "BLOCKED"' "review status enum"
has schemas/finding.schema.json '"CRITICAL", "HIGH", "MEDIUM", "LOW"' "severity enum"
has schemas/finding.schema.json '"HIGH", "MEDIUM", "LOW"' "confidence enum"

head "Gate 10 — Internal references resolve"
MISSING=0
while IFS= read -r p; do
  [[ "$p" == *'{'* || "$p" == *'*'* ]] && continue
  if [[ ! -e "$p" ]]; then echo "    broken: $p"; MISSING=$((MISSING + 1)); fi
done < <(grep -rhoE '(references|schemas|examples|tests|docs)/[A-Za-z0-9._/-]+\.(md|json|sh)' \
          Anubis.agent.md Anubis.devops.md references/ README.md 2>/dev/null | sort -u)
if [[ "$MISSING" -eq 0 ]]; then ok "no broken internal references"; else bad "$MISSING broken internal reference(s)"; fi

head "Result"
printf '  passed: %d   failed: %d\n' "$PASS" "$FAIL"
if [[ "$FAIL" -eq 0 ]]; then printf '\n\033[0;32mREGRESSION OK\033[0m\n'; exit 0; fi
printf '\n\033[0;31mREGRESSION FAILED\033[0m\n'; exit 1
