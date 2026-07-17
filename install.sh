#!/usr/bin/env bash
# =============================================================================
#  Anubis Agent Suite — Global Installer v1.1
#  Installa Anubis (.NET) e Anubis-devops (Azure DevOps) per tutti i
#  coding agent rilevati con frontmatter nativo:
#  Claude Code · OpenCode · GitHub Copilot · Cursor · Windsurf · Codex
#
#  Uso:
#    curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/install.sh | bash
#    ./install.sh                                  # installa tutta la suite
#    ./install.sh --agent anubis                   # solo Anubis (.NET)
#    ./install.sh --agent devops                   # solo Anubis-devops
#    ./install.sh --agent claude                   # solo per Claude Code
#    ./install.sh --local                          # installa nella directory corrente
#    ./install.sh --backup                         # backup dei file esistenti
#    ./install.sh --uninstall                      # rimuove tutta la suite
# =============================================================================

set -euo pipefail

# ── Colori ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'   GREEN='\033[0;32m'   YELLOW='\033[1;33m'
CYAN='\033[0;36m'  BOLD='\033[1m'      NC='\033[0m'

# ── Configurazione ───────────────────────────────────────────────────────────
ANUBIS_VERSION="1.1.0"
REPO_URL="https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main"

# ── Agente 1: Anubis (.NET) ──────────────────────────────────────────────────
ANUBIS_FILE="Anubis.agent.md"
ANUBIS_DESCRIPTION='Anubis .NET Agent — review tecnica strutturata di codice .NET con severity condivisa, refactoring concreti e handoff verso DevSecOps e delivery'
ANUBIS_SHORT_NAME="Anubis"
_BODY_ANUBIS=""

# ── Agente 2: Anubis-devops (Azure DevOps) ───────────────────────────────────
DEVOPS_FILE="Anubis.devops.md"
DEVOPS_DESCRIPTION='Anubis-devops Agent — analisi security di pipeline YAML Azure DevOps con severity condivisa, mapping CWE, remediation concrete (split YAML/Infra/Code), Security Score formalizzato e handoff verso Anubis'
DEVOPS_SHORT_NAME="Anubis-devops"
_BODY_DEVOPS=""

# ── Banner ───────────────────────────────────────────────────────────────────
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "  ⚖️  Anubis Agent Suite — Global Installer v${ANUBIS_VERSION}"
    echo -e "${NC}"
    echo "  ● Anubis        — Senior Code Reviewer .NET 8+"
    echo "  ● Anubis-devops — Azure DevOps Pipeline Security"
    echo ""
}

# ── OS Detection ─────────────────────────────────────────────────────────────
detect_os() {
    case "$(uname -s)" in
        Darwin*)  OS="macos" ;;
        Linux*)   OS="linux" ;;
        MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
        *)        OS="unknown" ;;
    esac
}

# ── Agent Body ──────────────────────────────────────────────────────────────
# Estrae il corpo dell'agente (tutto dopo il frontmatter YAML) dal file sorgente.
# Argomenti: anubis | devops

get_agent_body() {
    local agent_type="${1:-anubis}"

    # Cache lookup
    if [[ "$agent_type" == "devops" && -n "$_BODY_DEVOPS" ]]; then
        echo "$_BODY_DEVOPS"
        return 0
    fi
    if [[ "$agent_type" == "anubis" && -n "$_BODY_ANUBIS" ]]; then
        echo "$_BODY_ANUBIS"
        return 0
    fi

    # Determina nome file
    local agent_filename
    case "$agent_type" in
        devops) agent_filename="$DEVOPS_FILE" ;;
        *)      agent_filename="$ANUBIS_FILE" ;;
    esac

    local src=""
    if [[ -f "$SCRIPT_DIR/$agent_filename" ]]; then
        src="$SCRIPT_DIR/$agent_filename"
    else
        src=$(mktemp)
        if command -v curl &>/dev/null; then
            curl -fsSL "${REPO_URL}/${agent_filename}" -o "$src" || {
                rm -f "$src"
                echo -e "${RED}✗${NC} Download fallito da ${REPO_URL}/${agent_filename}" >&2
                return 1
            }
        elif command -v wget &>/dev/null; then
            wget -q "${REPO_URL}/${agent_filename}" -O "$src" || {
                rm -f "$src"
                echo -e "${RED}✗${NC} Download fallito da ${REPO_URL}/${agent_filename}" >&2
                return 1
            }
        else
            echo -e "${RED}✗${NC} Nessuno tra curl o wget disponibile. Installa curl e riprova." >&2
            return 1
        fi
    fi

    # Estrai il corpo: salta tutto fino al secondo --- (fine frontmatter YAML)
    # Normalizza \r\n → \n per robustezza su file con CRLF
    local body
    body=$(tr -d '\r' < "$src" | awk '
      BEGIN { c = 0 }
      /^---$/ && c < 2 { c++; next }
      c >= 2 { print }
    ')

    # Salva in cache
    if [[ "$agent_type" == "devops" ]]; then
        _BODY_DEVOPS="$body"
    else
        _BODY_ANUBIS="$body"
    fi

    # Pulizia se è stato scaricato in tmp
    if [[ "$src" != "$SCRIPT_DIR/$agent_filename" ]]; then
        rm -f "$src"
    fi

    echo "$body"
}

