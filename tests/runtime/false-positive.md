# Test — Anubis-Runtime / false positive

Purpose: prove the review rejects candidates that match a pattern in
source but lack the runtime evidence required to become a finding.

## Input

```csharp
// Batch job, runs once nightly, processes ~200 known rows.
foreach (var region in _knownRegions)   // fixed list of 6 regions
{
    var stats = await _db.RegionStats
        .Where(r => r.RegionId == region.Id)
        .FirstOrDefaultAsync();
    Publish(stats);
}
```

```text
No OpenTelemetry trace attached for this code path — request is out of
scope for the current review (batch job with no HTTP-facing trace).
```

## Expected Findings

None. Every candidate is a documented false positive/insufficient
evidence rejection.

## Expected Non-Findings (rejected candidates, with reason)

| Candidate | Reason for rejection |
| --- | --- |
| `RT-N1-001` on the `foreach` + query loop | no trace/profiler evidence attached; the static shape alone is `ANB-EFCORE-001`'s territory, not `RT-N1-001` — and even that is borderline given the fixed, small (6-item) collection |
| `RT-MEM-003` (GC pressure) | no allocation-rate measurement provided; cannot confirm a threshold is exceeded |

## Expected Severity

N/A (no findings).

## Expected Confidence

N/A.

## Expected Handoff

`human` if a runtime-confirmed answer is required for this code path
(request the trace); otherwise `none` with the candidates recorded as
rejected for insufficient evidence.

## Rule

`NO EVIDENCE = NO FINDING`. For `Anubis-Runtime` specifically: a pattern
visible only in source, with no trace/metric/profiler corroboration, is
never promoted to an `RT-*` finding — it is either rejected outright or
left to `Anubis`'s static reference pages.
