# Anubis-devops Agent — Usage Guide

## How to Invoke Anubis-devops

### Via Copilot CLI Command

```bash
# Interactive agent selection
copilot -agent

# Or direct invocation
copilot task Anubis-devops --prompt "Audit this pipeline..."

# With file input
copilot task Anubis-devops < azure-pipelines.yml

# With configuration override
copilot task Anubis-devops --model claude-3-5-sonnet --prompt "..."
```

### Via GitHub Copilot Chat (if available)

```
@Anubis-devops audit my Azure DevOps pipeline for security vulnerabilities
```

## Typical Workflow

### Step 1: Prepare Pipeline YAML

Gather the Azure DevOps pipeline YAML and relevant context:

```bash
# Export pipeline from Azure DevOps
az pipelines show --name "my-pipeline" --org https://dev.azure.com/myorg --project "myproject" | jq .yamlConfiguration

# Or manually copy YAML from Azure DevOps web interface
cat azure-pipelines.yml
```

### Step 2: Invoke Anubis-devops with Context

```bash
copilot task Anubis-devops --prompt "
Pipeline Security Audit:

Organization: MyOrg (Azure DevOps)
Project: E-commerce
Pipeline: Build & Deploy Production
Environments: Staging, Production
Compliance: SOC 2 Type II, PCI-DSS

YAML Pipeline:
---
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'
  azureSubscription: 'production-sub'
  apiKey: 'sk_live_abc123xyz...'  # ❌ SECRET!

stages:
- stage: Build
  displayName: 'Build Application'
  jobs:
  - job: BuildJob
    steps:
    - task: DotNetCoreCLI@2
      displayName: 'Restore NuGet packages'
      inputs:
        command: 'restore'
    
    - script: |
        echo 'API Key: '\${{ variables.apiKey }}  # ❌ LOGS SECRET
        dotnet build --configuration Release
      displayName: 'Build'

- stage: Deploy
  displayName: 'Deploy to Production'
  dependsOn: Build
  condition: succeeded()
  jobs:
  - deployment: ProdDeploy
    displayName: 'Production Deployment'
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureAppServiceDeploy@4
            inputs:
              azureSubscription: \$(azureSubscription)
              appName: 'myapp-prod'

Review Focus:
1. Secrets exposure (hardcoded, logged)
2. Repository access (fork builds, credential persistence)
3. Agent security (self-hosted pools, network access)
4. Artifact integrity (signing, provenance)
5. Compliance (SOC 2 logging, audit trails)
"
```

### Step 3: Review Findings

Anubis-devops returns structured security report:

```
📋 ANUBIS-DEVOPS PIPELINE SECURITY AUDIT

Organization: MyOrg | Project: E-commerce | Pipeline: Build & Deploy
Compliance: SOC 2, PCI-DSS

SEVERITY SUMMARY
├─ Critical: 1 (hardcoded secret)
├─ High: 2 (logging, credential persistence)
├─ Medium: 1 (agent security)
└─ Low: 0

KEY FINDINGS

[Critical] Hardcoded API Key in Pipeline
├─ Location: azure-pipelines.yml:10
├─ Issue: apiKey = 'sk_live_abc123xyz...' directly in YAML
├─ Risk: Secret visible in git history, accessible to all pipeline readers
├─ Remediation:
│   1. Delete from git history (git filter-branch / BFG)
│   2. Rotate key immediately
│   3. Move to Azure KeyVault:
│       
│       variables:
│       - group: 'production-secrets'  # Link secret group
│       
│   4. Reference in pipeline:
│       - script: 'echo API Key: \$(ApiKey)'
│          env:
│            ApiKey: \$(ApiKey)  # From KeyVault

[High] Secret Logged During Build
├─ Location: azure-pipelines.yml:24
├─ Issue: echo "API Key: \${{ variables.apiKey }}" logs secret to console
├─ Risk: Secret visible in build logs, accessible via web UI
├─ Remediation:
│   Remove logging of secrets:
│   - script: |
│       echo 'Building application...'
│       dotnet build --configuration Release
│     displayName: 'Build'

[High] No Credential Masking
├─ Issue: Azure CLI and Service Connections may log credentials
├─ Remediation: Enable credential masking in pipeline:
│   - task: AzureAppServiceDeploy@4
│     displayName: 'Deploy'
│     env:
│       SYSTEM_ACCESSTOKEN: \$(System.AccessToken)
│     inputs:
│       azureSubscription: \$(azureSubscription)
│       appName: 'myapp-prod'

[Medium] Self-Hosted Agents (If Used)
├─ Issue: Not visible in YAML, but check agent pool configuration
├─ Risk: Self-hosted agents bypass Microsoft security scanning
├─ Recommendation:
│   - Patch self-hosted agents monthly
│   - Run antivirus/EDR on agent machines
│   - Restrict network access (allowlist only)
│   - Rotate agent credentials quarterly

REMEDIATION ROADMAP

1. IMMEDIATE (Today)
   ☐ Rotate API key
   ☐ Remove secret from YAML
   ☐ Remove secret from git history
   ☐ Rebuild pipeline artifacts

2. SHORT TERM (This Week)
   ☐ Set up Azure KeyVault integration
   ☐ Create secret group in Azure Pipelines
   ☐ Link secret group to pipeline
   ☐ Test secret injection in non-prod

3. MEDIUM TERM (This Sprint)
   ☐ Audit all pipelines for hardcoded secrets
   ☐ Implement policy: \"No secrets in YAML\"
   ☐ Review all build logs for secret exposure
   ☐ Implement secret scanning in repo (GitHub Advanced Security)

AZURE POLICY RECOMMENDATIONS

To enforce secure pipelines organization-wide:

1. Enforce KeyVault for All Credentials
2. Block Hardcoded Secrets (Scanner)
3. Require Credential Masking
4. Enforce Artifact Signing
5. Mandate Repository Branch Protection

❓ COMPLIANCE NOTES

SOC 2 Type II:
├─ ✗ Hardcoded secrets violate CC6.1 (Logical Access)
├─ ✗ Unmasked logs violate CC7.2 (System Monitoring)
├─ ✓ Will comply after KeyVault integration

PCI-DSS:
├─ ✗ Current: Requirement 3.4 (Render PAN unreadable)
└─ ✓ After: Use KeyVault + masking

🔄 HANDOFF RECOMMENDATIONS

1. **Anubis** (Optional - Application Code Review)
   - Review application code for hardcoded secrets
   - Check credential usage in services
   - Validate KeyVault client implementation
   - **When**: After pipeline is fixed

2. **Anubis-GreenOps** (Optional - Cost Optimization)
   - Review pipeline resource usage
   - Optimize build agent sizing
   - Assess artifact storage costs
   - **When**: After security fixes are stable

---
Generated by Anubis-devops Agent | Report Time: 2024-01-15T10:30:00Z
```

### Step 4: Optional Handoff

If application code also needs review:

```bash
copilot task Anubis --prompt "
Based on pipeline security findings from Anubis-devops:
- We're moving secrets to Azure KeyVault
- Review application code for:
  1. KeyVault client usage patterns
  2. Secrets rotation handling
  3. Fallback for missing secrets
  4. Logging of secret-adjacent data
"
```

## Input Schema

### Minimal Input

```json
{
  "pipeline_yaml": "YAML content",
  "objective": "Find secrets / audit security / compliance check"
}
```

### Full Input (Recommended)

```json
{
  "organization": "MyOrg",
  "project": "E-commerce",
  "pipeline_name": "Build & Deploy Production",
  "yaml_content": "...",
  "context": {
    "environments": ["staging", "production"],
    "compliance": ["SOC 2", "PCI-DSS"],
    "ci_system": "Azure DevOps",
    "artifact_flow": "Build → Staging → Production",
    "service_connections": ["Azure subscription", "Docker registry"],
    "secrets_scope": ["API keys", "database passwords", "signing certificates"],
    "known_issues": ["Self-hosted agents in production", "Manual approvals not logged"]
  },
  "scan_depth": "comprehensive",
  "severity_threshold": "medium"
}
```

## Output Schema