# ── Docs ─────────────────────────────────────────────────────────────────────
# Copia i file docs/ nella directory dell'agente come riferimento.

copy_anubis_docs() {
    local target_dir="$1"
    local docs_dir="${target_dir}/anubis-docs"
    mkdir -p "$docs_dir"
    local copied=0

    local doc_files=("installation.md" "usage.md" "examples.md")

    for doc in "${doc_files[@]}"; do
        local dest="${docs_dir}/${doc}"

        if [[ "$DO_BACKUP" == "true" ]] && [[ -f "$dest" ]]; then
            cp "$dest" "${dest}.backup-$(date +%Y%m%d-%H%M%S)"
        fi

        if [[ -f "$SCRIPT_DIR/docs/$doc" ]]; then
            cp "$SCRIPT_DIR/docs/$doc" "$dest"
        elif command -v curl &>/dev/null; then
            curl -fsSL "${REPO_URL}/docs/${doc}" -o "$dest" || { rm -f "$dest"; continue; }
        elif command -v wget &>/dev/null; then
            wget -q "${REPO_URL}/docs/${doc}" -O "$dest" || { rm -f "$dest"; continue; }
        else
            continue
        fi

        ((copied++)) || true
    done

    if [[ $copied -gt 0 ]]; then
        echo -e "  ${GREEN}✓${NC} ${copied} doc Anubis  → ${docs_dir}/"
    fi
}

copy_devops_docs() {
    local target_dir="$1"
    local docs_dir="${target_dir}/anubis-devops-docs"
    mkdir -p "$docs_dir"
    local copied=0

    local doc_files=("installation.md" "usage.md" "examples.md")

    for doc in "${doc_files[@]}"; do
        local dest="${docs_dir}/${doc}"

        if [[ "$DO_BACKUP" == "true" ]] && [[ -f "$dest" ]]; then
            cp "$dest" "${dest}.backup-$(date +%Y%m%d-%H%M%S)"
        fi

        # I docs devops sono in docs/devops/
        if [[ -f "$SCRIPT_DIR/docs/devops/$doc" ]]; then
            cp "$SCRIPT_DIR/docs/devops/$doc" "$dest"
        elif command -v curl &>/dev/null; then
            curl -fsSL "${REPO_URL}/docs/devops/${doc}" -o "$dest" || { rm -f "$dest"; continue; }
        elif command -v wget &>/dev/null; then
            wget -q "${REPO_URL}/docs/devops/${doc}" -O "$dest" || { rm -f "$dest"; continue; }
        else
            continue
        fi

        ((copied++)) || true
    done

    if [[ $copied -gt 0 ]]; then
        echo -e "  ${GREEN}✓${NC} ${copied} doc Devops → ${docs_dir}/"
    fi
}

# ── Frontmatter per piattaforma ──────────────────────────────────────────────

get_frontmatter() {
    local platform="$1"     # claude | opencode | generic
    local short_name="$2"   # Anubis | Anubis-devops
    local description="$3"  # descrizione specifica per l'agente

    case "$platform" in
        claude|generic)
            echo "---"
            echo "name: ${short_name}"
            echo "description: \"${description}\""
            echo "---"
            ;;
        opencode)
            echo "---"
            echo "description: \"${description}\""
            echo "mode: all"
            cat <<'EOF'
