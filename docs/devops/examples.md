# Anubis-devops Agent — Usage Examples

## Example 1: Hardcoded Secrets Detection (Happy Path)

### Input

```bash
copilot task Anubis-devops --prompt "
Pipeline Security Audit - Secrets Focus:

Organization: FinServ Corp
Project: Payment Processing
Pipeline: main-build-deploy
Compliance: PCI-DSS Level 1

YAML Pipeline:
---
trigger:
  - main

variables:
  buildConfig: 'Release'
  sqlConnection: 'Server=prod-db.database.windows.net;Database=Payments;User Id=sa;Password=P@ssw0rd123'
  apiKey: 'sk_live_51234567890abcdef'
  dockerRegistry: 'myregistry.azurecr.io'

pool:
  vmImage: 'ubuntu-latest'

stages:
- stage: Build
  jobs:
  - job: BuildJob
    steps:
    - task: DotNetCoreCLI@2
      inputs:
        command: 'build'
        arguments: '--configuration Release'
    
    - script: |
        dotnet publish -c Release
        echo \"Connection: \${{ variables.sqlConnection }}\"
        echo \"API Key: \${{ variables.apiKey }}\"
      displayName: 'Publish'

- stage: Deploy
  dependsOn: Build
  condition: succeeded()
  jobs:
  - deployment: DeployProd
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: SqlDacpacDeploymentOnMachineGroup@0
            inputs:
              dacpacFile: '\$(Pipeline.Workspace)/publish/*.dacpac'
              sqlUsername: 'sa'
              sqlPassword: 'P@ssw0rd123'
              serverName: 'prod-db.database.windows.net'
              databaseName: 'Payments'

Scope: Full security audit including secrets, compliance, and remediation
"
```

### Output

