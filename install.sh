#!/usr/bin/env bash
# =============================================================================
#  Anubis Agent Suite — Global Installer v1.3
#  Installa Anubis, Anubis-devops, Anubis-Arch, Anubis-Runtime e
#  Anubis-GreenOps per tutti i coding agent rilevati con frontmatter
#  nativo: Claude Code · OpenCode · GitHub Copilot · Cursor · Windsurf · Codex
#
#  Ogni installazione include gli agenti della suite (skill .md) più il
#  pacchetto runtime completo: references/ · schemas/ · examples/
#
#  Uso:
#    curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/install.sh | bash
#    ./install.sh                                  # installa tutta la suite
#    ./install.sh --suite anubis                    # solo Anubis (.NET)
#    ./install.sh --suite devops                     # solo Anubis-devops
#    ./install.sh --suite arch                       # solo Anubis-Arch
#    ./install.sh --suite runtime                    # solo Anubis-Runtime
#    ./install.sh --suite greenops                   # solo Anubis-GreenOps
#    ./install.sh --agent claude                    # solo per Claude Code
#    ./install.sh --local                          # installa nella directory corrente
#    ./install.sh --dest DIR                       # installa in una directory specifica
#    ./install.sh --backup                         # backup dei file esistenti
#    ./install.sh --uninstall                      # rimuove tutta la suite
# =============================================================================

set -euo pipefail

# ── Colori ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'   GREEN='\033[0;32m'   YELLOW='\033[1;33m'
CYAN='\033[0;36m'  BOLD='\033[1m'      NC='\033[0m'

# ── Configurazione ───────────────────────────────────────────────────────────
ANUBIS_VERSION="1.3.1"
REPO_URL="https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main"
REPO_TARBALL="https://github.com/LuPaLa-Coder/anubis/archive/refs/heads/main.tar.gz"

# Directory del pacchetto runtime copiate accanto agli agenti installati.
PACKAGE_ASSET_DIRS=("references" "schemas" "examples")

# File runtime la cui assenza è un errore fatale (installazione rotta).
REQUIRED_RUNTIME_FILES=(
    "references/review-protocol.md"
    "references/dotnet.md"
    "references/security.md"
    "references/architecture.md"
    "references/performance.md"
    "references/efcore.md"
    "references/testing.md"
    "references/msbuild.md"
    "references/azure-devops-rules.md"
    "references/architecture-governance.md"
    "references/netarchtest-rules.md"
    "references/sbom.md"
    "references/runtime-performance.md"
    "references/sustainability.md"
    "schemas/finding.schema.json"
    "schemas/review.schema.json"
    "schemas/handoff.schema.json"
)

# Marker che identifica una directory di pacchetto gestita da questo installer.
PACKAGE_MARKER=".anubis-package"

# Directory sorgente da cui copiare gli asset (checkout locale o tarball).
SOURCE_DIR=""
PACKAGE_TMP=""

# ── Cleanup ──────────────────────────────────────────────────────────────────
cleanup() {
    if [[ -n "${PACKAGE_TMP:-}" && -d "${PACKAGE_TMP:-}" ]]; then
        rm -rf "$PACKAGE_TMP"
    fi
}
trap cleanup EXIT

# ── Registro agenti della suite ──────────────────────────────────────────────
# Array paralleli indicizzati per posizione (compatibile bash 3.2 / macOS
# default): AGENT_IDS[i] descrive AGENT_FILE[i] / AGENT_SHORT_NAME[i] / ecc.
# Aggiungere un agente = aggiungere un elemento a ciascun array, nessun'altra
# modifica strutturale è richiesta altrove nello script.
AGENT_IDS=(anubis devops arch runtime greenops)

AGENT_FILE=(
    "Anubis.agent.md"
    "Anubis.devops.md"
    "Anubis.Arch.md"
    "Anubis.Runtime.md"
    "Anubis.GreenOps.md"
)

AGENT_SHORT_NAME=(
    "Anubis"
    "Anubis-devops"
    "Anubis-Arch"
    "Anubis-Runtime"
    "Anubis-GreenOps"
)

