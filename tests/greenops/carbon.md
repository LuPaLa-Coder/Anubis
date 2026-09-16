# Test — Anubis-GreenOps / carbon footprint

## Input

```text
Resource: 10TB Blob Storage, redundancy: GRS (geo-redundant)
Data classification: dev/test fixtures, no resilience/RPO requirement documented.
Region: East US (emission factor 0.35 kg CO2e/kWh, indicative)
```

## Expected Findings

| ID | Title |
| --- | --- |
| `GRN-PROV-003` | Storage redundancy overkill (10TB dev/test data in GRS) |
| `GRN-CARBON-001` | Carbon footprint attributable to the 2x GRS allocation |

## Expected Severity

- `GRN-PROV-003` — `CRITICAL` (dev/test data in GRS, no resilience
  requirement documented)
- `GRN-CARBON-001` — `HIGH` (contributes a doubled allocation to the
  total footprint; not standalone extreme without the full breakdown)

## Expected Confidence

- `GRN-PROV-003` — `HIGH` (redundancy tier and data classification both
  confirmed).
- `GRN-CARBON-001` — `MEDIUM` (the carbon figure is a baseline estimate
  per `references/sustainability.md`'s indicative factors, not a
  Dashboard-validated number, until cross-checked).

## Expected Handoff

`anubis-devops` — the redundancy tier change is deployed through IaC.

## Expected Non-Findings

- Must **not** report `GRN-REGION-001` unless an alternative region is
  proposed and confirmed to meet the same constraints — this input gives
  no such alternative, so the candidate stays unconfirmed.