permission:
  read: allow
  edit: allow
  glob: allow
  grep: allow
  list: allow
  bash: allow
  task: allow
  webfetch: allow
  websearch: allow
  lsp: allow
  skill: allow
---
EOF
            ;;
    esac
}

# Mappa il nome del coding agent al tipo di piattaforma per il frontmatter
get_platform() {
    case "$1" in
        "OpenCode")   echo "opencode" ;;
        "Claude Code") echo "claude" ;;
        *)            echo "generic" ;;
    esac
}

# ── Agent Directories ────────────────────────────────────────────────────────

get_agent_dirs() {
    local agent="$1"  # vuoto = tutti, oppure nome specifico
    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"

    case "$OS" in
        macos|linux)
            if [[ -z "$agent" || "$agent" == "claude" ]]; then
                if command -v claude &>/dev/null || [[ -d "$HOME/.claude" ]]; then
                    printf '%s|%s\n' "$HOME/.claude/agents" "Claude Code"
                fi
            fi

            if [[ -z "$agent" || "$agent" == "opencode" ]]; then
                if [[ -d "$xdg_config/opencode/agents" ]]; then
                    printf '%s|%s\n' "$xdg_config/opencode/agents" "OpenCode"
                fi
            fi

            if [[ -z "$agent" || "$agent" == "copilot" ]]; then
                if [[ -d "$HOME/.copilot" ]]; then
                    printf '%s|%s\n' "$HOME/.copilot/agents" "GitHub Copilot"
                fi
            fi

            if [[ -z "$agent" || "$agent" == "cursor" ]]; then
                if [[ -d "$HOME/.cursor" ]] && [[ -d "$HOME/.cursor/agents" ]]; then
                    printf '%s|%s\n' "$HOME/.cursor/agents" "Cursor"
                fi
            fi

            if [[ -z "$agent" || "$agent" == "windsurf" ]]; then
                if [[ -d "$HOME/.windsurf" ]] && [[ -d "$HOME/.windsurf/agents" ]]; then
                    printf '%s|%s\n' "$HOME/.windsurf/agents" "Windsurf"
                fi
            fi

            if [[ -z "$agent" || "$agent" == "codex" ]]; then
                if [[ -d "$HOME/.codex" ]] || command -v codex &>/dev/null; then
                    printf '%s|%s\n' "$HOME/.codex/agents" "OpenAI Codex"
                fi
            fi
            ;;

        windows)
            local appdata="${APPDATA:-$HOME/AppData/Roaming}"

            if [[ -z "$agent" || "$agent" == "claude" ]]; then
                printf '%s|%s\n' "$appdata/Claude/agents" "Claude Code"
            fi
            if [[ -z "$agent" || "$agent" == "opencode" ]]; then
                printf '%s|%s\n' "$appdata/opencode/agents" "OpenCode"
            fi
            if [[ -z "$agent" || "$agent" == "copilot" ]]; then
                printf '%s|%s\n' "$HOME/.copilot/agents" "GitHub Copilot"
            fi
            if [[ -z "$agent" || "$agent" == "cursor" ]]; then
                printf '%s|%s\n' "$appdata/Cursor/agents" "Cursor"
            fi
            if [[ -z "$agent" || "$agent" == "windsurf" ]]; then
                printf '%s|%s\n' "$appdata/Windsurf/agents" "Windsurf"
            fi
            if [[ -z "$agent" || "$agent" == "codex" ]]; then
                printf '%s|%s\n' "$HOME/.codex/agents" "OpenAI Codex"
            fi
            ;;
    esac
}

# ── Installa un singolo agente ──────────────────────────────────────────────
# agent_type: anubis | devops