# Modello Claude per agente (allineato al campo model: dei sorgenti).
AGENT_MODEL=(
    "claude-opus-5-5"
    "claude-opus-5-5"
    "claude-opus-5-5"
    "claude-sonnet-5"
    "claude-sonnet-5"
)

# Nome file per OpenCode (lowercase, senza punti).
AGENT_OPENCODE_NAME=(
    "anubis"
    "anubis-devops"
    "anubis-arch"
    "anubis-runtime"
    "anubis-greenops"
)

# Descrizione completa usata nel frontmatter dell'agente installato.
AGENT_DESCRIPTION=(
    'Anubis .NET Agent — review tecnica strutturata di codice .NET con severity condivisa, refactoring concreti e handoff verso DevSecOps e delivery'
    'Anubis-devops Agent — analisi security di pipeline YAML Azure DevOps con severity condivisa, mapping CWE, remediation concrete (split YAML/Infra/Code), Security Score formalizzato e handoff verso Anubis'
    'Anubis-Arch Agent — governance architetturale .NET con NetArchTest rule generation, dependency graph analysis, license compliance e SBOM generation'
    'Anubis-Runtime Agent — analisi performance .NET con OpenTelemetry, N+1 detection, CRAP-Performance correlation e thread analysis'
    'Anubis-GreenOps Agent — analisi sostenibilità cloud e cost optimization per Azure con carbon footprint estimation, resource over-provisioning detection, green patterns'
)

# Descrizione breve usata in .claude/settings.json (installazione locale).
AGENT_SETTINGS_DESCRIPTION=(
    "Anubis .NET Agent — review tecnica strutturata di codice .NET"
    "Anubis-devops Agent — analisi security pipeline YAML Azure DevOps"
    "Anubis-Arch Agent — governance architetturale, dipendenze, licenze, SBOM"
    "Anubis-Runtime Agent — performance runtime .NET, OpenTelemetry, N+1, lock contention"
    "Anubis-GreenOps Agent — sostenibilità cloud Azure, carbon footprint, cost optimization"
)

# Cache del body per agente (indicizzata come AGENT_IDS).
_BODY_CACHE=()

