# Reference — Azure DevOps security rules

Rule catalogue for `Anubis-devops`. Every entry is a **candidate generator**;
apply Evidence First (`references/review-protocol.md`).

## Detection model

```text
STRUCTURAL PARSING FIRST
REGEX FALLBACK
```

Prefer structural YAML analysis (`variables[]`, `resources.repositories[]`,
`stages[*].jobs[*].steps[*]`, `container`, `pool`, `extends`) over text regex.
Regexes below are **fallback detection** for constructs that cannot be resolved
structurally (remote templates, runtime expressions, free-form scripts).

## ID preservation

The 41 rules keep their original IDs `AZDO-SEC001` … `AZDO-SEC042` verbatim.
`AZDO-SEC009` never existed (gap in the source) and is intentionally absent. The
source document claimed 42 rules but listed 41 (10 CRITICAL, 17 HIGH, 14 MEDIUM);
the accurate count is used here and the discrepancy is recorded in
`docs/refactoring-report.md`. The
canonical dashed alias (e.g. `AZDO-SEC-001`) is documented in
`docs/refactoring-report.md`; no ID is removed or renumbered. Each rule is
additionally tagged with a **family** (`SEC` | `IDENTITY` | `SUPPLY` | `PIPELINE` |
`SECRET`) used for grouping in reports.

## Rule index

| ID | Family | Severity | CWE | Detect | Title |
| --- | --- | --- | --- | --- | --- |
| `AZDO-SEC001` | SECRET | CRITICAL | CWE-798 | structural + regex | Secret hardcoded in YAML |
| `AZDO-SEC002` | SECRET | CRITICAL | CWE-200 | structural | Secrets in fork builds |
| `AZDO-SEC003` | SECRET | CRITICAL | CWE-522 | structural | Credential persistence |
| `AZDO-SEC004` | IDENTITY | CRITICAL | CWE-798 | external | Service Principal with secret |
| `AZDO-SEC005` | PIPELINE | CRITICAL | CWE-1188 | external | Classic pipeline in production |
| `AZDO-SEC006` | PIPELINE | CRITICAL | CWE-200 | external | Public project |
| `AZDO-SEC007` | IDENTITY | CRITICAL | CWE-269 | external | Agent with high privileges |
| `AZDO-SEC008` | SECRET | CRITICAL | CWE-532 | structural + regex | Secrets in logs |
| `AZDO-SEC033` | SUPPLY | CRITICAL | CWE-78, CWE-94 | structural | Template parameter injection |
| `AZDO-SEC034` | SECRET | CRITICAL | CWE-200 | regex | `System.AccessToken` exposed in script |
| `AZDO-SEC010` | SUPPLY | HIGH | CWE-1104 | structural + regex | Latest tag in image |
| `AZDO-SEC011` | IDENTITY | HIGH | CWE-269 | structural | Self-hosted in production |
| `AZDO-SEC012` | SUPPLY | HIGH | CWE-494 | structural | Template without commit hash |
| `AZDO-SEC013` | IDENTITY | HIGH | CWE-522 | external | No workload identity |
| `AZDO-SEC014` | IDENTITY | HIGH | CWE-269 | external | Service connection scope wide |
| `AZDO-SEC015` | PIPELINE | HIGH | CWE-20 | external | Variable settable at queue time |
| `AZDO-SEC016` | PIPELINE | HIGH | CWE-1357 | structural | No template validation |
| `AZDO-SEC017` | PIPELINE | HIGH | CWE-426 | regex | PATH manipulation |
| `AZDO-SEC018` | SUPPLY | HIGH | CWE-829 | external | Untrusted task installation |
| `AZDO-SEC019` | PIPELINE | HIGH | CWE-20 | structural | No input validation |
| `AZDO-SEC031` | SUPPLY | HIGH | CWE-798 | structural | NuGet API key long-lived |
| `AZDO-SEC032` | IDENTITY | HIGH | CWE-798 | regex | Entra app / SP with secret |
| `AZDO-SEC035` | IDENTITY | HIGH | CWE-269 | external | PAT with excessive scope |
| `AZDO-SEC036` | PIPELINE | HIGH | CWE-200 | structural | `system.debug=true` in production |
| `AZDO-SEC037` | PIPELINE | HIGH | CWE-732 | external | Missing CODEOWNERS / branch policy |
| `AZDO-SEC038` | PIPELINE | HIGH | CWE-285 | structural | PR trigger from fork without filter |
| `AZDO-SEC039` | PIPELINE | HIGH | CWE-269 | structural | Cross-project pipeline resource without approval |
| `AZDO-SEC020` | PIPELINE | MEDIUM | CWE-778 | structural | Missing `displayName` |
| `AZDO-SEC021` | SUPPLY | MEDIUM | CWE-400 | structural | Missing container resource limits |
| `AZDO-SEC022` | SUPPLY | MEDIUM | CWE-732 | structural | Writable container volumes |
| `AZDO-SEC023` | IDENTITY | MEDIUM | CWE-269 | external | Shared agent pool |
| `AZDO-SEC024` | PIPELINE | MEDIUM | CWE-400 | structural | Missing job timeout |
| `AZDO-SEC025` | PIPELINE | MEDIUM | CWE-1357 | structural | Inline script instead of template |
| `AZDO-SEC026` | PIPELINE | MEDIUM | CWE-755 | structural | Missing `continueOnError` policy |
| `AZDO-SEC027` | SUPPLY | MEDIUM | CWE-1104 | structural | Deprecated tasks |
| `AZDO-SEC028` | PIPELINE | MEDIUM | CWE-285 | structural | Missing condition on sensitive jobs |
| `AZDO-SEC029` | SUPPLY | MEDIUM | CWE-200 | structural | Checkout with full history |
| `AZDO-SEC030` | PIPELINE | MEDIUM | CWE-285 | external | Missing environment protection |
| `AZDO-SEC040` | SECRET | MEDIUM | CWE-200 | structural + regex | `setvariable` without `issecret` |
| `AZDO-SEC041` | IDENTITY | MEDIUM | CWE-1188 | external | Stale service connection |
| `AZDO-SEC042` | SUPPLY | MEDIUM | CWE-200 | structural | Artifact retention with secrets |