install_one_agent() {
    local target_dir="$1"
    local agent_name="$2"       # es. "Claude Code"
    local agent_type="${3:-anubis}"
    local platform
    platform=$(get_platform "$agent_name")

    # Variabili specifiche per tipo agente
    local short_name description filename body
    case "$agent_type" in
        devops)
            short_name="$DEVOPS_SHORT_NAME"
            description="$DEVOPS_DESCRIPTION"
            filename="$DEVOPS_FILE"
            body=$(get_agent_body "devops") || return 1
            ;;
        *)
            short_name="$ANUBIS_SHORT_NAME"
            description="$ANUBIS_DESCRIPTION"
            filename="$ANUBIS_FILE"
            body=$(get_agent_body "anubis") || return 1
            ;;
    esac

    # Per OpenCode il filename segue convenzione lowercase senza punti
    local dest_filename="$filename"
    if [[ "$platform" == "opencode" ]]; then
        dest_filename="$(echo "$short_name" | tr '[:upper:]' '[:lower:]').md"
    fi

    mkdir -p "$target_dir"
    local dest="${target_dir}/${dest_filename}"

    # Backup solo se richiesto esplicitamente con --backup
    if [[ "$DO_BACKUP" == "true" ]] && [[ -f "$dest" ]]; then
        local backup="${dest}.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$dest" "$backup"
        echo -e "  ${YELLOW}↻${NC} Backup creato: ${backup}"
    fi

    # Genera il file con frontmatter specifico per la piattaforma + corpo
    {
        get_frontmatter "$platform" "$short_name" "$description"
        echo ""
        echo "$body"
    } > "$dest"

    if [[ -s "$dest" ]]; then
        echo -e "  ${GREEN}✓${NC} ${short_name} installato per ${BOLD}${agent_name}${NC} (${platform})"
        echo -e "          → ${dest}"
        return 0
    else
        echo -e "  ${RED}✗${NC} Generazione fallita per ${short_name} su ${agent_name}"
        return 1
    fi
}

# ── Installa entrambi gli agenti in una directory ────────────────────────────
install_agent() {
    local target_dir="$1"
    local agent_name="$2"
    local agent_filter="${3:-all}"  # anubis | devops | all

    local success=0
    local failed=0

    if [[ "$agent_filter" == "all" || "$agent_filter" == "anubis" ]]; then
        if install_one_agent "$target_dir" "$agent_name" "anubis"; then
            copy_anubis_docs "$target_dir"
            ((success++)) || true
        else
            ((failed++)) || true
        fi
    fi

    if [[ "$agent_filter" == "all" || "$agent_filter" == "devops" ]]; then
        if install_one_agent "$target_dir" "$agent_name" "devops"; then
            copy_devops_docs "$target_dir"
            ((success++)) || true
        else
            ((failed++)) || true
        fi
    fi

    return $failed
}

# ── Uninstall ────────────────────────────────────────────────────────────────
uninstall_agent() {
    local target_dir="$1"
    local agent_name="$2"
    local platform
    platform=$(get_platform "$agent_name")

    # Rimuovi Anubis (.NET)
    local dest_anubis="${target_dir}/${ANUBIS_FILE}"
    if [[ "$platform" == "opencode" ]]; then
        dest_anubis="${target_dir}/anubis.md"
    fi
    if [[ -f "$dest_anubis" ]]; then
        rm "$dest_anubis"
        echo -e "  ${GREEN}✓${NC} Anubis rimosso da ${BOLD}${agent_name}${NC}"
    else
        echo -e "  ${YELLOW}○${NC} Nessun Anubis presente per ${agent_name}"
    fi

    # Rimuovi Anubis-devops
    local dest_devops="${target_dir}/${DEVOPS_FILE}"
    if [[ "$platform" == "opencode" ]]; then
        dest_devops="${target_dir}/anubis-devops.md"
    fi
    if [[ -f "$dest_devops" ]]; then
        rm "$dest_devops"
        echo -e "  ${GREEN}✓${NC} Anubis-devops rimosso da ${BOLD}${agent_name}${NC}"
    else
        echo -e "  ${YELLOW}○${NC} Nessun Anubis-devops presente per ${agent_name}"
    fi

    # Rimuovi le directory dei docs
    rm -rf "${target_dir}/anubis-docs"
    rm -rf "${target_dir}/anubis-devops-docs"
}