```
╔═════════════════════════════════════════════════════════════════╗
║      ANUBIS-DEVOPS PIPELINE SECURITY AUDIT — SECRETS FOCUS      ║
╚═════════════════════════════════════════════════════════════════╝

📊 AUDIT SUMMARY
├─ Organization: FinServ Corp
├─ Project: Payment Processing
├─ Pipeline: main-build-deploy
├─ Compliance Scope: PCI-DSS Level 1
├─ Total Issues: 5
└─ Status: 🔴 CRITICAL - PRODUCTION DEPLOYMENT BLOCKED

🔴 CRITICAL FINDINGS

[1/5] Hardcoded Database Password in Variables
├─ Severity: CRITICAL
├─ Location: azure-pipelines.yml:7
├─ Category: Secrets Exposure (CWE-798)
├─ Current:
│  variables:
│    sqlConnection: 'Server=prod-db.database.windows.net;User Id=sa;Password=P@ssw0rd123'
│
├─ Risk:
│  ✗ Password visible to all project members
│  ✗ Stored in git history (permanent leak)
│  ✗ Accessible via Azure Pipelines Web UI
│  ✗ Violates PCI-DSS Requirement 3.4 (Render credentials unreadable)
│
├─ Remediation (4 Steps):
│
│  Step 1: Rotate password immediately
│    az sql server ad-admin update --resource-group PaymentRG \
│      --server-name prod-db --display-name sql-admin
│
│  Step 2: Remove from git history (use BFG or filter-branch)
│    bfg --replace-text secrets.txt repo.git
│
│  Step 3: Create Azure KeyVault Secret Group
│    - Library → Variable Groups → New
│    - Name: production-database
│    - Link KV: your-kv-prod
│    - Add variable: sql-password (secret)
│
│  Step 4: Update pipeline YAML
│    variables:
│    - group: 'production-database'  # Links to KeyVault
│    - name: sqlConnection
│      value: 'Server=prod-db.database.windows.net;User Id=sa'
│    
│    Then reference in script:
│    - task: SqlDacpacDeploymentOnMachineGroup@0
│      inputs:
│        sqlPassword: \$(sql-password)  # From KeyVault

[2/5] Hardcoded API Key in Variables
├─ Severity: CRITICAL
├─ Location: azure-pipelines.yml:9
├─ Current: apiKey: 'sk_live_51234567890abcdef'
├─ Risk: Live production key accessible to all members
├─ Remediation:
│  1. Rotate key immediately (revoke sk_live_51234567...)
│  2. Generate new key in API provider (Stripe, etc.)
│  3. Store in KeyVault
│  4. Reference via variable group:
│     
│     - group: 'production-secrets'
│     
│     Then use: \$(api-key) in scripts

[3/5] Secret Logged to Build Console
├─ Severity: CRITICAL
├─ Location: azure-pipelines.yml:21
├─ Current:
│  - script: |
│      echo \"Connection: \${{ variables.sqlConnection }}\"
│      echo \"API Key: \${{ variables.apiKey }}\"
│
├─ Risk:
│  ✗ Secrets appear in build logs (web accessible)
│  ✗ Logs retained per Azure Pipelines retention policy
│  ✗ Auditable to any user with pipeline view access
│
├─ Remediation:
│  1. Remove all echo statements of secrets
│  2. Use environment variables with masking:
│     
│     - script: |
│         # Safe: just build, don't echo secrets
│         dotnet publish -c Release
│       env:
│         SqlPassword: \$(sql-password)  # Masked in logs
│
│  3. Enable automatic secret masking:
│     - In Variable Groups, mark secret variables
│       (Azure Pipelines auto-masks them in logs)

🟠 HIGH PRIORITY FINDINGS

[4/5] Plaintext Password in SQL Task
├─ Severity: HIGH
├─ Location: azure-pipelines.yml:35
├─ Task: SqlDacpacDeploymentOnMachineGroup
├─ Issue: sqlPassword passed as plain string
├─ Remediation:
│  Instead of hardcoding, use:
│  
│  - task: SqlDacpacDeploymentOnMachineGroup@0
│    inputs:
│      sqlUsername: 'sa'
│      sqlPassword: \$(sql-password)  # From KeyVault variable group
│      authenticationMethod: 'sqlServerAuthentication'
│      serverName: 'prod-db.database.windows.net'

[5/5] Missing Credential Masking on Service Task
├─ Severity: HIGH
├─ Issue: Azure authentication logs may contain credentials
├─ Recommendation:
│  Ensure all tasks masking:
│  
│  - task: AzurePowerShell@5
│    inputs:
│      ScriptType: 'InlineScript'
│      Inline: 'Write-Host "Deployed"'
│      azureSubscription: 'Production-Subscription'
│      ScriptArguments: '-ResourceGroupName $(rg-name) -StorageKey $(storage-key)'
│    env:
│      SYSTEM_ACCESSTOKEN: \$(System.AccessToken)  # Explicitly masked

📊 COMPLIANCE ASSESSMENT

PCI-DSS Level 1:
├─ Requirement 3.4 (Render Credentials Unreadable)
│  └─ ❌ FAILED: Database password in plaintext YAML
│  └─ ❌ FAILED: API key exposed in logs
│  └─ ❌ FAILED: SQL password in task definition
│
├─ Requirement 6.2 (Security Features)
│  └─ ⚠️ PARTIAL: No audit of pipeline changes
│
├─ Requirement 8.2 (User Access)
│  └─ ⚠️ PARTIAL: All project members can see secrets

Remediation: All critical findings must be fixed BEFORE production deployment.

🔧 REMEDIATION ROADMAP

PHASE 1 - IMMEDIATE (Today, <1 hour)
☐ Rotate database password
☐ Rotate API key
☐ Remove credentials from git history
☐ Block commits with secrets (git pre-commit hook)

PHASE 2 - SHORT TERM (This Week, <4 hours)
☐ Create Azure KeyVault (if not exists)
☐ Store secrets in KeyVault
☐ Create Variable Groups linking KeyVault
☐ Update YAML to reference variable groups
☐ Test pipeline in Staging environment
☐ Remove all hardcoded secrets from YAML

PHASE 3 - MEDIUM TERM (This Sprint, <8 hours)
☐ Audit ALL pipelines in organization for hardcoded secrets
☐ Implement GitHub Advanced Security secret scanning
☐ Set up pre-commit hooks across all repos
☐ Document secrets management policy
☐ Train team on Azure KeyVault integration

PHASE 4 - LONG TERM (Next Quarter)
☐ Implement Azure Policy: \"Deny pipelines with hardcoded secrets\"
☐ Set up regular secret rotation (every 90 days)
☐ Audit pipeline log retention settings
☐ Implement pipeline change auditing

📝 IMPLEMENTATION GUIDE - Step by Step

1. Create Azure KeyVault (one-time)
   ```bash
   az keyvault create --name kv-paymentprod \
     --resource-group PaymentRG --enable-soft-delete true
   ```

2. Add secrets to KeyVault
   ```bash
   az keyvault secret set --vault-name kv-paymentprod \
     --name sql-password --value \"new-password-here\"
   
   az keyvault secret set --vault-name kv-paymentprod \
     --name api-key --value \"sk_live_newkey\"
   ```

3. Create Variable Group in Azure Pipelines
   - Project Settings → Pipelines → Library → Variable Groups
   - New Variable Group: \"production-database\"
   - Link Azure KeyVault
   - Add variable: sql-password (should show from KV)

4. Update azure-pipelines.yml
   ```yaml
   variables:
   - group: 'production-database'
   - group: 'production-secrets'
   - name: sqlServer
     value: 'prod-db.database.windows.net'
   
   steps:
   - script: |
       # Use variables from groups (auto-masked)
       sqlcmd -S \$(sqlServer) -U sa -P \$(sql-password) ...
     displayName: 'Deploy Database'
     env:
       SYSTEM_ACCESSTOKEN: \$(System.AccessToken)
   ```

5. Test in Staging
   ```bash
   # Re-run pipeline in Staging environment
   # Verify no secrets appear in logs
   # Check Variable Group integration works
   ```

⚠️ GIT HISTORY CLEANUP

After removing secrets from YAML, clean git history:

```bash
# Option 1: BFG (recommended for large repos)
bfg --replace-text patterns.txt /path/to/repo.git

