# Test — Anubis-devops / pipeline

## Input

```yaml
pr:
  branches:
    include: ['*']            # public repo, no fork filter

extends:
  template: templates/security.yml@templates   # remote, not available locally

stages:
  - stage: Deploy
    jobs:
      - job: DeployProd
        steps:
          - script: |
              echo "${{ parameters.region }}"
              export PATH=$PATH:/custom/bin
              cd /tmp && ./deploy.sh
```

## Expected Findings

| ID | Title | Detect |
| --- | --- | --- |
| `AZDO-SEC038` | PR trigger from fork without filter | structural |
| `AZDO-SEC033` | Template parameter injection (`${{ parameters.region }}` in script) | structural |
| `AZDO-SEC017` | PATH manipulation | regex |
| `AZDO-SEC020` | Missing `displayName` / job metadata | structural |
| `AZDO-SEC024` | Missing job timeout | structural |

## Expected Review Status

`BLOCKED` (or `PARTIAL`) because `extends` references a remote template that is
not available locally. Report the blocker; do not infer the template's content.

## Expected Severity

- `AZDO-SEC038` — `HIGH`
- `AZDO-SEC033` — `CRITICAL`
- `AZDO-SEC017` — `HIGH`
- `AZDO-SEC020`, `AZDO-SEC024` — `MEDIUM`

## Expected Confidence

- `AZDO-SEC033`, `AZDO-SEC017` — `HIGH` (visible in YAML).
- `AZDO-SEC038` — `MEDIUM` (depends on repository visibility setting).
- Overall review confidence limited by the unresolved template → `PARTIAL` /
  `BLOCKED`.

## Expected Handoff

`target: human` — provide the remote template `templates/security.yml` and the
repository visibility setting to continue.

## Expected Non-Findings

- Do not emit findings attributed to the remote template; the review is blocked
  on it (guardrail: unavailable external template → `BLOCKED`, never infer).
- `export PATH=...` is flagged; a fully-qualified call is not.