# ── Local Install ────────────────────────────────────────────────────────────
install_local() {
    local local_dir="${1:-$PWD}"
    local dest_dir="${local_dir}/.claude/agents"
    local agent_filter="${2:-all}"

    mkdir -p "$dest_dir"

    if [[ "$agent_filter" == "all" || "$agent_filter" == "anubis" ]]; then
        local dest="${dest_dir}/${ANUBIS_FILE}"
        {
            get_frontmatter "claude" "$ANUBIS_SHORT_NAME" "$ANUBIS_DESCRIPTION"
            echo ""
            get_agent_body "anubis"
        } > "$dest"

        if [[ -s "$dest" ]]; then
            echo -e "  ${GREEN}✓${NC} ${ANUBIS_SHORT_NAME} installato localmente"
            echo -e "          → ${dest}"
        else
            echo -e "  ${RED}✗${NC} Installazione locale fallita per ${ANUBIS_FILE}"
        fi

        copy_anubis_docs "$dest_dir"
    fi

    if [[ "$agent_filter" == "all" || "$agent_filter" == "devops" ]]; then
        local dest="${dest_dir}/${DEVOPS_FILE}"
        {
            get_frontmatter "claude" "$DEVOPS_SHORT_NAME" "$DEVOPS_DESCRIPTION"
            echo ""
            get_agent_body "devops"
        } > "$dest"

        if [[ -s "$dest" ]]; then
            echo -e "  ${GREEN}✓${NC} ${DEVOPS_SHORT_NAME} installato localmente"
            echo -e "          → ${dest}"
        else
            echo -e "  ${RED}✗${NC} Installazione locale fallita per ${DEVOPS_FILE}"
        fi

        copy_devops_docs "$dest_dir"
    fi

    # Crea/aggiorna settings.json Claude Code con entrambi gli agenti
    local settings="${local_dir}/.claude/settings.json"
    if [[ ! -f "$settings" ]]; then
        cat > "$settings" <<'SETTINGS'
{
  "agents": {
    "Anubis": {
      "description": "Anubis .NET Agent — review tecnica strutturata di codice .NET",
      "path": ".claude/agents/Anubis.agent.md"
    },
    "Anubis-devops": {
      "description": "Anubis-devops Agent — analisi security pipeline YAML Azure DevOps",
      "path": ".claude/agents/Anubis.devops.md"
    }
  }
}
SETTINGS
        echo -e "  ${GREEN}✓${NC} Creato .claude/settings.json con registrazione agenti (Anubis + Anubis-devops)"
    fi
}