# Option 2: git filter-branch
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch aws_keys.txt' \
  --prune-empty --tag-name-filter cat -- --all

# Verify clean
git log --all -p | grep -i password

# Force push (warning: modifies history)
git push origin --force --all
```

🔄 HANDOFF RECOMMENDATION

**Consider Anubis for Application Code Review:**
- Review code that uses KeyVault
- Verify secrets rotation handling
- Check credential caching patterns
- Audit logging for secret-adjacent data

---
Generated by Anubis-devops Agent | Report Time: 2024-01-15T10:30:00Z
```

---

## Example 2: Compliance Validation (SOC 2 & PCI-DSS)

### Input

```bash
copilot task Anubis-devops --prompt "
Compliance Assessment:

Organization: HealthTech Inc
Project: Patient Records System
Pipeline: main-production-deploy
Compliance Requirements: SOC 2 Type II + HIPAA

Assess pipeline against:
1. Audit logging (deployment events)
2. Access control (approval gates)
3. Secrets protection (PII in logs)
4. Artifact integrity (signed releases)
5. Change management (audit trail)

YAML: [paste full pipeline YAML]
"
```

Output includes:
- Compliance scorecard (pass/fail per requirement)
- Missing controls (audit logging, approvals, signatures)
- Remediation steps with estimated effort
- Policy recommendations for organization-wide enforcement

---

## Example 3: Handoff to Anubis

After finding deployment code issues:

```bash
copilot task Anubis --prompt "
Based on Anubis-devops pipeline audit findings:

1. We're storing API keys in Azure KeyVault
2. Pipeline uses managed identity for deployment
3. Need to review:
   - Application KeyVault client implementation
   - Secret rotation handling
   - Error logging (no PII leakage)
   - Fallback strategies for missing secrets

Codebase: [describe your application code structure]
"
```

---

These examples show Anubis-devops detecting secrets, validating compliance, and providing concrete remediation with step-by-step guidance.
