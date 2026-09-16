# Reference — Cloud sustainability & cost

Pattern catalogue for `Anubis-GreenOps`. Families: `GRN-CARBON`,
`GRN-COST`, `GRN-PROV`, `GRN-REGION`, `GRN-PATTERN`. Evidence First
applies: a resource shape (e.g. "VM looks oversized") is a candidate
until confirmed against actual utilisation, pricing or emission data.

## Carbon footprint formula (GHG Protocol Scope 2)

```text
Emissions (kg CO2e) = kWh × Regional Emission Factor (kg CO2e/kWh)
```

Use the [Microsoft Emissions Impact Dashboard](https://www.microsoft.com/en-us/sustainability/emissions-impact-dashboard)
as the reference source for Azure emission factors per region (this
supersedes the retired Microsoft Sustainability Calculator). The factors
below are **indicative baselines**; validate against the Dashboard or a
current public source (IEA, Ember, regional grid data) before publishing
a number as authoritative.

**Breakdown minimum** for any `GRN-CARBON-*` estimation:
- Compute (VM, App Service): CPU-hours × emission factor
- Storage (Blob, Disk): GB stored × 0.015 kg CO2e/GB/year (baseline)
- Network (data transfer): GB transferred × emission factor
- Database (SQL, CosmosDB): DTU-hours × emission factor

### Emission factors by Azure region (kg CO2e/kWh, indicative)

| Region | Renewable % | Emission Factor |
| --- | --- | --- |
| West Europe (NL) | 70% | 0.15 |
| UK South | 50% | 0.25 |
| North Europe (IE) | 65% | 0.18 |
| Germany West Central | 80% | 0.10 |
| East US | 30% | 0.35 |
| West US 2 | 55% | 0.22 |

### Energy consumption by Azure service (baseline)

| Service | Metric | Energy (kWh) | Carbon (kg CO2e, West EU) |
| --- | --- | --- | --- |
| VM | 1 vCore-hour | 0.10 | 0.015 |
| App Service | 1 instance-hour | 0.05 | 0.008 |
| Blob Storage | 1 GB stored/month | 0.000002 | 0.0000003 |
| SQL Database | 1 DTU-hour | 0.0005 | 0.000075 |
| CosmosDB | 100 RU/s-hour | 0.001 | 0.00015 |

---

## GRN-CARBON-001 — Carbon footprint exceeds target / extreme total

- **Detection**: computed kg CO2e/year (using the formula above) exceeds
  a stated ESG target, or is extreme relative to the workload's expected
  scale with no target stated.
- **Evidence Required**: the full breakdown (compute/storage/network/
  database) and the computed total.
- **Typical Impact**: ESG compliance risk, regulatory exposure.
- **Possible Severity**: CRITICAL (no target defined, or breach
  confirmed) – HIGH (approaching a defined threshold).
- **False Positives**: figure computed from incomplete resource
  inventory (declare as `BLOCKED`/low confidence instead of reporting a
  number as final).
- **Remediation**: prioritise the largest breakdown contributor first
  (usually compute); see `GRN-PROV-*`/`GRN-REGION-001`.
- **Verification**: recompute after remediation; compare against target.

### Worked example — VM downsize

- Current: `Standard_D4s_v3` (4 vCore) 24/7 = 4 × 0.10 × 365 × 24 =
  35,040 kWh/year → 35,040 × 0.15 = **5,256 kg CO2e/year** (West EU)
- Refactored: `Standard_D2s_v3` (2 vCore) 24/7 = 17,520 kWh/year →
  **2,628 kg CO2e/year**
- Reduction: **2,628 kg CO2e/year (50%)**; cost savings ≈ 50% on compute

### Worked example — Storage redundancy

- Current: 10TB Blob GRS = 2× allocation → 10 × 1000 × 0.015 × 2 =
  **300 kg CO2e/year**
- Refactored: 10TB Blob LRS = 1× allocation → **150 kg CO2e/year**
- Reduction: **150 kg CO2e/year (50%)**; cost savings ≈ 50% on storage
  replication

## GRN-PROV-001 — Over-provisioned compute

- **Detection**: VM/App Service sized well above measured CPU/memory
  utilisation (e.g. `Standard_D4s_v3` at 30% CPU avg, 20% memory avg).
- **Evidence Required**: SKU, utilisation metrics over a representative
  window.
- **Typical Impact**: wasted cost and carbon proportional to unused
  capacity.
- **Possible Severity**: CRITICAL (waste > 50% of provisioned capacity) –
  HIGH (20–50%) – MEDIUM (5–20%).
- **False Positives**: capacity reserved for a known, scheduled peak not
  visible in the sampled window.
- **Remediation**: downsize to a SKU matching measured utilisation, or
  move to Burstable/serverless where applicable.
- **Verification**: post-downsize utilisation re-measured; no SLA
  regression.

## GRN-PROV-002 — Over-provisioned database

- **Detection**: SQL Database/CosmosDB provisioned tier or RU/s far
  above measured DTU/RU usage (e.g. Premium tier at 10% DTU avg).
- **Evidence Required**: tier/provisioned units, measured usage.
- **Typical Impact**: same as `GRN-PROV-001`, database-specific.
- **Possible Severity**: HIGH (waste 20–50%) – MEDIUM (5–20%).
- **Remediation**: downsize tier, or move to serverless/autoscale
  provisioning.
- **Verification**: usage re-measured after change; latency/throughput
  unaffected.

## GRN-PROV-003 — Storage redundancy overkill

- **Detection**: geo-redundant (GRS) or zone-redundant (ZRS) storage
  used for dev/test or non-critical data that does not require it.
- **Evidence Required**: the redundancy tier and the data's actual
  criticality/retention requirement.
- **Typical Impact**: ~2× storage cost/carbon for no corresponding
  resilience requirement.
- **Possible Severity**: CRITICAL (dev/test data in GRS) – HIGH
  (production data with a lower documented RPO/RTO requirement than GRS
  provides).
- **Remediation**: LRS for non-critical/dev data; reserve GRS/ZRS for
  data with a confirmed resilience requirement.
- **Verification**: redundancy tier confirmed changed; cost/carbon
  recomputed.

## GRN-COST-001 — Missing auto-shutdown on non-production resource

- **Detection**: VM/App Service running 24/7 with no auto-shutdown
  schedule, and the resource is dev/test/staging (not customer-facing
  production).
- **Evidence Required**: the resource, its environment tag/naming, and
  the absence of a shutdown schedule.
- **Typical Impact**: waste of 24×365 hours for a resource typically
  needed ~8–10h/weekday.
- **Possible Severity**: CRITICAL.
- **False Positives**: resource is production or otherwise requires
  continuous availability (documented SLA).
- **Remediation**: Azure Automation Runbooks or the built-in
  auto-shutdown policy on a schedule matching actual usage hours.
- **Verification**: schedule confirmed active; off-hours utilisation
  drops to zero.

## GRN-COST-002 — Missing auto-scaling on variable workload

- **Detection**: fixed instance count / SKU serving a workload with
  measured variable demand (peak/trough ratio ≥ 2×), no autoscale rule
  configured.
- **Evidence Required**: the demand curve and the absence of an
  autoscale rule.
- **Typical Impact**: capacity sized for peak paid for at trough.
- **Possible Severity**: HIGH.
- **Remediation**: Azure Monitor metric-based autoscale, or a
  serverless/consumption tier if the workload shape fits.
- **Verification**: autoscale rule active; cost re-measured over a full
  demand cycle.

## GRN-REGION-001 — High-emission region with a viable lower-emission alternative

- **Detection**: workload hosted in a region with a materially higher
  emission factor than an alternative Azure region that meets the same
  latency/compliance/data-residency constraints.
- **Evidence Required**: current region's emission factor, the
  alternative's, and confirmation the constraints (data residency,
  latency to users, compliance) are actually met by the alternative.