`Detect` legend: `structural` = YAML AST/first-class field; `regex` = fallback
only; `external` = requires Project/Organization settings or API (record as a
request or `BLOCKED`, never fabricate evidence).

## CRITICAL rules

| ID | Check | Evidence required | Exceptions / false positives | Remediation | Verification |
| --- | --- | --- | --- | --- | --- |
| `AZDO-SEC001` | Secret literal in `variables[].value` or `inputs` with a secret-ish key (`password`, `apikey`, `secret`, `connectionString`, `client_secret`, `token`), not `$()`/`$[]` | The literal key/line (mask the value) | Key Vault/VG reference `value: ''` with `# From Azure Key Vault`; parameterised `password: $(SecretFromKV)` | Variable Group linked to Key Vault | secret scanning; config review |
| `AZDO-SEC002` | `fork: true` combined with exposed secrets | the fork setting + the secret usage | none | Disable "Make secrets available to builds of forks" | Project/Pipeline settings review |
| `AZDO-SEC003` | `persistCredentials: true` | the checkout/step option | documented need for later authenticated step in same job | remove or `false` | pipeline validation |
| `AZDO-SEC004` | Service connection authenticating with a stored secret (`servicePrincipalKey`) | connection name + auth method (from settings) | none | Workload Identity Federation (OIDC) | connection config review |
| `AZDO-SEC005` | Non-YAML (Classic) pipeline in production | pipeline definition (external) | legacy pipelines under decommission documented | migrate to YAML + branch policies | pipeline inventory |
| `AZDO-SEC006` | `visibility: public` | project visibility | intentionally public OSS | set `private` | organization settings review |
| `AZDO-SEC007` | Agent pool with access to multiple projects | pool + project scope (external) | shared infra pool with least-privilege agent | dedicated pools per project | RBAC review |
| `AZDO-SEC008` | `echo $(secret)`, `Write-Host $(password)`, secret in log | the step/line | non-secret variable echoed | remove logging; `issecret: true` | log inspection |
| `AZDO-SEC033` | `${{ parameters.x }}` interpolated into `script:`/`bash:` without sanitisation | parameter definition + usage | parameter constrained by `values:` enum and used in a safe context | `values:` enum; avoid raw interpolation into shell | pipeline validation; injection test |
| `AZDO-SEC034` | `$(System.AccessToken)` in log or URL | the step/line | token passed via `env:` mapping, never logged/in URL | `env:` + `issecret`, never in URL | log inspection |

