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

A follow-up pass (see **Extended Agents** below) applied the same
architecture — operating contract + `references/` + shared protocol +
schemas + examples + tests + installer integration — to
`Anubis.Arch.md`, `Anubis.Runtime.md` and `Anubis.GreenOps.md`, which
were previously monolithic and roadmap-only.

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

1. No automated LLM harness: `tests/anubis/*`, `tests/devops/*`,
   `tests/arch/*`, `tests/runtime/*` and `tests/greenops/*` remain
   specifications, not machine-executed assertions.
2. The exact install layout (assets copied next to the agent files) is a
   documented convention; platforms that require a different resolution
   strategy may need an adapter.
3. The `jsonschema` module is optional; without it meta-schema validation is
   limited to JSON validity and `$ref` resolution (structural checks still run).
4. `Anubis-azure` (Azure subscription security audit), referenced only as a
   handoff/interoperability target by the other five skills, is not
   implemented in this repository.

## Extended Agents (Arch / Runtime / GreenOps)

Follow-up pass bringing `Anubis-Arch`, `Anubis-Runtime` and
`Anubis-GreenOps` to the same operating-contract architecture as
`Anubis`/`Anubis-devops`. Full detail in
`docs/refactoring-report.md` → `## Extended Agents`.

### Changes Made

| File | Change |
| --- | --- |
| `references/review-protocol.md` | Now normative for all 5 skills; added `ARCH-*`/`RT-*`/`GRN-*` ID families (§11); added the shared Agent Interoperability Matrix (§13), replacing three near-identical copies previously embedded per skill. |
| `schemas/finding.schema.json`, `schemas/handoff.schema.json`, `schemas/review.schema.json` | `id` pattern extended to `ARCH\|RT\|GRN`; `category` enum extended (`dependency`, `license`, `sbom`, `concurrency`, `memory`, `runtime`, `sustainability`, `cost`); `handoff.target` enum extended with `anubis-arch`, `anubis-runtime`, `anubis-greenops`. |
| `Anubis.Arch.md`, `Anubis.Runtime.md`, `Anubis.GreenOps.md` | Rewritten as operating contracts (~200–211 lines each; previously 543–597), each with `Mission/Scope/Non-Scope/Operating Contract/Review Workflow/Evidence Contract/Finding Contract/Severity/Confidence/Remediation/Verification/Handoff/Output Contract/References`. `BLOCKER` removed from severity tables (now a review status); `Confidence` introduced; hardcoded LLM model tables (`Claude Sonnet 4.6`, `GPT-5.x`, `Gemini 3 Pro`, …) removed in favour of capability labels. |
| `references/architecture-governance.md`, `references/netarchtest-rules.md`, `references/sbom.md` | New — `ARCH-LAYER`/`ARCH-DEP`/`ARCH-LIC`/`ARCH-DEBT` pattern catalogue, NetArchTest checklist + worked example, SBOM checklist + worked example. |
| `references/runtime-performance.md` | New — `RT-N1`/`RT-ASYNC`/`RT-LOCK`/`RT-MEM`/`RT-CRAP` pattern catalogue; explicit overlap rule against `ANB-PERF-*`/`ANB-EFCORE-*` (an `RT-*` id requires runtime evidence, not just the static shape); CRAP formula reused from `references/testing.md`, not duplicated. |
| `references/sustainability.md` | New — `GRN-CARBON`/`GRN-COST`/`GRN-PROV`/`GRN-REGION`/`GRN-PATTERN` pattern catalogue, GHG Protocol formula, regional emission factors, worked carbon-impact examples. |
| `examples/arch-review.md`, `examples/runtime-review.md`, `examples/greenops-review.md` | New — worked Full Reviews, each including a rejected false positive. |
| `tests/arch/*`, `tests/runtime/*`, `tests/greenops/*` | New — 11 behavioural test files (3–4 per agent, including a `false-positive.md` per agent). |
| `install.sh` | v1.3: agent registry generalised from two hardcoded agents to a declarative array (`AGENT_IDS` + parallel `AGENT_FILE`/`AGENT_SHORT_NAME`/`AGENT_DESCRIPTION`/`AGENT_OPENCODE_NAME`/`AGENT_SETTINGS_DESCRIPTION`), bash-3.2-compatible (indexed arrays only, no associative arrays / namerefs); `get_agent_body`, `install_one_agent`, `install_dir`, `uninstall_agent` all loop over the registry instead of two copy-pasted branches; `.claude/settings.json` generated dynamically for whichever agents were installed; `--suite` accepts `arch`/`runtime`/`greenops`; `REQUIRED_RUNTIME_FILES` extended with the 5 new reference files. |
| `tests/validate.sh` | `SKILL_FILES` extended to all 5 skill files. |
| `tests/regression.sh` | Gates 2–4 now loop over all 5 skills; Gate 8 extended to the 3 new skills; new Gate 13 (`ARCH-*`/`RT-*`/`GRN-*` id-count thresholds) and Gate 14 (no hardcoded LLM model name, all 5 skills). |
| `tests/install_test.sh` | `REQUIRED_FILES` and the broken-source fixture extended to all 5 skills + 5 new references. |
| `README.md` | Skill table, architecture tree, References table, Tests/Handoff/Quick Start sections extended to 5 skills; `## Planned Agents` replaced with `## Agent Suite` (all ✅ implemented); `Anubis-azure` explicitly named as the one sibling agent still absent from this repository. |
| `docs/installation.md` | Manual-install `cp` examples extended to all 5 skill files; `--suite` documented alongside `--agent`. |
| `docs/arch/`, `docs/runtime/`, `docs/greenops/` | New — `usage.md` (concise, mirrors `docs/usage.md`'s invocation style), `installation.md` (pointer to the unified installer, no duplication), `examples.md` (pointer to the worked `examples/*.md`). |
| `docs/refactoring-baseline.md` | `## Extended Agents` section appended (pre-work baseline: file/test state, known gaps). |

### Rule Preservation

`Anubis-Arch`, `Anubis-Runtime` and `Anubis-GreenOps` had **no formal
finding IDs before this pass** — confirmed in the baseline (STEP 0).
`ARCH-*`/`RT-*`/`GRN-*` are therefore a first assignment, not a rename;
no OLD ID → NEW ID mapping applies to these three families. Introduced
and verified present (Gate 13):

- `ARCH-LAYER` (2), `ARCH-DEP` (3), `ARCH-LIC` (2), `ARCH-DEBT` (1)
- `RT-N1` (1), `RT-ASYNC` (5), `RT-LOCK` (3), `RT-MEM` (3), `RT-CRAP` (1)
- `GRN-CARBON` (1), `GRN-COST` (2), `GRN-PROV` (3), `GRN-REGION` (1), `GRN-PATTERN` (2)

All pre-existing `ANB-*` and `AZDO-*` families are unchanged (Gates 5, 6, 11).

### Installer Tests (extended)

```text
$ bash install.sh --dest <tmp> --suite arch   # single-suite filter
✓ Anubis-Arch installato per Generic (generic)
✓ Installazione completata e verificata

$ bash install.sh --local                     # all 5 agents, local
✓ Pacchetto Anubis installato localmente
✓ Creato .claude/settings.json con registrazione agenti
  (5 valid JSON entries, one per installed agent)
```

### Regression Tests (extended)

```text
$ bash tests/regression.sh
REGRESSION OK
  passed: 228   failed: 0
```

## Final Status

PASS
