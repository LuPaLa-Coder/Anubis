# Anubis .NET Agent — Installation Guide

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
# Install only for a specific agent
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/install.sh | bash -s -- --agent claude
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/install.sh | bash -s -- --agent opencode
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/anubis/main/install.sh | bash -s -- --agent copilot

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
cp Anubis.agent.md ~/.claude/agents/
```

#### OpenCode
```bash
mkdir -p ~/.config/opencode/agents
# OpenCode uses its own agent registration; place the file and configure via opencode.json
cp Anubis.agent.md ~/.config/opencode/agents/anubis.md
```

#### GitHub Copilot
```bash
mkdir -p ~/.copilot/agents
cp Anubis.agent.md ~/.copilot/agents/
```

### 3. Clone or Copy Agent Directory

```bash
# Option A: Use the installer script
./install.sh

# Option B: Manual copy
cp -r docs/ ~/.claude/agents/anubis-docs/
```

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
