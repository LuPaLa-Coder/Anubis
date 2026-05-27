# Anubis .NET Agent — Installation Guide

## Prerequisites

- **Copilot CLI** v0.1.0 or higher ([install here](https://github.com/github/copilot-cli))
- **Git** for cloning the agent repository
- **GitHub CLI** (`gh`) optional, for repository management
- **.NET 8 SDK** (optional, only if you want to validate samples locally)

## Installation Steps

### 1. Clone or Copy Agent Directory

**Option A: Clone the full Agents repository**
```bash
git clone https://github.com/your-org/GenAI.git
cd GenAI/Agents
```

**Option B: Copy just the Anubis agent**
```bash
# Download from your repository
curl -L https://raw.githubusercontent.com/your-org/GenAI/main/Agents/Anubis.agent.md -o ~/.copilot/agents/Anubis.agent.md
```

### 2. Verify Agent File

```bash
ls -la ~/.copilot/agents/ | grep Anubis

# Output should show:
# Anubis.agent.md
```

If the file is not present, ensure it was copied to the correct location:
```bash
mkdir -p ~/.copilot/agents
cp ./Anubis.agent.md ~/.copilot/agents/
```

### 3. Register Agent with Copilot CLI

Update your Copilot CLI configuration to recognize the agent:

```bash
# Edit or create ~/.copilot/config.json
cat >> ~/.copilot/config.json << 'EOF'
{
  "agents": {
    "Anubis": {
      "path": "~/.copilot/agents/Anubis.agent.md",
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
# Test that Anubis is available
copilot agent list

# Output should include:
# Anubis [enabled] - Anubis .NET Agent — review tecnica strutturata...

# Or invoke directly
copilot task Anubis --prompt "Review this C# code: [snippet]"
```

## Troubleshooting

### Agent not appearing in `copilot agent list`

1. Verify file exists: `cat ~/.copilot/agents/Anubis.agent.md | head -5`
2. Check config syntax: `copilot config validate`
3. Reload: `copilot config reload && copilot agent list`

### "Agent not found" or "Path not valid" error

- Ensure full path is used in config (not relative)
- Check file permissions: `ls -l ~/.copilot/agents/Anubis.agent.md`
- File must be readable by your user

### Agent loads but responds slowly

- First run may download model weights; wait 30-60 seconds
- Subsequent runs should be faster
- Check internet connectivity for model downloads

### Model compatibility error

Anubis.agent.md specifies `claude-3-5-sonnet` as default. If unavailable:
1. Edit `~/.copilot/agents/Anubis.agent.md` 
2. Change line 2: `#model: "claude-3-5-sonnet"` → `#model: "your-available-model"`
3. Reload: `copilot config reload`

## Next Steps

- Read [`usage.md`](usage.md) to understand the workflow
- Check [`examples.md`](examples.md) for real-world scenarios
- Review [Copilot CLI documentation](https://github.com/github/copilot-cli) for advanced features

## Support

If you encounter issues:
1. Check [Copilot CLI GitHub Issues](https://github.com/github/copilot-cli/issues)
2. Verify prerequisites are installed: `copilot --version`, `git --version`
3. Review agent manifest syntax in the [Copilot CLI docs](https://github.com/github/copilot-cli)
