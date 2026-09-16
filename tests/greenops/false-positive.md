# Test — Anubis-GreenOps / false positive

Purpose: prove the review rejects candidates that match a pattern but
whose context neutralises the waste/footprint claim, and never emits
them as findings.

## Input

```bicep
resource prodVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'vm-prod-payments-01'
  properties: { hardwareProfile: { vmSize: 'Standard_D4s_v3' } }
}
resource prodVmSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  // no shutdown schedule attached — this is expected: production, 24/7 SLA
}
resource prodDisk 'Microsoft.Compute/disks@2023-04-02' = {
  properties: { sku: { name: 'Premium_ZRS' } }
  tags: { rpo: '15-minutes', slaTier: 'gold' }
}
```

```text
Azure Monitor, 30-day window: Avg CPU 71%, Avg Memory 68%, tags: environment=production.
```

## Expected Findings

None. Every candidate is a documented false positive.

## Expected Non-Findings (rejected candidates, with reason)

| Candidate | Reason for rejection |
| --- | --- |
| `GRN-COST-001` (missing auto-shutdown) on `vm-prod-payments-01` | production resource with a documented 24/7 SLA, not dev/test |
| `GRN-PROV-001` (over-provisioned) on `vm-prod-payments-01` | 71% avg CPU is within normal operating range for a 4-vCore SKU, not over-provisioned |
| `GRN-PROV-003` (redundancy overkill) on `prodDisk` (`Premium_ZRS`) | documented 15-minute RPO / gold SLA tier justifies the redundancy tier |

## Expected Severity

N/A (no findings).

## Expected Confidence

N/A.

## Expected Handoff

`none`. `summary.false_positives_rejected` must equal the number of
rejected candidates (3).

## Rule

`NO EVIDENCE = NO FINDING`. A resource shape that matches a waste
pattern but whose documented requirement (SLA, RPO, measured
utilisation) justifies it must be recorded as rejected, never promoted
to a finding and never silently dropped.
