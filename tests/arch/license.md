# Test — Anubis-Arch / license compliance

## Input

```text
SBOM excerpt:
  pkg:nuget/SomeGplLib@2.1.0   license: GPL-3.0-only
Product distribution model: closed-source, sold as a proprietary binary.
```

## Expected Findings

| ID | Title |
| --- | --- |
| `ARCH-LIC-001` | Copyleft license (GPL-3.0) in proprietary product |

## Expected Severity

- `ARCH-LIC-001` — `CRITICAL`

## Expected Confidence

- `ARCH-LIC-001` — `HIGH` (license and distribution model both
  confirmed, not inferred).

## Expected Handoff

`human` — legal review and license replacement/negotiation decision is
outside the agent's authority.

## Expected Non-Findings

- Must **not** report `ARCH-LIC-001` if the package is only referenced
  by a build-time/dev-only tool never distributed with the product
  (see false-positive test).