# Risolve l'indice di un agent_type in AGENT_IDS. Stampa l'indice ed esce 0
# se trovato, altrimenti non stampa nulla ed esce 1.
agent_index() {
    local id="$1" i
    for i in "${!AGENT_IDS[@]}"; do
        if [[ "${AGENT_IDS[$i]}" == "$id" ]]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

# ── Banner ───────────────────────────────────────────────────────────────────
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "  ⚖️  Anubis Agent Suite — Global Installer v${ANUBIS_VERSION}"
    echo -e "${NC}"
    echo "  ● Anubis          — Senior Code Reviewer .NET 8+"
    echo "  ● Anubis-devops   — Azure DevOps Pipeline Security"
    echo "  ● Anubis-Arch     — Architecture Governance & Dependencies"
    echo "  ● Anubis-Runtime  — Runtime Performance & OpenTelemetry"
    echo "  ● Anubis-GreenOps — Cloud Sustainability & Cost Optimization"
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
# Argomenti: uno degli id in AGENT_IDS (anubis | devops | arch | runtime | greenops)

get_agent_body() {
    local agent_type="${1:-anubis}"
    local idx
    idx=$(agent_index "$agent_type") || {
        echo -e "${RED}✗${NC} Agent sconosciuto: $agent_type" >&2
        return 1
    }

    # Cache lookup
    if [[ -n "${_BODY_CACHE[$idx]:-}" ]]; then
        echo "${_BODY_CACHE[$idx]}"
        return 0
    fi

    local agent_filename="${AGENT_FILE[$idx]}"

    local src=""
    if [[ -n "${SOURCE_DIR:-}" && -f "$SOURCE_DIR/$agent_filename" ]]; then
        src="$SOURCE_DIR/$agent_filename"
    elif [[ -f "$SCRIPT_DIR/$agent_filename" ]]; then
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
    _BODY_CACHE[$idx]="$body"

    # Pulizia se è stato scaricato in tmp (non cancellare la sorgente locale).
    if [[ "$src" != "$SCRIPT_DIR/$agent_filename" ]] && \
       [[ -z "${SOURCE_DIR:-}" || "$src" != "$SOURCE_DIR/$agent_filename" ]]; then
        rm -f "$src"
    fi

    echo "$body"
}

# ── Sorgente del pacchetto (checkout locale o tarball) ───────────────────────
# Se lo script è eseguito da un checkout completo usa quello; altrimenti
# scarica il tarball del repository una sola volta e ne estrae gli asset.

fetch_package_source() {
    # Override esplicito (usato dai test per puntare a una sorgente controllata).
    if [[ -n "${ANUBIS_SOURCE_DIR:-}" ]]; then
        SOURCE_DIR="$ANUBIS_SOURCE_DIR"
        return 0
    fi

    if [[ -d "$SCRIPT_DIR/references" && -d "$SCRIPT_DIR/schemas" ]]; then
        SOURCE_DIR="$SCRIPT_DIR"
        return 0
    fi

    PACKAGE_TMP="$(mktemp -d)"
    local archive="$PACKAGE_TMP/anubis.tar.gz"

    if command -v curl &>/dev/null; then
        curl -fsSL "$REPO_TARBALL" -o "$archive" || {
            echo -e "${RED}✗${NC} Download del pacchetto fallito da ${REPO_TARBALL}" >&2
            return 1
        }
    elif command -v wget &>/dev/null; then
        wget -q "$REPO_TARBALL" -O "$archive" || {
            echo -e "${RED}✗${NC} Download del pacchetto fallito da ${REPO_TARBALL}" >&2
            return 1
        }
    else
        echo -e "${RED}✗${NC} Nessuno tra curl o wget disponibile. Installa curl e riprova." >&2
        return 1
    fi

    tar -xzf "$archive" -C "$PACKAGE_TMP" || {
        echo -e "${RED}✗${NC} Estrazione del pacchetto fallita" >&2
        return 1
    }

    local ref
    ref="$(find "$PACKAGE_TMP" -maxdepth 2 -type d -name references -print -quit 2>/dev/null)"
    if [[ -z "$ref" ]]; then
        echo -e "${RED}✗${NC} references/ non trovata nel pacchetto scaricato" >&2
        return 1
    fi
    SOURCE_DIR="$(dirname "$ref")"

    if [[ ! -d "$SOURCE_DIR/references" || ! -d "$SOURCE_DIR/schemas" ]]; then
        echo -e "${RED}✗${NC} Pacchetto scaricato incompleto" >&2
        return 1
    fi
    return 0
}

# ── Nome file agente per piattaforma ─────────────────────────────────────────
# OpenCode usa un filename lowercase senza punti.

agent_dest_filename() {
    local short_name="$1" platform="$2" filename="$3"
    if [[ "$platform" == "opencode" ]]; then
        echo "$(echo "$short_name" | tr '[:upper:]' '[:lower:]').md"
    else
        echo "$filename"
    fi
}

# ── Installa il pacchetto runtime (references/schemas/examples) ──────────────
# Copia whitelist per directory: gli asset sono condivisi e idempotenti.
# directory non gestita da noi viene rifiutata invece che sovrascritta.

install_package_assets() {
    local target_dir="$1"

    if [[ -z "${SOURCE_DIR:-}" || ! -d "$SOURCE_DIR/references" ]]; then
        echo -e "${RED}✗${NC} Sorgente del pacchetto non disponibile" >&2
        return 1
    fi

    local asset
    for asset in "${PACKAGE_ASSET_DIRS[@]}"; do
        [[ -d "$SOURCE_DIR/$asset" ]] || continue
        if [[ -e "$target_dir/$asset" && ! -f "$target_dir/$PACKAGE_MARKER" ]]; then
            echo -e "${RED}✗${NC} Directory non gestita già presente: $target_dir/$asset" >&2
            return 1
        fi
        rm -rf "$target_dir/$asset"
        cp -R "$SOURCE_DIR/$asset" "$target_dir/$asset" || {
            echo -e "${RED}✗${NC} Copia di $asset fallita in $target_dir" >&2
            return 1
        }
    done

    printf 'anubis-package v%s\n' "$ANUBIS_VERSION" > "$target_dir/$PACKAGE_MARKER"
    return 0
}

# ── Verifica post-installazione ──────────────────────────────────────────────
# Elenca <target_dir> [dest_filename...]: verifica gli agenti attesi e tutti i
# file runtime obbligatori. Ritorna 1 (installazione rotta) se manca qualcosa.

verify_installation() {
    local target_dir="$1"
    shift

    local missing=0 f
    for f in "$@"; do
        if [[ ! -s "$target_dir/$f" ]]; then
            echo -e "  ${RED}✗${NC} File agente mancante o vuoto: $f" >&2
            missing=1
        fi
    done
    for f in "${REQUIRED_RUNTIME_FILES[@]}"; do
        if [[ ! -s "$target_dir/$f" ]]; then
            echo -e "  ${RED}✗${NC} File runtime mancante o vuoto: $f" >&2
            missing=1
        fi
    done

    if [[ "$missing" -ne 0 ]]; then
        echo -e "  ${RED}✗${NC} Verifica installazione fallita in $target_dir" >&2
        return 1
    fi
    return 0
}

# ── Installa agenti + pacchetto runtime in una directory ─────────────────────
# install_dir <dir> <agent_name> <filter>

install_dir() {
    local target_dir="$1"
    local agent_name="$2"
    local agent_filter="${3:-all}"

    mkdir -p "$target_dir"
    local platform
    platform=$(get_platform "$agent_name")

    local expected=()
    local id idx
    for id in "${AGENT_IDS[@]}"; do
        [[ "$agent_filter" == "all" || "$agent_filter" == "$id" ]] || continue
        if install_one_agent "$target_dir" "$agent_name" "$id"; then
            idx=$(agent_index "$id")
            expected+=("$(agent_dest_filename "${AGENT_SHORT_NAME[$idx]}" "$platform" "${AGENT_FILE[$idx]}")")
        else
            return 1
        fi
    done

    install_package_assets "$target_dir" || return 1
    verify_installation "$target_dir" "${expected[@]}" || return 1
    return 0
}


# ── Frontmatter per piattaforma ──────────────────────────────────────────────

get_frontmatter() {
    local platform="$1"     # claude | opencode | generic
    local short_name="$2"   # Anubis | Anubis-devops
    local description="$3"  # descrizione specifica per l'agente
    local model="${4:-}"    # modello Claude (solo platform claude)

    case "$platform" in
        claude)
            echo "---"
            echo "name: ${short_name}"
            echo "description: \"${description}\""
            [[ -n "$model" ]] && echo "model: ${model}"
            echo "---"
            ;;
        generic)
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
# agent_type: uno degli id in AGENT_IDS (anubis | devops | arch | runtime | greenops)

