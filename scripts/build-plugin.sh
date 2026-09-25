#!/usr/bin/env bash
# =============================================================================
#  Anubis — Build del plugin Claude Code
#
#  Genera plugin/agents/*.md a partire dai file sorgente root
#  (Anubis.agent.md, Anubis.devops.md, ...), che restano l'unica fonte di
#  verità anche per install.sh. Sincronizza inoltre references/ · schemas/ ·
#  examples/ dentro plugin/, così il plugin è auto-contenuto e installabile
#  via `/plugin marketplace add` senza dipendere da install.sh.
#
#  Uso:
#    ./scripts/build-plugin.sh
#
#  Da rieseguire dopo ogni modifica a un file Anubis*.md in root o a
#  references/ · schemas/ · examples/.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$ROOT/plugin"
AGENTS_DIR="$PLUGIN_DIR/agents"

RED='\033[0;31m' GREEN='\033[0;32m' NC='\033[0m'

# Array paralleli: file sorgente in root -> nome file generato in plugin/agents/.
SRC_FILE=(
    "Anubis.agent.md"
    "Anubis.devops.md"
    "Anubis.Arch.md"
    "Anubis.Runtime.md"
    "Anubis.GreenOps.md"
)
DEST_FILE=(
    "anubis.md"
    "anubis-devops.md"
    "anubis-arch.md"
    "anubis-runtime.md"
    "anubis-greenops.md"
)

mkdir -p "$AGENTS_DIR"

# Estrae un campo scalare (name|description|model) dal frontmatter YAML del file sorgente.
frontmatter_field() {
    local file="$1" field="$2"
    awk -v field="$field" '
      BEGIN { c = 0 }
      /^---$/ { c++; if (c >= 2) exit; next }
      c == 1 {
        pattern = "^" field ":[ ]*"
        if ($0 ~ pattern) {
          sub(pattern, "")
          gsub(/^"|"$/, "")
          print
          exit
        }
      }
    ' "$file"
}

# Corpo del file sorgente: tutto ciò che segue il secondo delimitatore ---.
body_of() {
    local file="$1"
    tr -d '\r' < "$file" | awk '
      BEGIN { c = 0 }
      /^---$/ && c < 2 { c++; next }
      c >= 2 { print }
    '
}

build_agent() {
    local src="$ROOT/$1" dest="$AGENTS_DIR/$2"
    local name description model body

    name=$(frontmatter_field "$src" "name")
    description=$(frontmatter_field "$src" "description")
    model=$(frontmatter_field "$src" "model")
    body=$(body_of "$src")

    if [[ -z "$name" || -z "$description" ]]; then
        echo -e "${RED}✗${NC} frontmatter incompleto in $src (name/description mancante)" >&2
        return 1
    fi

    {
        echo "---"
        echo "name: ${name}"
        echo "description: \"${description}\""
        [[ -n "$model" ]] && echo "model: ${model}"
        echo "---"
        echo ""
        echo "<!-- File generato da scripts/build-plugin.sh — non modificare a mano."
        echo "     Sorgente: $1 (root). Rieseguire lo script dopo ogni modifica. -->"
        echo ""
        echo "$body"
    } > "$dest"

    echo -e "  ${GREEN}✓${NC} plugin/agents/$2 <- $1"
}

echo "Generazione agent plugin da sorgenti root..."
i=0
while [[ $i -lt ${#SRC_FILE[@]} ]]; do
    build_agent "${SRC_FILE[$i]}" "${DEST_FILE[$i]}"
    i=$((i + 1))
done

echo ""
echo "Sincronizzazione asset (references/ · schemas/ · examples/)..."
for asset in references schemas examples; do
    rm -rf "$PLUGIN_DIR/$asset"
    cp -R "$ROOT/$asset" "$PLUGIN_DIR/$asset"
    echo -e "  ${GREEN}✓${NC} plugin/$asset/ <- $asset/"
done

echo ""
echo "Verifica riferimenti interni al plugin..."
MISSING=0
while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    [[ "$ref" == *'*'* ]] && continue
    if [[ ! -e "$PLUGIN_DIR/$ref" ]]; then
        echo -e "  ${RED}✗${NC} riferimento non risolto in plugin/: $ref" >&2
        MISSING=1
    fi
done < <(grep -rhoE '(references|schemas|examples)/[A-Za-z0-9._/-]+\.(md|json)' "$AGENTS_DIR"/*.md 2>/dev/null | sort -u)

if [[ "$MISSING" -ne 0 ]]; then
    echo -e "${RED}✗${NC} Build plugin incompleta: asset mancanti." >&2
    exit 1
fi

echo -e "${GREEN}✓${NC} Plugin generato in plugin/ ed è auto-contenuto."
