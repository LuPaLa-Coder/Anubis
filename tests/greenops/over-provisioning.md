# Test — Anubis-GreenOps / over-provisioning

## Input

```bicep
resource devVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'vm-dev-catalog-01'
  properties: { hardwareProfile: { vmSize: 'Standard_D4s_v3' } }
}
```

```text
Azure Monitor, 30-day window: Avg CPU 28%, Avg Memory 22%, Uptime 24/7,
no shutdown events, tags: environment=dev.
```

## Expected Findings

| ID | Title |
| --- | --- |
| `GRN-COST-001` | Missing auto-shutdown on dev VM |
| `GRN-PROV-001` | Over-provisioned dev VM (28% CPU avg on 4 vCore) |

## Expected Severity

- `GRN-COST-001` — `CRITICAL` (24/7 non-prod with no shutdown schedule)
- `GRN-PROV-001` — `HIGH` (waste in the 20–50% utilisation-gap range)

## Expected Confidence

- Both — `HIGH` (30-day Azure Monitor window, resource tags confirmed).

## Expected Handoff

`anubis-devops` — both fixes must be deployed through the existing IaC
pipeline.

## Expected Non-Findings

- Must **not** report `GRN-PROV-003` (storage redundancy overkill)
  unless the OS/data disk redundancy tier is actually GRS/ZRS — this
  input says nothing about the disk, so that candidate stays
  unconfirmed, not reported.