## HIGH rules

| ID | Check | Evidence required | Exceptions / false positives | Remediation | Verification |
| --- | --- | --- | --- | --- | --- |
| `AZDO-SEC010` | `:latest` or untagged image | the image reference | `:latest` appearing only in `condition:`/`displayName` | pin a specific version/digest | pipeline validation |
| `AZDO-SEC011` | `pool.name` not Microsoft-hosted, in production | pool declaration | documented need (private networking, resources) | Microsoft-hosted for public workloads | settings review |
| `AZDO-SEC012` | Remote template repo without immutable `ref` | `resources.repositories` entry | none | pin `refs/tags/...` or a commit SHA | dependency review |
| `AZDO-SEC013` | Service connection without OIDC | connection auth (external) | none | enable WIF | connection config review |
| `AZDO-SEC014` | ARM connection without resource-group scope | connection scope (external) | org-wide deployment by design, documented | scope to a dedicated resource group | RBAC review |
| `AZDO-SEC015` | Variables settable at queue time | pipeline settings (external) | intentionally parameterised values | enable "Limit variables that can be set at queue time" | settings review |
| `AZDO-SEC016` | No `extends` security template | pipeline root | documented alternative enforcement (decorators) | apply a base `extends` template | pipeline validation |
| `AZDO-SEC017` | `$PATH`/`$(PATH)` modified in a script | the script line | none | use fully-qualified paths | pipeline validation |
| `AZDO-SEC018` | Task from unvalidated marketplace | the task reference | approved/allow-listed publisher | disable marketplace task installation | org settings review |
| `AZDO-SEC019` | Script without input validation | script + runtime parameters | constant, internal-only input | typed runtime parameters | pipeline validation |
| `AZDO-SEC031` | Long-lived NuGet API key in push step | the push step + credential | none | Trusted Publisher on nuget.org + `NuGetAuthenticate@1` with WIF | supply-chain review |
| `AZDO-SEC032` | `client_secret` / `AZURE_CLIENT_SECRET` in pipeline | the variable/usage | none | Federated Identity Credential (OIDC) or Managed Identity | identity review |
| `AZDO-SEC035` | PAT with `Full access` or excessive scope | PAT metadata (external) | documented, short-lived admin PAT | minimal scope + expiry ≤ 90 days | identity audit |
| `AZDO-SEC036` | `system.debug` set in a production stage | the variable/stage | diagnostic job, documented | remove or scope to troubleshooting | pipeline validation |
| `AZDO-SEC037` | Missing CODEOWNERS / branch policy on the pipeline | repo policies (external) | none | require security-team review on pipeline changes | branch policy review |
| `AZDO-SEC038` | `pr: { branches: include: ['*'] }` on a public repo | the PR trigger | private repo with trusted contributors | limit branches; require `safe-to-test` label | settings review |
| `AZDO-SEC039` | Cross-project `pipelines:` resource triggering without approval | the resource declaration | non-production pipeline | add environment check/approval | pipeline validation |

## MEDIUM rules

| ID | Check | Evidence required | Exceptions / false positives | Remediation | Verification |
| --- | --- | --- | --- | --- | --- |
| `AZDO-SEC020` | Task/step without `displayName` | the step | generated/simple steps | add descriptive names | pipeline review |
| `AZDO-SEC021` | Container without memory/cpu limits | `container` block | ephemeral, tiny jobs | set appropriate limits | pipeline validation |
| `AZDO-SEC022` | Volume mount without `readOnly: true` | the mount | legitimately writable workspace | mark read-only when possible | pipeline review |
| `AZDO-SEC023` | Pool shared across projects | pool usage (external) | documented shared platform pool | dedicated pools | org settings review |
| `AZDO-SEC024` | Job without `timeoutInMinutes` | the job | intentionally unbounded, documented | set a timeout | pipeline validation |
| `AZDO-SEC025` | Inline script > ~50 lines | the step | one-off generated step | extract to a template | pipeline review |
| `AZDO-SEC026` | Critical step without explicit `continueOnError` | the step | default fail-on-error acceptable | set `continueOnError: false` explicitly | pipeline review |
| `AZDO-SEC027` | Deprecated task version | the task (`@N`) | none | upgrade to a supported version | dependency review |
| `AZDO-SEC028` | Sensitive deploy job without `condition` | the job | single-flow pipeline | add conditions/gates | pipeline review |
| `AZDO-SEC029` | `fetchDepth: 0` without need | the checkout | required by `git describe`/SBOM (documented) | `fetchDepth: 1` | pipeline validation |
| `AZDO-SEC030` | Environment without approvers | environment config (external) | non-production environment | configure approvals for production | environment review |
| `AZDO-SEC040` | `task.setvariable ... value` for sensitive data without `issecret=true` | the logging command | non-sensitive value | `issecret=true` | log inspection |
| `AZDO-SEC041` | Service connection unused > 90 days | connection usage (external) | planned reuse, documented | periodic audit; remove unused | identity audit |
| `AZDO-SEC042` | Artifact with config/secrets published | the publish step + artifact content | artifacts free of secrets | short retention; scrub before publish | artifact review |

