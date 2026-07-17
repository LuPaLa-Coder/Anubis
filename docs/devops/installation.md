# Anubis-devops Agent — Installation Guide

## Prerequisites

- **Copilot CLI** v0.1.0 or higher ([install here](https://github.com/github/copilot-cli))
- **Azure DevOps account** access (for context only, no credentials needed from you)
- **Git** for cloning the agent repository
- **Azure CLI** (optional, for policy validation)

## Installation Steps

### 1. Clone or Copy Agent Directory

**Option A: Clone the full Agents repository**
```bash
git clone https://github.com/your-org/GenAI.git
cd GenAI/Agents
```

**Option B: Copy just the Anubis-devops agent**
```bash
curl -L https://raw.githubusercontent.com/your-org/GenAI/main/Agents/Anubis-devops.agent.md \
  -o ~/.copilot/agents/Anubis-devops.agent.md
```

### 2. Verify Agent File

```bash
ls -la ~/.copilot/agents/ | grep Anubis-devops

# Output should show:
# Anubis-devops.agent.md
```

If the file is not present:
```bash
mkdir -p ~/.copilot/agents
cp ./Anubis-devops.agent.md ~/.copilot/agents/
```

### 3. Register Agent with Copilot CLI

Update your Copilot CLI configuration:

```bash
# Edit or create ~/.copilot/config.json
cat >> ~/.copilot/config.json << 'EOF'
{
  "agents": {
    "Anubis-devops": {
      "path": "~/.copilot/agents/Anubis-devops.agent.md",
      "enabled": true,
      "model": "claude-3-5-sonnet"
    }
  }
}
EOF
```

Then reload Copilot CLI:
```bash
copilot config reload
```

### 4. Quick Test

```bash
# Verify Anubis-devops is available
copilot agent list | grep Anubis-devops

# Test invocation
copilot task Anubis-devops --prompt "Scan this pipeline for secrets..."
```

## Troubleshooting

### Agent not appearing in `copilot agent list`

1. Verify file exists: `cat ~/.copilot/agents/Anubis-devops.agent.md | head -5`
2. Check config syntax: `copilot config validate`
3. Reload: `copilot config reload && copilot agent list`

### "Agent not found" error

- Ensure full path is used (not relative)
- Check file permissions: `ls -l ~/.copilot/agents/Anubis-devops.agent.md`
- File must be readable

### Model compatibility error

If `claude-3-5-sonnet` is unavailable:
1. Edit `~/.copilot/agents/Anubis-devops.agent.md`
2. Change line 2: `#model: "claude-3-5-sonnet"` → `#model: "your-available-model"`
3. Reload: `copilot config reload`

### Very slow first run

- First execution may download model weights (30-60 seconds)
- Subsequent runs are faster
- Ensure stable internet connection

## Prerequisites Validation

Verify all prerequisites are met:

```bash
# Copilot CLI installed
copilot --version

# Git installed
git --version

# (Optional) Azure CLI for policy checks
az --version
```

## Next Steps

- Read [`usage.md`](usage.md) to learn the workflow
- Check [`examples.md`](examples.md) for real pipeline scenarios
- Review [Azure DevOps Security Best Practices](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/)

## Support

If you encounter issues:
1. Check [Copilot CLI GitHub Issues](https://github.com/github/copilot-cli/issues)
2. Review [Azure DevOps Pipelines Documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/)
3. Verify agent manifest in [Copilot CLI docs](https://github.com/github/copilot-cli)
