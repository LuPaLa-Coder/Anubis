# Anubis-Arch Agent — Usage Guide

## How to Invoke Anubis-Arch

### Via Claude Code

```bash
claude -p "Use Anubis-Arch to review the dependency graph and layering of this solution..."
```

### Via OpenCode

```bash
opencode --agent anubis-arch --prompt "Audit NuGet version drift and license compliance..."
```

### Via GitHub Copilot Chat

```
@Anubis-Arch review this solution for layer violations and dependency drift
```

## Typical Workflow

### Step 1: Gather context

- `.sln` / `.csproj` files, `Directory.Packages.props`
- The architecture blueprint (Clean, DDD, Onion, CQRS, Layered) if one is
  declared for the project
- License whitelist / compliance constraints, if any

### Step 2: Invoke with the objective

```bash
claude -p "Use Anubis-Arch to:
- detect the architecture pattern in use
- flag any layer violation or dependency cycle
- report NuGet version proliferation and license risk
- generate NetArchTest rules for anything flagged
Solution: MyApp.sln
"
```

### Step 3: Review the output

Anubis-Arch reports findings with the Finding Contract (severity +
confidence + evidence), generated NetArchTest rules ready to commit, and
an SBOM when requested. See `examples/arch-review.md` for a full worked
example, including a rejected false positive.

## Choosing Quick Pass vs Full Review

- **Quick Pass**: a single dependency/layering question, fast triage.
- **Full Review** (default): a full governance pass — architecture
  pattern detection, dependency drift, license compliance, SBOM,
  technical debt plan.

## Reference

- Pattern catalogue: `references/architecture-governance.md`
- NetArchTest checklist: `references/netarchtest-rules.md`
- SBOM checklist: `references/sbom.md`
- Shared protocol: `references/review-protocol.md`