```json
{
  "summary": {
    "organization": "MyOrg",
    "project": "E-commerce",
    "pipeline": "Build & Deploy Production",
    "scan_date": "2024-01-15T10:30:00Z",
    "total_issues": 4
  },
  "severity_distribution": {
    "critical": 1,
    "high": 2,
    "medium": 1,
    "low": 0
  },
  "vulnerabilities": [
    {
      "severity": "critical",
      "category": "secrets_exposure",
      "location": "azure-pipelines.yml:10",
      "issue": "Hardcoded API key",
      "recommendation": "Move to Azure KeyVault",
      "cis_benchmark": "CIS Azure 5.2",
      "remediation_steps": [
        "Rotate API key",
        "Remove from YAML",
        "Clean git history"
      ]
    }
  ],
  "remediation_plan": {
    "immediate": [ ... ],
    "short_term": [ ... ],
    "medium_term": [ ... ]
  },
  "azure_policy_recommendations": [ ... ],
  "compliance_assessment": {
    "SOC2": { "status": "non-compliant", "items": [...] },
    "PCI-DSS": { "status": "non-compliant", "items": [...] }
  },
  "handoff_recommendation": {
    "agent": "Anubis",
    "reason": "Review application KeyVault client implementation",
    "scope": ["secrets handling", "credential rotation", "error handling"]
  }
}
```

## Configuration Options

Edit `~/.copilot/agents/Anubis-devops.agent.md` to customize:

```yaml
# Model override
#model: "claude-3-5-sonnet"

# Compliance frameworks to check
# #compliance: "SOC2,PCI-DSS,ISO27001"

# Severity threshold (skip lower)
# #min_severity: "high"

# Scan depth
# #scan_depth: "comprehensive"  # or "quick", "deep"
```

Command-line overrides:

```bash
copilot task Anubis-devops \
  --model claude-3-5-sonnet \
  --prompt "..." \
  --config '{"min_severity": "high", "compliance": "SOC2,PCI-DSS"}'
```

## Best Practices

### ✅ DO

- **Provide full YAML content** — including all stages, jobs, tasks
- **Include context** — environments, compliance, service connections
- **Specify known issues** — helps Anubis-devops prioritize
- **Use Azure KeyVault** — for all secrets, not environment variables
- **Enable secret masking** — in all pipeline tasks
- **Review findings immediately** — secrets exposure is urgent

### ❌ DON'T

- **Omit sensitive data** — auditor needs to see actual secrets to find them
- **Audit outdated pipelines** — scan production pipelines regularly
- **Ignore critical findings** — secret exposure requires immediate rotation
- **Assume built-in masking** — verify each task explicitly masks output
- **Mix compliance frameworks** — prioritize based on your requirements

## Example Prompts

### Secrets & Credentials Audit
```
Pipeline Security Audit - Secrets Focus:

Azure DevOps Organization: MyOrg
Pipeline: main build
Compliance: PCI-DSS

Scan for:
- Hardcoded API keys, passwords, connection strings
- Secrets logged in build steps
- Credential persistence settings
- Service connection security

YAML: [paste pipeline YAML]
```

### Compliance Validation
```
Compliance Assessment:

Project: Healthcare Portal
Compliance Requirements: HIPAA, SOC 2
Pipeline: Build & Deploy

Validate pipeline against:
1. Logging of audit events (PHI protection)
2. Access control (deployment approvals)
3. Artifact integrity (signed releases)
4. Encryption in transit (secrets, artifacts)

YAML: [paste pipeline YAML]
```

### Agent Security Review
```
Agent Pool Security Review:

Organization: MyOrg
Pipeline: Production Deployment
Agent Pools: windows-agents (self-hosted), ubuntu-latest (Microsoft-hosted)

Audit:
- Agent patch levels and maintenance
- Network access restrictions
- Credential handling on self-hosted agents
- Build isolation and artifact access

Configuration: [describe agent pool setup]
```

## Limitations & Known Issues

- **Large YAML files** (>1000 lines): Split into multiple reviews
- **Complex variable expansion**: Some $() syntax may be missed; validate manually
- **Custom tasks**: Third-party tasks may have security issues not in YAML
- **Runtime secrets**: Secrets created at runtime (e.g., generated tokens) can't be detected statically

## Support & More Information

- [Azure DevOps Security Best Practices](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/)
- [CIS Azure Foundations Benchmark](https://www.cisecurity.org/benchmark/azure)
- [Azure KeyVault Integration](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups/)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