install_one_agent() {
    local target_dir="$1"
    local agent_name="$2"       # es. "Claude Code"
    local agent_type="${3:-anubis}"
    local platform
    platform=$(get_platform "$agent_name")

    local idx
    idx=$(agent_index "$agent_type") || {
        echo -e "${RED}✗${NC} Agent sconosciuto: $agent_type" >&2
        return 1
    }

    local short_name="${AGENT_SHORT_NAME[$idx]}"
    local description="${AGENT_DESCRIPTION[$idx]}"
    local filename="${AGENT_FILE[$idx]}"
    local body
    body=$(get_agent_body "$agent_type") || return 1

    # Per OpenCode il filename segue convenzione lowercase senza punti
    local dest_filename="$filename"
    if [[ "$platform" == "opencode" ]]; then
        dest_filename="${AGENT_OPENCODE_NAME[$idx]}.md"
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
        get_frontmatter "$platform" "$short_name" "$description" "${AGENT_MODEL[$idx]}"
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

# ── Uninstall ────────────────────────────────────────────────────────────────
uninstall_agent() {
    local target_dir="$1"
    local agent_name="$2"
    local platform
    platform=$(get_platform "$agent_name")

    local id idx short_name dest
    for id in "${AGENT_IDS[@]}"; do
        idx=$(agent_index "$id")
        short_name="${AGENT_SHORT_NAME[$idx]}"
        dest="${target_dir}/${AGENT_FILE[$idx]}"
        if [[ "$platform" == "opencode" ]]; then
            dest="${target_dir}/${AGENT_OPENCODE_NAME[$idx]}.md"
        fi
        if [[ -f "$dest" ]]; then
            rm "$dest"
            echo -e "  ${GREEN}✓${NC} ${short_name} rimosso da ${BOLD}${agent_name}${NC}"
        else
            echo -e "  ${YELLOW}○${NC} Nessun ${short_name} presente per ${agent_name}"
        fi
    done

    # Rimuovi il pacchetto runtime, solo se è stato installato da noi (marker).
    if [[ -f "$target_dir/$PACKAGE_MARKER" ]]; then
        local asset
        for asset in "${PACKAGE_ASSET_DIRS[@]}"; do
            if [[ -e "$target_dir/$asset" ]]; then
                rm -rf "$target_dir/$asset"
                echo -e "  ${GREEN}✓${NC} Pacchetto $asset/ rimosso da ${BOLD}${agent_name}${NC}"
            fi
        done
        rm -f "$target_dir/$PACKAGE_MARKER"
    fi
}

# ── Local Install ────────────────────────────────────────────────────────────
install_local() {
    local local_dir="${1:-$PWD}"
    local dest_dir="${local_dir}/.claude/agents"
    local agent_filter="${2:-all}"

    mkdir -p "$dest_dir"

    if ! install_dir "$dest_dir" "Claude Code" "$agent_filter"; then
        echo -e "  ${RED}✗${NC} Installazione locale fallita in ${dest_dir}" >&2
        return 1
    fi
    echo -e "  ${GREEN}✓${NC} Pacchetto Anubis installato localmente (agenti + references/ + schemas/)"
    echo -e "          → ${dest_dir}"

    # Crea/aggiorna settings.json Claude Code con gli agenti installati
    local settings="${local_dir}/.claude/settings.json"
    if [[ ! -f "$settings" ]]; then
        local entries="" id idx first=true
        for id in "${AGENT_IDS[@]}"; do
            [[ "$agent_filter" == "all" || "$agent_filter" == "$id" ]] || continue
            idx=$(agent_index "$id")
            if [[ "$first" == "true" ]]; then first=false; else entries+=","; fi
            entries+=$'\n'"    \"${AGENT_SHORT_NAME[$idx]}\": {"
            entries+=$'\n'"      \"description\": \"${AGENT_SETTINGS_DESCRIPTION[$idx]}\","
            entries+=$'\n'"      \"path\": \".claude/agents/${AGENT_FILE[$idx]}\""
            entries+=$'\n'"    }"
        done
        printf '{\n  "agents": {%s\n  }\n}\n' "$entries" > "$settings"
        echo -e "  ${GREEN}✓${NC} Creato .claude/settings.json con registrazione agenti"
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
    echo "Uso: $0 [--local] [--dest DIR] [--agent <name>] [--suite <type>] [--backup] [--uninstall] [--help]"
    echo ""
    echo "Opzioni:"
    echo "  --local              Installa solo nella directory corrente"
    echo "  --dest <dir>         Installa in una directory specifica (per test/automazione)"
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
    echo "  anubis    — Anubis          — Senior Code Reviewer .NET 8+"
    echo "  devops    — Anubis-devops   — Azure DevOps Pipeline Security"
    echo "  arch      — Anubis-Arch     — Architecture Governance & Dependencies"
    echo "  runtime   — Anubis-Runtime  — Runtime Performance & OpenTelemetry"
    echo "  greenops  — Anubis-GreenOps — Cloud Sustainability & Cost Optimization"
    echo ""
    echo "Esempi:"
    echo "  $0                                   # Installa tutta la suite"
    echo "  $0 --suite devops                    # Solo Anubis-devops"
    echo "  $0 --suite arch                      # Solo Anubis-Arch"
    echo "  $0 --agent claude                    # Solo per Claude Code"
    echo "  $0 --suite anubis --local            # Solo Anubis in locale"
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    print_banner

    detect_os
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null || pwd)"

    local mode="install"
    local target_agent=""
    local suite_filter="all"    # anubis | devops | all
    local dest_dir=""
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
            --dest)
                dest_dir="${2:-}"
                if [[ -z "$dest_dir" ]]; then
                    echo -e "${RED}✗${NC} Specifica una directory: --dest <dir>"
                    exit 1
                fi
                mode="dest"
                shift 2
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

    # ── Sorgente del pacchetto runtime ───────────────────────────────────
    if [[ "$mode" == "local" || "$mode" == "dest" || "$mode" == "install" ]]; then
        if ! fetch_package_source; then
            echo -e "${RED}✗${NC} Impossibile preparare il pacchetto runtime (references/ · schemas/)."
            exit 1
        fi
    fi

    # ── Modalità: Dest (directory esplicita, per test/automazione) ───────
    if [[ "$mode" == "dest" ]]; then
        echo -e "${BOLD}Installazione in directory:${NC} ${dest_dir}"
        echo -e "  Sorgente pacchetto: ${SOURCE_DIR}"
        echo ""
        if install_dir "$dest_dir" "Generic" "$suite_filter"; then
            echo ""
            echo -e "${GREEN}${BOLD}✓${NC} Installazione completata e verificata in ${dest_dir}"
            exit 0
        else
            echo ""
            echo -e "${RED}${BOLD}✗${NC} Installazione fallita in ${dest_dir}"
            exit 1
        fi
    fi

    # ── Modalità: Local ──────────────────────────────────────────────────
    if [[ "$mode" == "local" ]]; then
        if [[ -n "$target_agent" ]]; then
            echo -e "${YELLOW}⚠${NC} --local e --agent sono mutualmente esclusivi."
        fi
        echo -e "${BOLD}Installazione locale di Anubis Suite${NC}"
        echo ""
        if ! install_local "$PWD" "$suite_filter"; then
            echo ""
            echo -e "${RED}${BOLD}✗${NC} Installazione locale fallita."
            exit 1
        fi
        echo ""
        echo -e "${GREEN}${BOLD}✓${NC} Installazione locale completata e verificata!"
        echo ""
        echo "  Agenti disponibili:"
        local id idx
        for id in "${AGENT_IDS[@]}"; do
            if [[ "$suite_filter" == "all" || "$suite_filter" == "$id" ]]; then
                idx=$(agent_index "$id")
                echo "    • ${AGENT_SHORT_NAME[$idx]}"
            fi
        done
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
    local failed=0

    while IFS='|' read -r dir name; do
        [[ -z "$dir" ]] && continue
        if install_dir "$dir" "$name" "$suite_filter"; then
            installed=$((installed + 1))
        else
            failed=$((failed + 1))
        fi
    done < <(get_agent_dirs "$target_agent")

    echo ""
    if [[ "$failed" -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓${NC} Completato: ${installed} directory installate e verificate, 0 fallite"
    else
        echo -e "${RED}${BOLD}✗${NC} Completato con errori: ${installed} installate, ${failed} fallite"
    fi

    if [[ -z "$target_agent" && $installed -eq 0 && $failed -eq 0 ]]; then
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
    echo -e "${CYAN}${BOLD}Anubis Suite${NC} — Code Review · DevOps Security · Architecture · Runtime · GreenOps. ${BOLD}Ready.${NC}"

    if [[ "$failed" -ne 0 ]]; then
        exit 1
    fi
}

main "$@"
