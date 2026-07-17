#!/usr/bin/env bash
# =============================================================================
#  Anubis Agent Suite — Uninstaller v1.0
#  Rimuove Anubis (.NET) e Anubis-devops (Azure DevOps) da tutti i
#  coding agent rilevati.
#
#  Uso:
#    curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/uninstall.sh | bash
#    ./uninstall.sh
# =============================================================================

set -euo pipefail

RED='\033[0;31m'   GREEN='\033[0;32m'   YELLOW='\033[1;33m'
CYAN='\033[0;36m'  BOLD='\033[1m'       NC='\033[0m'

ANUBIS_VERSION="1.0"

AGENTS=(
  "$HOME/.claude/agents"
  "$HOME/.config/opencode/agents"
  "$HOME/.copilot/agents"
  "$HOME/.cursor/agents"
  "$HOME/.windsurf/agents"
  "$HOME/.codex/agents"
)

# Su Windows cerca anche in APPDATA
if [[ -n "${APPDATA:-}" ]]; then
  AGENTS+=("$APPDATA/Claude/agents")
  AGENTS+=("$APPDATA/opencode/agents")
  AGENTS+=("$APPDATA/Cursor/agents")
  AGENTS+=("$APPDATA/Windsurf/agents")
fi

echo -e "${CYAN}${BOLD}"
echo "  ⚖️  Anubis Agent Suite — Uninstaller v${ANUBIS_VERSION}"
echo -e "${NC}"
echo "  Rimuove Anubis e Anubis-devops da tutti i coding agent"
echo ""

total=0
for dir in "${AGENTS[@]}"; do
  [[ ! -d "$dir" ]] && continue

  # Anubis.agent.md (Claude, Copilot, Cursor, Windsurf, Codex)
  for f in "$dir/Anubis.agent.md" "$dir/anubis.md" "$dir/Anubis.devops.md" "$dir/anubis-devops.md"; do
    if [[ -f "$f" ]]; then
      rm "$f"
      echo -e "  ${GREEN}✓${NC} Rimosso $(basename "$f") da ${dir}"
      ((total++)) || true
    fi
  done

  # anubis-docs/ e anubis-devops-docs/
  for d in "$dir/anubis-docs" "$dir/anubis-devops-docs"; do
    if [[ -d "$d" ]]; then
      rm -rf "$d"
      echo -e "  ${GREEN}✓${NC} Rimossa directory $(basename "$d")/ da ${dir}"
    fi
  done
done

echo ""
if [[ $total -eq 0 ]]; then
  echo -e "${YELLOW}${BOLD}○${NC} Nessun agente Anubis trovato da rimuovere."
else
  echo -e "${GREEN}${BOLD}✓${NC} Rimossi ${total} file agente Anubis."
fi
echo -e "  ${BOLD}Done.${NC}"