## Known false positives

Do **not** flag these; if the pattern matches but the context justifies it,
record it as informational `LOW` instead of suppressing silently.

| Pattern | Reason |
| --- | --- |
| `value: ''` with `# From Azure Key Vault` / `# Linked from VG` | variable already linked to Key Vault |
| `displayName: 'Reset password'`, `description: 'Token rotation flow'` | descriptive strings, not value assignments |
| `password: $(SecretFromKV)`, `apikey: $[ variables.token ]` | safe variable references, not plaintext |
| `:latest` in `condition:` or `displayName` | not an image tag |
| `persistCredentials: false` (explicit) | confirmation of the fix, not a finding |
| `fetchDepth: 0` when `git describe`/SBOM explicitly requires it | documented necessity |

## Standard mapping

Every rule maps to CWE. Additional coverage:

- **OWASP Top 10 CI/CD**: CICD-SEC-1 (insufficient flow control), CICD-SEC-4
  (poisoned pipeline execution), CICD-SEC-6 (insufficient credential hygiene),
  CICD-SEC-7 (insecure system configuration).
- **NIST SSDF**: PO.5 (secure environments), PS.1 (protect code), PW.4 (reuse
  secure components).
- **SLSA**: Build L2/L3 (provenance, hermetic builds).
- **OSSF Scorecard**: Token-Permissions, Pinned-Dependencies, Branch-Protection.
- **CIS Microsoft Azure Foundations Benchmark v3**: DevOps section.

## Regex fallback catalogue

Use only when structural parsing is not possible. See
`references/azure-devops-rules.md` detection model.

```regex
# Secrets hardcoded (excludes ADO $() and $[])
(?im)^\s*(password|apikey|api_key|secret|connectionstring|client_secret|token):\s*['"]?(?!\$\(|\$\[)[^'"\s]+['"]?$

# Latest tag (image)
(?im)^\s*(image|container)\s*:\s*[\w./-]+:latest\b

# Credential persistence
(?im)persistCredentials\s*:\s*true\b

# Fork builds
(?im)fork\s*:\s*true\b

# Self-hosted pool (negative lookahead for Microsoft-hosted)
(?im)pool\s*:\s*\n\s*name\s*:\s*(?!Azure\s+Pipelines\b|Hosted\b)([^\s\n]+)

# Template without immutable ref
(?ims)repository\s*:\s*\w+\s*\n(?:\s+\w+\s*:[^\n]*\n)*?\s+(?!ref\s*:\s*refs/tags/|ref\s*:\s*[a-f0-9]{40})

# System.AccessToken in script or URL
(?im)\$\(System\.AccessToken\)

# Setvariable without issecret for suspicious names
(?im)task\.setvariable\s+variable\s*=\s*\w*(token|secret|key|password)\w*(?![^]]*issecret\s*=\s*true)

# Template parameter injection in shell script
(?im)^\s*(script|bash|pwsh|powershell)\s*:\s*\|?\s*\n[^\n]*\$\{\{\s*parameters\.\w+\s*\}\}
```

## YAML remediation examples

### Secret management (`AZDO-SEC001`)

```yaml
# ❌ WRONG - Secret in plaintext
variables:
  - name: dbPassword
    value: 'SuperSecret123!'

# ✅ CORRECT - Variable Group linked to Key Vault (Project Settings)
variables:
  - group: my-secure-variable-group  # Linked to Azure Key Vault
```