- **Typical Impact**: avoidable carbon at no functional cost.
- **Possible Severity**: HIGH.
- **False Positives**: data residency or compliance requirement pins the
  region; documented and non-negotiable.
- **Remediation**: migrate or place new capacity in the lower-emission
  region.
- **Verification**: recomputed carbon footprint post-migration.

## GRN-PATTERN-001 — No Reserved Instance / Spot adoption

- **Detection**: 24/7 stable compute with no Reserved Instance coverage,
  or flexible/interruptible workload with no Spot VM usage.
- **Evidence Required**: the workload's usage pattern (stable vs
  flexible) and current pricing model (pay-as-you-go).
- **Typical Impact**: paying on-demand price for a predictable or
  interruption-tolerant workload.
- **Possible Severity**: HIGH.
- **Remediation**: 1-year Reserved Instance for stable 24/7 compute;
  Spot VMs for interruption-tolerant/batch workloads.
- **Verification**: cost re-measured after commitment; no availability
  regression for the stable case.

## GRN-PATTERN-002 — No storage tiering

- **Detection**: data older than the access-pattern threshold (e.g.
  2 years) still in the Hot tier, with no lifecycle management policy.
- **Evidence Required**: the data age/access pattern and the absence of
  a lifecycle policy.
- **Typical Impact**: paying Hot-tier price for effectively archival
  data.
- **Possible Severity**: HIGH.
- **Remediation**: Azure Storage lifecycle management — Cool after ~30
  days of inactivity, Archive after ~90 days, per the data's actual
  access pattern.
- **Verification**: lifecycle policy active; cost re-measured after one
  full tiering cycle.
