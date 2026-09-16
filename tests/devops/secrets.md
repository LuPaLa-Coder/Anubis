# Test — Anubis-devops / secrets

## Input

```yaml
variables:
  - name: dbPassword
    value: 'SuperSecret123!'
  - name: okFromKv
    value: ''            # From Azure Key Vault
  - name: apiToken
    value: $(SECRET_FROM_VG)

steps:
  - script: |
      echo "password=$(dbPassword)"
      echo "##vso[task.setvariable variable=sessionToken]$TOKEN"
    env:
      SYSTEM_ACCESSTOKEN: $(System.AccessToken)
```

## Expected Findings

| ID | Title |
| --- | --- |
| `AZDO-SEC001` | Secret hardcoded in YAML (`dbPassword`) |
| `AZDO-SEC008` | Secret written to log |
| `AZDO-SEC040` | `setvariable` without `issecret` |

## Expected Severity

- `AZDO-SEC001` — `CRITICAL`
- `AZDO-SEC008` — `CRITICAL`
- `AZDO-SEC040` — `MEDIUM`

## Expected Confidence

All `HIGH`.

## Expected Handoff

`target: anubis` if the connection string is also read by the application;
otherwise `none`.

## Expected Non-Findings

- `okFromKv` (`value: ''` with `# From Azure Key Vault`) → rejected false positive.
- `apiToken` (`value: $(SECRET_FROM_VG)`) → safe variable reference, no finding.
- `SYSTEM_ACCESSTOKEN` passed via `env:` → not an `AZDO-SEC034` finding (no log,
  no URL); this is the correct pattern.
