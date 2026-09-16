# Anubis Final Audit

Final hardening pass after the skills refactoring. The refactoring itself was
not redone: this pass addresses installation, reference integrity, the Quick
Pass contract, validation and regression.

## Scope

Reviewed and (where required) changed:

- `Anubis.agent.md`, `Anubis.devops.md` — operating contracts
- `references/`, `schemas/`, `examples/` — runtime knowledge and contracts
- `tests/` — regression, validation and installer tests
- `install.sh`, `uninstall.sh` — packaging and removal
- `README.md`, `docs/` — documentation

Out of scope: rewriting the architecture, renaming/removing rules, weakening
tests.

## Changes Made

| File | Change |
| --- | --- |
| `install.sh` | v1.2: packages `references/`, `schemas/`, `examples/` with the skills; idempotent copy; post-install verification (missing runtime file ⇒ non-zero exit); `--dest DIR` target; tarball fallback for `curl | bash`; `ANUBIS_SOURCE_DIR` test override. |
| `uninstall.sh` | (unchanged in this pass; package directories are removed by the installer's own `--uninstall` path, marker-guarded) |
| `Anubis.agent.md` | Deterministic `## Quick Pass` and `## Full Review` contracts; removed the `§7–§8` vs Findings/Handoff ambiguity; evidence mandatory in both modes. |
| `tests/validate.sh` | New: checks every file referenced by the two skills exists (brace-globs expanded) and validates the three schemas (valid JSON, `$schema`, resolvable `$ref`, meta-schema when `jsonschema` is present). |
| `tests/install_test.sh` | New: temporary-directory install, package/reference/schema checks, double install for idempotency, broken-source failure check. |
| `tests/regression.sh` | Gates 11–12 added: ANB rule families and delegation to `tests/validate.sh`. |
| `README.md` | `## Planned Agents` section; Anubis-Runtime/Arch/GreenOps explicitly labelled as planned, not implemented. |
| `docs/devops/installation.md`, `docs/devops/usage.md` | Replaced hardcoded `claude-3-5-sonnet` with provider-independent `<your-available-model>` and capability-based guidance. |
| `docs/usage.md` | Companion-agent note corrected (Anubis-devops implemented; Runtime/Arch planned). |
| `docs/refactoring-report.md` | Installer limitation removed; test counts updated; `## Final Verification` added. |
| `docs/final-audit-report.md` | New: this report. |

## Installer

`install.sh` now installs a complete package per detected agent directory:

```text
Anubis.agent.md · Anubis.devops.md · references/ · schemas/ · examples/
```

- Assets are copied with `cp -R` from a whole-directory list (`PACKAGE_ASSET_DIRS`),
  not a hardcoded filename list.
- Running the installer twice produces an identical tree (`rm -rf` + `cp -R`,
  marker `.anubis-package`).
- After installation `verify_installation` checks the agent files and the
  required runtime files; a missing/empty file makes the installer exit non-zero.
- Unmanaged pre-existing `references/`/`schemas/`/`examples/` directories are
  refused rather than overwritten.
- `--dest DIR` allows installing to an explicit directory for automation.

## Reference Validation

`tests/validate.sh` scans `Anubis.agent.md` and `Anubis.devops.md` for every
`references/…`, `schemas/…`, `examples/…` path, expands brace-globs
(e.g. `schemas/{finding,review,handoff}.schema.json`) and fails if any target is
missing. Result on the repository and on the freshly installed package:

```text
REFERENCE TEST: PASS
```

## Schema Validation

`tests/validate.sh` validates:

```text
schemas/finding.schema.json
schemas/review.schema.json
schemas/handoff.schema.json
```

Checks: valid JSON, `$schema` present, every local `$ref` (`#/$defs/…`)
resolvable, and `jsonschema.Draft202012Validator.check_schema` when the
`jsonschema` module is installed.

```text
SCHEMA TEST: PASS
```

## Skill Validation

- `Anubis.agent.md` remains the compact operating contract (Mission, Scope,
  Non-Scope, Operating Contract, Review Workflow, Evidence/Finding/Severity/
  Confidence/Remediation/Verification/Handoff/Output contracts, References).
- `Anubis.devops.md` remains the compact operating contract (Detection,
  Evidence, Rules, Finding, Remediation, Verification, Azure Policy, Score,
  Blocker, Handoff, Output).
- Quick Pass is now unambiguous (MUST list: scope, high-confidence findings,
  Finding Contract, severity + confidence, concise remediation, verification,
  handoff; may omit analysis; must not omit evidence).
- Full Review keeps every capability (scope, context, evidence, validated
  findings, severity, confidence, impact, root cause, remediation, verification,
  handoff).
- Both skills remain model/provider-independent (capability labels only).

## Rule Preservation

- `AZDO-SEC001`…`AZDO-SEC042`: 41/41 unique IDs present (Gate 5).
- `ANB-*` families present: `ANB-SEC` (12), `ANB-ARCH` (10), `ANB-PERF` (12),
  `ANB-DOTNET` (12), `ANB-EFCORE` (8), `ANB-TEST` (10), `ANB-BUILD` (9) (Gate 11).
- Legacy `AP-01`…`AP-09` MSBuild aliases preserved (Gate 6).
- No rule renamed or removed; `AZDO-SEC009` remains intentionally absent (never
  existed).

## Regression Tests

```text
$ bash tests/regression.sh
REGRESSION OK
  passed: 141   failed: 0
```

## Installer Tests

```text
$ bash tests/install_test.sh
INSTALLATION TEST: PASS
IDEMPOTENCY TEST: PASS
REFERENCE TEST: PASS
SCHEMA TEST: PASS
```

## Known Limitations

1. No automated LLM harness: `tests/anubis/*` and `tests/devops/*` remain
   specifications, not machine-executed assertions.
2. The exact install layout (assets copied next to the agent files) is a
   documented convention; platforms that require a different resolution
   strategy may need an adapter.
3. Anubis-Runtime / Anubis-Arch / Anubis-GreenOps are still roadmap items and
   are not implemented in this repository.
4. The `jsonschema` module is optional; without it meta-schema validation is
   limited to JSON validity and `$ref` resolution (structural checks still run).

## Final Status

PASS
