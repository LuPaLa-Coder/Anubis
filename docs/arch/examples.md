# Anubis-Arch Agent — Usage Examples

The full worked example (Input → Evidence → Finding → Severity →
Confidence → Remediation → Verification, plus a rejected false
positive) lives at [`../../examples/arch-review.md`](../../examples/arch-review.md).

It covers:
- `ARCH-LAYER-002` — an assembly dependency cycle between `Domain` and
  `Infrastructure`, with the NetArchTest rule used to verify the fix
- `ARCH-DEP-001` — version proliferation of a NuGet package across three
  projects despite Central Package Management
- A rejected `ARCH-LIC-001` candidate, where the SBOM confirms an MIT
  (non-copyleft) license

For behavioural test cases (expected findings/severity/confidence per
scenario), see `tests/arch/`.
