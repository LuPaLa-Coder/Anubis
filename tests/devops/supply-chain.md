# Test — Anubis-devops / supply-chain

## Input

```yaml
resources:
  repositories:
    - repository: templates
      type: git
      name: Org/templates
      ref: refs/heads/main          # mutable

container: node:latest

steps:
  - task: SomeMarketplaceTask@1
    inputs:
      command: run

  - task: NuGetCommand@2
    inputs:
      command: push
      publishFeedCredentials: 'nuget-api-key'

  - checkout: self
    fetchDepth: 0                   # full history
```

## Expected Findings

| ID | Title | Detect |
| --- | --- | --- |
| `AZDO-SEC012` | Template without immutable ref | structural |
| `AZDO-SEC010` | Latest tag in image | structural |
| `AZDO-SEC018` | Untrusted marketplace task | external |
| `AZDO-SEC031` | Long-lived NuGet API key | structural |
| `AZDO-SEC029` | Checkout with full history | structural |

## Expected Severity

- `AZDO-SEC012`, `AZDO-SEC010`, `AZDO-SEC018`, `AZDO-SEC031` — `HIGH`
- `AZDO-SEC029` — `MEDIUM`

## Expected Confidence

- `AZDO-SEC012`, `AZDO-SEC010`, `AZDO-SEC031`, `AZDO-SEC029` — `HIGH`.
- `AZDO-SEC018` — `MEDIUM` (task allow-list is an organization setting; `LOW` if
  not observable).

## Expected Handoff

`target: human` if the organization task allow-list cannot be observed;
otherwise `none`.

## Expected Non-Findings

- `:latest` inside a `displayName` or `condition` must not trigger `AZDO-SEC010`.
- `fetchDepth: 0` must be rejected as a false positive when `git describe` / SBOM
  generation explicitly requires full history (documented).
- Pin to `refs/tags/vX.Y.Z` (immutable) satisfies `AZDO-SEC012`; a mutable branch
  does not.