### Workload Identity (`AZDO-SEC004`, `AZDO-SEC013`, `AZDO-SEC032`)

> Service connections are **not** configured in YAML. They are Project Settings
> entities; YAML only references the connection name. WIF (OIDC) is enabled in
> the UI/REST API.

```yaml
# ❌ WRONG - Service Principal with client secret used in a script
variables:
  - name: AZURE_CLIENT_SECRET
    value: $(clientSecret)

steps:
  - script: |
      az login --service-principal \
        --username $(AZURE_CLIENT_ID) \
        --password $(AZURE_CLIENT_SECRET) \
        --tenant $(AZURE_TENANT_ID)

# ✅ CORRECT - Service connection with Workload Identity Federation
steps:
  - task: AzureCLI@2
    displayName: 'Deploy to Azure (WIF)'
    inputs:
      azureSubscription: 'my-wif-connection'   # WIF, no secret stored
      scriptType: bash
      scriptLocation: inlineScript
      inlineScript: |
        az account show

# ✅ ALTERNATIVE - Managed Identity for a self-hosted agent on VM/AKS
- task: AzureCLI@2
  inputs:
    azureSubscription: 'managed-identity-connection'
    scriptType: bash
    scriptLocation: inlineScript
    inlineScript: |
      az account show
```

### NuGet Trusted Publishing (`AZDO-SEC031`)

```yaml
# ❌ WRONG - Long-lived API key
- task: NuGetCommand@2
  inputs:
    command: push
    nuGetFeedType: external
    publishFeedCredentials: 'nuget-api-key'   # long-lived secret

# ✅ CORRECT - Trusted Publisher (on nuget.org) + WIF
steps:
  - task: NuGetAuthenticate@1
    displayName: 'Authenticate to NuGet (OIDC)'
    inputs:
      nuGetServiceConnections: 'nuget-org-trusted'
  - task: NuGetCommand@2
    inputs:
      command: push
      packagesToPush: '$(Build.ArtifactStagingDirectory)/*.nupkg'
      nuGetFeedType: external
      publishFeedCredentials: 'nuget-org-trusted'
```

### Container security (`AZDO-SEC010`, `AZDO-SEC021`, `AZDO-SEC022`)

```yaml
# ❌ WRONG
container: node:latest

# ✅ CORRECT
container:
  image: node:18-alpine@sha256:abc123...   # immutable digest
  options: --memory=2g --cpus=1

volumes:
  - volume: $(Agent.ToolsDirectory)/externals
    mountPath: /opt/externals
    readOnly: true
```

### Template security (`AZDO-SEC012`, `AZDO-SEC033`)

```yaml
# ❌ WRONG - Mutable template ref + parameter injection
resources:
  repositories:
    - repository: templates
      type: git
      name: Org/templates
      ref: refs/heads/main   # mutable

parameters:
  - name: scriptArg
    type: string

steps:
  - script: echo "${{ parameters.scriptArg }}"   # injection

# ✅ CORRECT - Immutable ref + typed parameters with values:
resources:
  repositories:
    - repository: templates
      type: git
      name: Org/templates
      ref: refs/tags/v1.2.3   # immutable tag or SHA

parameters:
  - name: environment
    type: string
    values:
      - dev
      - staging
      - prod

steps:
  - script: echo "Deploying to ${{ parameters.environment }}"
```

### System.AccessToken (`AZDO-SEC034`)

```yaml
# ❌ WRONG - Token in URL and log
- script: |
    git push https://$(System.AccessToken)@dev.azure.com/...
    echo "Token: $(System.AccessToken)"

# ✅ CORRECT - env mapping + issecret
- script: |
    git -c http.extraheader="Authorization: Bearer $SYSTEM_ACCESSTOKEN" push ...
  env:
    SYSTEM_ACCESSTOKEN: $(System.AccessToken)
```

### `setvariable` without `issecret` (`AZDO-SEC040`)

```yaml
# ❌ WRONG
- script: |
    TOKEN=$(curl -s https://idp/token | jq -r .access_token)
    echo "##vso[task.setvariable variable=apiToken]$TOKEN"

# ✅ CORRECT
- script: |
    TOKEN=$(curl -s https://idp/token | jq -r .access_token)
    echo "##vso[task.setvariable variable=apiToken;issecret=true]$TOKEN"
```
