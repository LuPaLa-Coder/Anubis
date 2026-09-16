# Anubis Agent Suite — Installation Guide

Covers all five skills: `Anubis`, `Anubis-devops`, `Anubis-Arch`,
`Anubis-Runtime`, `Anubis-GreenOps`. One installer, one runtime package.

## Prerequisites

- One of the supported coding agents: **Claude Code**, **OpenCode**, **GitHub Copilot**, **Cursor**, **Windsurf**, or **OpenAI Codex**
- **Git** for cloning the repository
- **.NET 8+ SDK** (optional, only if you want to validate samples locally)

## Quick Install (recommended)

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/install.sh | bash
```

This installs Anubis in all detected coding agents on your system.

### Selective install

```bash
# Install only for a specific coding tool
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/install.sh | bash -s -- --agent claude
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/install.sh | bash -s -- --agent opencode
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/install.sh | bash -s -- --agent copilot

# Install only one skill of the suite (anubis | devops | arch | runtime | greenops)
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/install.sh | bash -s -- --suite arch

# Local install (project-level .claude directory)
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/install.sh | bash -s -- --local

# With backup of existing configs
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/install.sh | bash -s -- --backup
```

## Manual Installation

### 1. Clone the repository

```bash
git clone https://github.com/LuPaLa-Coder/anubis.git
cd anubis
```

### 2. Install per platform

#### Claude Code
```bash
mkdir -p ~/.claude/agents
cp Anubis.agent.md Anubis.devops.md Anubis.Arch.md Anubis.Runtime.md Anubis.GreenOps.md ~/.claude/agents/
```

#### OpenCode
```bash
mkdir -p ~/.config/opencode/agents
# OpenCode uses its own agent registration; place the files (lowercase,
# no dots) and configure via opencode.json
cp Anubis.agent.md ~/.config/opencode/agents/anubis.md
cp Anubis.devops.md ~/.config/opencode/agents/anubis-devops.md
cp Anubis.Arch.md ~/.config/opencode/agents/anubis-arch.md
cp Anubis.Runtime.md ~/.config/opencode/agents/anubis-runtime.md
cp Anubis.GreenOps.md ~/.config/opencode/agents/anubis-greenops.md
```

#### GitHub Copilot
```bash
mkdir -p ~/.copilot/agents
cp Anubis.agent.md Anubis.devops.md Anubis.Arch.md Anubis.Runtime.md Anubis.GreenOps.md ~/.copilot/agents/
```

### 3. Install runtime package

The skills reference `references/` and `schemas/` at runtime, so those
directories must be installed next to the agent files.

```bash
# Option A: Use the installer (installs all 5 skills + references/ + schemas/ + examples/)
./install.sh

# Option B: Manual copy for a single agent directory
DEST=~/.claude/agents
mkdir -p "$DEST"
cp Anubis.agent.md Anubis.devops.md Anubis.Arch.md Anubis.Runtime.md Anubis.GreenOps.md "$DEST/"
cp -R references schemas examples "$DEST/"
```

The installer verifies that the agent files and all required runtime files are
present and fails if any is missing. Re-running it is safe (idempotent).

### 4. Quick Test

```bash
# Claude Code
claude -p "Use Anubis to review this C# code: ..."

# OpenCode
opencode --agent anubis

# GitHub Copilot
copilot task Anubis --prompt "Review this C# code: ..."
```

## Troubleshooting

### Agent not appearing in agent list

1. Verify file exists in the correct agent directory
2. Check agent registration in your coding tool's configuration
3. Restart the coding agent

### Agent loads but responds slowly

- First invocation may load model weights; subsequent runs are faster
- Check internet connectivity

## Next Steps

- Read [`usage.md`](usage.md) to understand the workflow
- Check [`examples.md`](examples.md) for real-world scenarios

## Support

If you encounter issues:
1. Open a [GitHub Issue](https://github.com/LuPaLa-Coder/anubis/issues)
2. Check that your coding agent is properly installed
