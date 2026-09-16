# Example — Cloud sustainability review

Worked Full Review demonstrating the output shape:
Input · Evidence · Finding · Severity · Confidence · Remediation · Verification.

## Input

```bicep
// infra/main.bicep (excerpt)
resource devVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'vm-dev-catalog-01'
  location: 'eastus'
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4s_v3'   // 4 vCore
    }
  }
}
// no Microsoft.DevTestLab/schedules resource anywhere in the template
```

```text
# Azure Monitor, vm-dev-catalog-01, 30-day window
Avg CPU: 28%   Avg Memory: 22%   Uptime: 24/7 (no shutdown events)
Tags: environment=dev
```

## Evidence

- `main.bicep` provisions `vm-dev-catalog-01` at `Standard_D4s_v3` (4
  vCore), tagged `environment=dev`.
- No auto-shutdown schedule resource exists in the template or in the
  resource group.
- Azure Monitor confirms 24/7 uptime with 28% avg CPU, 22% avg memory
  over 30 days.

## Findings

### GRN-COST-001 — Missing auto-shutdown on dev VM — CRITICAL / HIGH

- **Evidence**: `vm-dev-catalog-01` tagged `environment=dev`, running
  24/7 with no shutdown schedule found in `main.bicep` or the resource
  group.
- **Impact**: assuming ~10h/weekday of actual dev usage, ~74% of the
  VM's runtime hours are pure waste — both cost and carbon.
- **Recommendation**: add an auto-shutdown schedule matching the team's
  working hours.
- **Fix**:
  ```bicep
  resource devVmSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
    name: 'shutdown-computevm-${devVm.name}'
    location: devVm.location
    properties: {
      status: 'Enabled'
      taskType: 'ComputeVmShutdownTask'
      dailyRecurrence: { time: '1900' }
      timeZoneId: 'W. Europe Standard Time'
      targetResourceId: devVm.id
    }
  }
  ```
- **Verification**: Azure Monitor confirms zero CPU activity outside
  07:00–19:00 for one full week post-deployment.

### GRN-PROV-001 — Over-provisioned dev VM (28% CPU avg on 4 vCore) — HIGH / HIGH

- **Evidence**: `Standard_D4s_v3` (4 vCore) at 28% avg CPU / 22% avg
  memory over a 30-day window.
- **Impact**: paying for capacity roughly 2× what the measured workload
  needs, compounding the waste already flagged by `GRN-COST-001`.
- **Recommendation**: downsize to a 2-vCore SKU sized to the measured
  usage.
- **Fix**: `vmSize: 'Standard_D2s_v3'`
- **Verification**: post-downsize CPU/memory re-measured over one week;
  stays below 60% avg with no throttling.

## Rejected candidate (false positive)

- Candidate: `GRN-PROV-003` (storage redundancy overkill) on the VM's
  OS disk. The disk is provisioned as `Standard_LRS`, not GRS/ZRS — the
  redundancy tier is already minimal for a dev resource. No finding
  emitted for `GRN-PROV-003`.

## Severity summary

| Severity | Count |
| --- | --- |
| CRITICAL | 1 |
| HIGH | 1 |
| MEDIUM | 0 |
| LOW | 0 |

False positives rejected: 1.

## Handoff

```yaml
handoff:
  target: anubis-devops
  reason: the auto-shutdown schedule and SKU change must be deployed through the existing IaC pipeline
  findings: [GRN-COST-001, GRN-PROV-001]
  files: [infra/main.bicep]
  required_context: [pipeline stage that deploys infra/, approval gate for non-prod changes]
  artifacts: [review report, updated Bicep snippet]
```
