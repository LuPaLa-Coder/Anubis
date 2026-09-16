# Example — DevOps review

Worked Azure DevOps pipeline review. Input · Evidence · Finding · Severity ·
Confidence · Remediation · Verification · Security Score (secondary).

## Input

```yaml
# .azuredevops/azure-pipelines.yml
trigger:
  - main

pool:
  vmImage: ubuntu-latest

variables:
  - name: dbPassword
    value: 'SuperSecret123!'
  - name: nugetKey
    value: 'oy2abc123...'

steps:
  - checkout: self
    persistCredentials: true

  - script: |
      echo "Deploying..."
      echo "Token: $(System.AccessToken)"
      git push https://$(System.AccessToken)@dev.azure.com/org/proj/_git/repo
    displayName: Push artifacts

  - task: NuGetCommand@2
    inputs:
      command: push
      packagesToPush: '$(Build.ArtifactStagingDirectory)/*.nupkg'
      publishFeedCredentials: 'nuget-key'
```

## Evidence

- `azure-pipelines.yml:11-12` — literal `dbPassword` value.
- `azure-pipelines.yml:13-14` — literal `nugetKey` value.
- `azure-pipelines.yml:18` — `persistCredentials: true`.
- `azure-pipelines.yml:22` — `System.AccessToken` printed to the log and embedded in a URL.
- `azure-pipelines.yml:26-29` — long-lived NuGet API key credential.

## Findings

### AZDO-SEC001 — Secret hardcoded in YAML — CRITICAL / HIGH

- **Evidence**: `name: dbPassword` / `value: '***'` (masked) at line 11-12.
- **Impact**: DB credential committed to the repository and its history.
- **Fix**: link a Variable Group to Azure Key Vault and reference it:
  ```yaml
  variables:
    - group: app-secrets   # linked to Azure Key Vault
  ```
- **Verification**: secret scanning; configuration review. Manual review included
  because the value exists in git history.

### AZDO-SEC034 — `System.AccessToken` exposed in script — CRITICAL / HIGH

- **Evidence**: `echo "Token: $(System.AccessToken)"` and token in the push URL.
- **Impact**: pipeline token leaked to logs / process list.
- **Fix**:
  ```yaml
  - script: |
      git -c http.extraheader="Authorization: Bearer $SYSTEM_ACCESSTOKEN" push ...
    env:
      SYSTEM_ACCESSTOKEN: $(System.AccessToken)
  ```
- **Verification**: log inspection after rerun.

### AZDO-SEC003 — Credential persistence — CRITICAL / HIGH

- **Evidence**: `persistCredentials: true`.
- **Impact**: credentials remain available to later script steps.
- **Fix**: remove it or set `false`; authenticate per step.
- **Verification**: pipeline validation.

### AZDO-SEC031 — Long-lived NuGet API key — HIGH / HIGH

- **Evidence**: `publishFeedCredentials: 'nuget-key'` backed by the hardcoded key.
- **Impact**: long-lived credential leaking through marketplace/pipeline.
- **Fix**: Trusted Publisher on nuget.org + `NuGetAuthenticate@1` with WIF.
- **Verification**: supply-chain review; rotate/revoke the key.

### AZDO-SEC020 — Missing `displayName` on the NuGet step — MEDIUM / MEDIUM

- **Evidence**: `NuGetCommand@2` task without `displayName`.
- **Impact**: weaker audit trail.
- **Fix**: add a descriptive `displayName`.
- **Verification**: pipeline review.

## Rejected candidate (false positive)

- Candidate: `AZDO-SEC008` (secret in log) on the `displayName: Push artifacts`
  line, which the regex flagged because it contains the word "artifacts".
- The evidence shows a display string, not a value assignment; the documented
  false-positive catalogue ("descriptive strings, not value assignments")
  applies. Rejected, no finding.

## Severity summary

| Severity | Count |
| --- | --- |
| CRITICAL | 3 |
| HIGH | 1 |
| MEDIUM | 1 |
| LOW | 0 |

False positives rejected: 1.

## Remediation split

- **YAML fix**: remove `persistCredentials`, remove token from log/URL, add
  `displayName`, replace NuGet credential.
- **Infrastructure fix**: create the Key Vault-backed Variable Group; register
  the pipeline as a NuGet Trusted Publisher.
- **Code or config fix**: remove `ConnectionStrings` from `appsettings.json` if
  the application also reads it.

## Security Score (secondary)

```
score = max(0, 100 − (3×20 + 1×10 + 1×3 + 0×1)) = 100 − 73 = 27/100
```
Band: **Critical** — not deployable to production. Secondary metric only; the
findings above are the primary report.

## Handoff

```yaml
handoff:
  target: anubis
  reason: AZDO-SEC001 requires reviewing how the .NET app reads the connection string
  findings: [AZDO-SEC001]
  files: [azure-pipelines.yml, appsettings.json]
  required_context: [configuration binding, secret usage in the app]
  artifacts: [pipeline security report, remediation split]
```
