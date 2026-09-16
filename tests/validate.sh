#!/usr/bin/env bash
# =============================================================================
#  Anubis suite — reference & schema validation
#  Verifies that every file referenced by the skills exists and that the
#  JSON schemas are valid JSON Schema with resolvable internal $refs.
#
#  Usage: bash tests/validate.sh [ROOT]
#    ROOT  directory containing Anubis.agent.md / Anubis.devops.md and the
#          references/ + schemas/ directories (default: repository root).
#  Exit:  0 = all checks pass, 1 = at least one failure
# =============================================================================
set -uo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$ROOT" || { echo "cannot enter ROOT: $ROOT" >&2; exit 1; }

REF_FAIL=0
SCHEMA_FAIL=0

say()  { printf '%s\n' "$1"; }
ok()   { printf '  \033[0;32mPASS\033[0m %s\n' "$1"; }
bad()  { printf '  \033[0;31mFAIL\033[0m %s\n' "$1"; }

# Expand a single-level brace group: a{b,c}d -> ab d, acd
expand_braces() {
  local p="$1"
  if [[ "$p" =~ ^([^{}]*)\{([^{}]*)\}(.*)$ ]]; then
    local prefix="${BASH_REMATCH[1]}" items="${BASH_REMATCH[2]}" suffix="${BASH_REMATCH[3]}"
    local it
    local IFS=','
    for it in $items; do
      printf '%s%s%s\n' "$prefix" "$it" "$suffix"
    done
  else
    printf '%s\n' "$p"
  fi
}

# ── Reference validation ─────────────────────────────────────────────────────
say ""
printf '\033[1mReference validation (root: %s)\033[0m\n' "$ROOT"

SKILL_FILES=()
for f in Anubis.agent.md Anubis.devops.md Anubis.Arch.md Anubis.Runtime.md Anubis.GreenOps.md; do
  [[ -f "$f" ]] && SKILL_FILES+=("$f")
done

if [[ "${#SKILL_FILES[@]}" -eq 0 ]]; then
  bad "no skill files found in $ROOT"
  REF_FAIL=1
fi

REF_MISSING=0
REF_CHECKED=0
while IFS= read -r raw; do
  [[ -z "$raw" ]] && continue
  # Wildcards are not statically resolvable.
  [[ "$raw" == *'*'* ]] && continue

  while IFS= read -r candidate; do
    [[ -z "$candidate" ]] && continue
    REF_CHECKED=$((REF_CHECKED + 1))
    if [[ ! -e "$candidate" ]]; then
      bad "broken reference: $candidate"
      REF_MISSING=$((REF_MISSING + 1))
    fi
  done < <(expand_braces "$raw")
done < <(
  grep -rhoE '(references|schemas|examples|tests|docs)/[A-Za-z0-9._,{}/-]+\.(md|json|sh)' \
    "${SKILL_FILES[@]}" 2>/dev/null | sort -u
)

if [[ "$REF_MISSING" -eq 0 ]]; then
  ok "all referenced files exist ($REF_CHECKED checked)"
  say "REFERENCE TEST: PASS"
else
  say "REFERENCE TEST: FAIL ($REF_MISSING missing)"
  REF_FAIL=1
fi

# ── Schema validation ────────────────────────────────────────────────────────
say ""
printf '\033[1mSchema validation\033[0m\n'

SCHEMAS=(schemas/finding.schema.json schemas/review.schema.json schemas/handoff.schema.json)

validate_schema() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    bad "missing schema: $file"
    return 1
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$file" <<'PY'
import json, sys

path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as fh:
        doc = json.load(fh)
except Exception as exc:  # noqa: BLE001
    print("  FAIL invalid JSON: %s (%s)" % (path, exc))
    sys.exit(1)

if not isinstance(doc, dict):
    print("  FAIL not a JSON object: %s" % path)
    sys.exit(1)
if "$schema" not in doc:
    print("  FAIL missing $schema: %s" % path)
    sys.exit(1)

# Resolve every local JSON pointer $ref (#/...).
def walk(node):
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "$ref" and isinstance(v, str) and v.startswith("#/"):
                yield v
            yield from walk(v)
    elif isinstance(node, list):
        for item in node:
            yield from walk(item)

def resolve(ref, root):
    node = root
    for part in ref[2:].split("/"):
        part = part.replace("~1", "/").replace("~0", "~")
        if isinstance(node, list):
            node = node[int(part)]
        elif isinstance(node, dict) and part in node:
            node = node[part]
        else:
            return False
    return True

for ref in walk(doc):
    try:
        if not resolve(ref, doc):
            print("  FAIL unresolved $ref %s in %s" % (ref, path))
            sys.exit(1)
    except (LookupError, ValueError):
        print("  FAIL unresolved $ref %s in %s" % (ref, path))
        sys.exit(1)

# Best-effort full meta-schema check when jsonschema is available.
try:
    import jsonschema
    try:
        jsonschema.Draft202012Validator.check_schema(doc)
    except Exception as exc:  # noqa: BLE001
        print("  FAIL invalid JSON Schema: %s (%s)" % (path, exc))
        sys.exit(1)
except ImportError:
    pass

print("  PASS %s" % path)
PY
    return $?
  fi

  if command -v jq >/dev/null 2>&1; then
    if jq -e . "$file" >/dev/null 2>&1 && jq -e 'has("$schema")' "$file" >/dev/null 2>&1; then
      ok "$file (jq)"
      return 0
    fi
    bad "invalid JSON/schema: $file"
    return 1
  fi

  bad "no JSON validator available (python3 or jq required)"
  return 1
}

for s in "${SCHEMAS[@]}"; do
  if ! validate_schema "$s"; then
    SCHEMA_FAIL=1
  fi
done

say ""
if [[ "$SCHEMA_FAIL" -eq 0 ]]; then
  say "SCHEMA TEST: PASS"
else
  say "SCHEMA TEST: FAIL"
fi

# ── Result ───────────────────────────────────────────────────────────────────
say ""
if [[ "$REF_FAIL" -eq 0 && "$SCHEMA_FAIL" -eq 0 ]]; then
  printf '\033[0;32mVALIDATION OK\033[0m\n'
  exit 0
fi
printf '\033[0;31mVALIDATION FAILED\033[0m\n'
exit 1
