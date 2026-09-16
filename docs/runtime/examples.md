# Anubis-Runtime Agent — Usage Examples

The full worked example (Input → Evidence → Finding → Severity →
Confidence → Remediation → Verification, plus a rejected false
positive) lives at [`../../examples/runtime-review.md`](../../examples/runtime-review.md).

It covers:
- `RT-N1-001` — an N+1 query confirmed by an OpenTelemetry trace excerpt
  (40 queries for one request), with the `Include()` fix and the
  expected trace shape after the fix
- A rejected `RT-MEM-003` candidate, where the measured allocation rate
  is far below the GC-pressure threshold

For behavioural test cases (expected findings/severity/confidence per
scenario), see `tests/runtime/`.
