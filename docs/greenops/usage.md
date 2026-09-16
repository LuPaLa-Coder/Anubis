# Anubis-GreenOps Agent — Usage Guide

## How to Invoke Anubis-GreenOps

### Via Claude Code

```bash
claude -p "Use Anubis-GreenOps to estimate carbon footprint and cost waste for this Bicep template..."
```

### Via OpenCode

```bash
opencode --agent anubis-greenops --prompt "Find over-provisioning and missing green patterns in this IaC..."
```

### Via GitHub Copilot Chat

```
@Anubis-GreenOps review this Terraform for cost and carbon waste
```

## Typical Workflow

### Step 1: Gather context

- Bicep/Terraform files for the resources under review
- Azure consumption/utilisation metrics for a representative window
  (Azure Monitor export or similar)
- ESG target or SLA constraints, if any

### Step 2: Invoke with the objective

```bash
claude -p "Use Anubis-GreenOps to:
- estimate the carbon footprint (GHG Protocol Scope 2/3)
- detect over-provisioning against measured utilisation
- flag missing green patterns (auto-shutdown, auto-scaling, RI/Spot, tiering)
- recommend a lower-emission region if constraints allow
IaC: infra/main.bicep · Metrics: <30-day Azure Monitor export>
"
```

### Step 3: Review the output

Findings carry severity, confidence, and impact in both $/year and kg
CO2e/year, with a concrete IaC fix and an ROI estimate. See
`examples/greenops-review.md` for a full worked example, including a
rejected false positive (a production resource whose configuration is
already justified by its SLA).

## Choosing Quick Pass vs Full Review

- **Quick Pass**: a single resource/cost question, fast triage.
- **Full Review** (default): full sustainability audit — carbon
  footprint, cost waste, over-provisioning, green patterns, regional
  strategy, ROI.

## Reference

- Pattern catalogue, GHG formula, emission factors:
  `references/sustainability.md`
- Shared protocol: `references/review-protocol.md`
