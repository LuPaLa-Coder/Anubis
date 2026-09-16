# Test — Anubis-devops / identity

## Input

```yaml
pool:
  name: SelfHostedProdPool

steps:
  - script: |
      az login --service-principal \
        --username $(AZURE_CLIENT_ID) \
        --password $(AZURE_CLIENT_SECRET) \
        --tenant $(AZURE_TENANT_ID)

  - task: AzureCLI@2
    inputs:
      azureSubscription: 'arm-prod-connection'   # no OIDC, wide scope
      scriptType: bash
      scriptLocation: inlineScript
      inlineScript: az account show
```

## Expected Findings

| ID | Title | Detect |
| --- | --- | --- |
| `AZDO-SEC032` | Entra app / SP with secret (`AZURE_CLIENT_SECRET`) | regex |
| `AZDO-SEC011` | Self-hosted agent in production | structural |
| `AZDO-SEC013` | Service connection without workload identity | external |
| `AZDO-SEC014` | Service connection scope too wide | external |
| `AZDO-SEC023` | Shared agent pool (if evidence of multi-project use) | external |

## Expected Severity

- `AZDO-SEC032` — `HIGH`
- `AZDO-SEC011` — `HIGH`
- `AZDO-SEC013` — `HIGH`
- `AZDO-SEC014` — `HIGH`
- `AZDO-SEC023` — `MEDIUM`

## Expected Confidence

- `AZDO-SEC032`, `AZDO-SEC011` — `HIGH`.
- `AZDO-SEC013`, `AZDO-SEC014`, `AZDO-SEC023` — `LOW`/`MEDIUM` unless connection
  metadata is provided; if metadata is unavailable, the review is `PARTIAL`.

## Expected Handoff

`target: human` (service-connection and pool configuration require Project /
Organization settings).

## Expected Non-Findings

- Do not emit `AZDO-SEC004` (SP with stored secret) as a confirmed finding
  without evidence from the service-connection configuration; the YAML in itself
  only proves the *usage* pattern (`AZDO-SEC032`). Without metadata, record the
  configuration-dependent checks as `PARTIAL`.