# ── Verifica connessione ─────────────────────────────────────────────────────
check_connectivity() {
    if get_agent_body "anubis" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

# ── Help ─────────────────────────────────────────────────────────────────────
print_help() {
    echo "Uso: $0 [--local] [--agent <name>] [--suite <type>] [--backup] [--uninstall] [--help]"
    echo ""
    echo "Opzioni:"
    echo "  --local              Installa solo nella directory corrente"
    echo "  --agent <name>       Installa solo per un agent specifico (claude, opencode, ...)"
    echo "  --suite <type>       Installa solo Anubis (anubis) o solo Anubis-devops (devops)"
    echo "  --backup             Crea backup dei file agent esistenti prima di sovrascrivere"
    echo "  --uninstall          Rimuove Anubis e Anubis-devops da tutti gli agent"
    echo "  --help, -h           Mostra questo help"
    echo ""
    echo "Agent supportati:"
    echo "  claude    — Claude Code"
    echo "  opencode  — OpenCode"
    echo "  copilot   — GitHub Copilot (VS Code / CLI)"
    echo "  cursor    — Cursor"
    echo "  windsurf  — Windsurf"
    echo "  codex     — OpenAI Codex"
    echo ""
    echo "Suite agenti:"
    echo "  anubis    — Anubis (.NET) — Senior Code Reviewer .NET 8+"
    echo "  devops    — Anubis-devops — Azure DevOps Pipeline Security"
    echo ""
    echo "Esempi:"
    echo "  $0                                   # Installa tutta la suite"
    echo "  $0 --suite devops                    # Solo Anubis-devops"
    echo "  $0 --agent claude                    # Solo per Claude Code"
    echo "  $0 --suite anubis --local            # Solo Anubis in locale"
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    print_banner

    detect_os
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    local mode="install"
    local target_agent=""
    local suite_filter="all"    # anubis | devops | all
    DO_BACKUP="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --uninstall)
                mode="uninstall"
                shift
                ;;
            --local)
                mode="local"
                shift
                ;;
            --backup)
                DO_BACKUP="true"
                shift
                ;;
            --suite)
                suite_filter="${2:-}"
                if [[ -z "$suite_filter" ]]; then
                    echo -e "${RED}✗${NC} Specifica: anubis o devops"
                    exit 1
                fi
                shift 2
                ;;
            --agent)
                target_agent="${2:-}"
                if [[ -z "$target_agent" ]]; then
                    echo -e "${RED}✗${NC} Specifica un agent: claude, opencode, copilot, cursor, windsurf, codex"
                    exit 1
                fi
                shift 2
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                echo -e "${RED}✗${NC} Opzione sconosciuta: $1"
                echo "Usa --help per vedere le opzioni disponibili"
                exit 1
                ;;
        esac
    done

    # ── Modalità: Local ──────────────────────────────────────────────────
    if [[ "$mode" == "local" ]]; then
        if [[ -n "$target_agent" ]]; then
            echo -e "${YELLOW}⚠${NC} --local e --agent sono mutualmente esclusivi."
        fi
        echo -e "${BOLD}Installazione locale di Anubis Suite${NC}"
        echo ""
        install_local "$PWD" "$suite_filter"
        echo ""
        echo -e "${GREEN}${BOLD}✓${NC} Installazione locale completata!"
        echo ""
        echo "  Agenti disponibili:"
        if [[ "$suite_filter" == "all" || "$suite_filter" == "anubis" ]]; then
            echo "    • Anubis"
        fi
        if [[ "$suite_filter" == "all" || "$suite_filter" == "devops" ]]; then
            echo "    • Anubis-devops"
        fi
        echo "  Per usarli: seleziona l'agente dal menu quando richiesto."
        exit 0
    fi

    # ── Modalità: Uninstall ──────────────────────────────────────────────
    if [[ "$mode" == "uninstall" ]]; then
        echo -e "${BOLD}Disinstallazione di Anubis Suite${NC}"
        echo ""

        local removed=0
        while IFS='|' read -r dir name; do
            [[ -z "$dir" ]] && continue
            uninstall_agent "$dir" "$name"
            removed=$((removed + 1))
        done < <(get_agent_dirs "$target_agent")

        echo ""
        echo -e "${GREEN}${BOLD}✓${NC} Anubis Suite disinstallata da ${removed} agent directory."
        exit 0
    fi

    # ── Modalità: Install ────────────────────────────────────────────────
    echo -e "${BOLD}Installazione globale di Anubis Suite${NC}"
    echo -e "  OS rilevato: ${CYAN}${OS}${NC}"
    echo ""

    # Verifica connettività prima di procedere
    if ! check_connectivity; then
        echo -e "${RED}✗${NC} Impossibile accedere al file agente. Verifica la connessione."
        exit 1
    fi

    local installed=0
    local skipped=0
    local agents_to_install=("anubis" "devops")

    if [[ "$suite_filter" == "anubis" ]]; then
        agents_to_install=("anubis")
    elif [[ "$suite_filter" == "devops" ]]; then
        agents_to_install=("devops")
    fi

    while IFS='|' read -r dir name; do
        [[ -z "$dir" ]] && continue
        for agent in "${agents_to_install[@]}"; do
            if install_agent "$dir" "$name" "$agent"; then
                installed=$((installed + 1))
            else
                skipped=$((skipped + 1))
            fi
        done
    done < <(get_agent_dirs "$target_agent")

    echo ""
    echo -e "${GREEN}${BOLD}✓${NC} Completato: ${installed} installazioni, ${skipped} saltati"

    if [[ -z "$target_agent" && $installed -eq 0 ]]; then
        echo ""
        echo -e "${YELLOW}${BOLD}⚠${NC} Nessun coding agent rilevato sul sistema."
        echo ""
        echo "  Installa uno dei seguenti e ri-esegui questo script:"
        echo "    • Claude Code:   https://claude.ai/code"
        echo "    • OpenCode:      https://github.com/opencode-ai/opencode"
        echo "    • GitHub Copilot: https://github.com/features/copilot"
        echo "    • Cursor:        https://cursor.sh"
        echo "    • Windsurf:      https://codeium.com/windsurf"
        echo "    • Codex:         https://openai.com/codex"
        echo ""
        echo "  Per installazione locale usa: $0 --local"
    fi

    echo ""
    echo -e "${CYAN}${BOLD}Anubis Suite${NC} — .NET Code Review + DevOps Security. ${BOLD}Ready.${NC}"
}

main "$@"
