# Anubis-GreenOps Agent — Usage Examples

The full worked example (Input → Evidence → Finding → Severity →
Confidence → Remediation → Verification, plus a rejected false
positive) lives at [`../../examples/greenops-review.md`](../../examples/greenops-review.md).

It covers:
- `GRN-COST-001` — a dev VM running 24/7 with no auto-shutdown schedule,
  with the Bicep fix (`Microsoft.DevTestLab/schedules`)
- `GRN-PROV-001` — the same VM over-provisioned against measured
  CPU/memory usage
- A rejected false-positive set on a production VM/disk, where the
  measured utilisation and documented SLA/RPO justify the configuration

For behavioural test cases (expected findings/severity/confidence per
scenario), see `tests/greenops/`.
