# Test — Anubis-devops / false positive

Purpose: prove DevOps patterns that match but whose context neutralises the risk
are rejected, and that secrets are never echoed.

## Input

```yaml
variables:
  - name: kvLinked
    value: ''                    # Linked from VG to Azure Key Vault
  - name: fromParam
    value: $(SecretFromKV)
  - name: fromMacro
    value: $[ variables.token ]

steps:
  - checkout: self
    persistCredentials: false

  - script: git describe --tags   # requires full history
    displayName: Reset password   # description only
  - checkout: self
    fetchDepth: 0

container:
  image: node:18-alpine
  options: --memory=2g
```

## Expected Findings

None. All candidates are documented false positives.

## Expected Non-Findings (rejected, with reason)

| Candidate | Reason |
| --- | --- |
| `AZDO-SEC001` on `kvLinked` | `value: ''` explicitly linked to Key Vault |
| `AZDO-SEC001` on `fromParam` | parameterised secret reference `$(...)` |
| `AZDO-SEC001` on `fromMacro` | macro syntax `$[...]`, safe variable reference |
| `AZDO-SEC003` on `persistCredentials: false` | explicit safe setting |
| `AZDO-SEC020` on `displayName: Reset password` | descriptive string, not an assignment |
| `AZDO-SEC029` on `fetchDepth: 0` | required by `git describe --tags` (documented) |

## Expected Severity

N/A (no findings).

## Expected Confidence

N/A.

## Expected Handoff

`none`. `summary.false_positives_rejected` must equal 6.

## Rule

A rule does not produce a finding when the documented false-positive context
applies. Secrets must never be echoed in the report — only the line and rule ID.
