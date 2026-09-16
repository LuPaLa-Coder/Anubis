# Anubis Refactoring Report

Refactoring of the Anubis skill suite from monolithic documents into
`skills = behaviour/workflow`, `references = knowledge/rules`,
`schemas = machine-readable contracts`, `tests = verifiable behaviour`,
`examples = practical documentation`.

Plan reference: *Anubis — Coding Agent Refactoring Plan*.
Baseline: `docs/refactoring-baseline.md`.

## Files Changed

| File | Before | After | Change |
| --- | --- | --- | --- |
| `Anubis.agent.md` | 431 lines, monolithic contract + pattern catalogue + model table | 209 lines, operating contract | knowledge moved to `references/`; deterministic workflow; evidence/confidence/review-status; model names replaced by capability labels |
| `Anubis.devops.md` | 780 lines, monolithic contract + 41 rules inline + regex + examples | 260 lines, operating contract | rule catalogue, regex and YAML examples moved to `references/azure-devops-rules.md`; structural parsing first; score marked secondary |
| `README.md` | described agents + JSON output only | describes architecture, skills, references, schemas, tests, handoff; planned agents labelled | documentation of the new structure (STEP 21) |
| `install.sh` | agent-only install, no runtime assets | packages `references/`, `schemas/`, `examples/`; idempotent; post-install verification; `--dest` target | final hardening: installable package |
| `uninstall.sh` | removed agent files only | also removes installed `references/`, `schemas/`, `examples/` (marker-guarded) | final hardening: clean uninstall |

## Files Added

- `references/review-protocol.md` — shared normative contract (lifecycle,
  Finding/Review/Handoff Contract, severity vs status, confidence, evidence,
  verification, IDs).
- `references/dotnet.md`, `security.md`, `architecture.md`, `performance.md`,
  `efcore.md`, `testing.md`, `msbuild.md` — Anubis knowledge base.
- `references/azure-devops-rules.md` — 41 Azure DevOps rules + regex fallback +
  YAML remediation examples + false-positive catalogue.
- `schemas/finding.schema.json`, `schemas/review.schema.json`,
  `schemas/handoff.schema.json` — JSON Schema 2020-12.
- `examples/dotnet-review.md`, `security-review.md`, `performance-review.md`,
  `devops-review.md` — worked reviews (each with a rejected false positive).
- `tests/anubis/{security,architecture,performance,testing,false-positive}.md`.
- `tests/devops/{secrets,identity,supply-chain,pipeline,false-positive}.md`.
- `tests/regression.md`, `tests/regression.sh` — executable regression suite.
- `tests/validate.sh` — reference and JSON Schema validation (final hardening).
- `tests/install_test.sh` — installer / idempotency / package regression test
  (final hardening).
- `docs/refactoring-baseline.md`, `docs/refactoring-report.md`,
  `docs/final-audit-report.md`.

## Files Removed

None. No rule, example or handoff was deleted.

## Rules Migrated

### Anubis (.NET) — new IDs introduced

Anubis previously had **no rule IDs**. Patterns were grouped only by category and
severity. They now live in the references with stable IDs:

| Source (old location) | New location | New IDs |
| --- | --- | --- |
| `async void`, `.Result`/`.Wait()`, exceptions, nullable, `DateTime.Now`, culture strings, LINQ | `references/dotnet.md` | `ANB-DOTNET-001`…`012` |
| EF Core injection, secrets, logging, validation, crypto, randomness, path, XXE, deserialization, CORS, TLS, authz | `references/security.md` | `ANB-SEC-001`…`012` |
| layering, coupling, service locator, god class, anemic domain, cycles, DbContext lifetime, cancellation, leaky abstraction, transactions | `references/architecture.md` | `ANB-ARCH-001`…`010` |
| unbounded `WhenAll`, `string +=`, regex, `Substring`, capacity, `sealed`, `params`, `FrozenDictionary`, `RegexOptions.Compiled`, materialise-before-filter, sync I/O, boxing | `references/performance.md` | `ANB-PERF-001`…`012` |
| EF Core pattern table (6 rows) | `references/efcore.md` | `ANB-EFCORE-001`…`008` |
| MSTest 3.x/4.x expectations, CRAP score | `references/testing.md` | `ANB-TEST-001`…`010` |
| MSBuild `AP-01`…`AP-09` | `references/msbuild.md` | `ANB-BUILD-001`…`009` (legacy `AP-0N` preserved as alias) |

Severities were preserved: e.g. `async void`, `.Result`, unbounded `WhenAll`,
`string +=`, N+1, `ToList()`-before-`Where()` stay HIGH; `FromSqlRaw`
interpolation and `DbContext` lifetime stay CRITICAL; MSTest style stays LOW.

### Anubis-devops — IDs preserved verbatim

All 41 IDs `AZDO-SEC001`…`AZDO-SEC042` are preserved unchanged and moved to
`references/azure-devops-rules.md`. Each rule gains uniform fields: family, CWE,
detect type (`structural` | `regex` | `external`), evidence required, exceptions /
false positives, remediation, verification.

Canonical dashed alias (documentation only, **not** a rename):

| Legacy ID (canonical, preserved) | Dashed alias | Family |
| --- | --- | --- |
| `AZDO-SEC001` … `AZDO-SEC042` | `AZDO-SEC-001` … `AZDO-SEC-042` | `SEC` / `IDENTITY` / `SUPPLY` / `PIPELINE` / `SECRET` (per rule) |

No ID was renamed, removed or renumbered. The `id` pattern in
`schemas/finding.schema.json` accepts both `AZDO-SEC001` and `ANB-SEC-001`.

## Rules Preserved

- **Azure DevOps**: 41/41 unique IDs present (`tests/regression.sh` Gate 5), with
  severity per rule unchanged.
- **Anubis**: every pattern from the original catalogue is present in the
  references (Gate 6 spot-checks `async void`, `.Result`, `.Wait()`, `WhenAll`,
  `StringBuilder`, `AsNoTracking`, `FromSqlRaw`, `MSTest`, `CRAP`,
  `ThrowsExactly`, `AP-01`…`AP-09`; the full sets are listed in the migration
  table above).
- Preserved behaviours: Quick Pass, Full Review, BLOCKED short-circuit, severity
  scale, Common Output Contract, bidirectional handoff, DevOps remediation split,
  Security Score formula, Azure Policy tables, false-positive catalogue, regex
  fallback, analysis limits, untrusted-input guardrails.

## Contract Changes

| Concept | Before | After |
| --- | --- | --- |
| Finding contract | ad hoc, prose | explicit fields in `references/review-protocol.md` + `schemas/finding.schema.json` |
| Review contract | implicit | `status`/`scope`/`summary`/`findings`/`remediation`/`verification`/`handoff` + `schemas/review.schema.json` |
| Handoff contract | prose templates | `target`/`reason`/`findings`/`files`/`required_context`/`artifacts` + `schemas/handoff.schema.json` |
| `BLOCKER` | listed among severities | removed from severity; `status: BLOCKED` + `blocker.reason` |
| Confidence | absent | `HIGH | MEDIUM | LOW` per finding |
| Evidence | implied | explicit: no evidence, no finding |
| Remediation | "fix" used generically | `recommendation` vs `fix` vs `migration`; DevOps buckets preserved |
| Verification | absent | mandatory per finding |
| Model requirement | named LLMs required | provider-independent capability labels |

## Skill Changes

- `Anubis.agent.md`: 431 → 209 lines (−51%).
- `Anubis.devops.md`: 780 → 260 lines (−67%).
- Both gained explicit Mission, Scope, Non-Scope, deterministic Review Workflow,
  Evidence/Finding contracts, Remediation, Verification, Handoff and References.
- No duplicated Finding Contract: it lives once in `references/review-protocol.md`
  and is referenced by both skills.

## Test Results

Baseline: no tests existed (`docs/refactoring-baseline.md`). The regression suite
is the first executable verification layer.

```text
$ bash tests/regression.sh
REGRESSION OK
  passed: 141   failed: 0
```

Coverage: files present, operating-contract sections, output contract, handoff
targets, all 41 AZDO rule IDs, all ANB rule families, MSBuild/.NET patterns,
score formula, BLOCKER not a severity, JSON schemas valid, no broken internal
references, and delegation to `tests/validate.sh` (reference + schema).

Additional executable layers added by the final hardening pass:

```text
$ bash tests/validate.sh      # reference + schema validation (REFERENCE/SCHEMA TEST: PASS)
$ bash tests/install_test.sh  # installer, idempotency, installed-package validation
```

Behavioural tests live in `tests/anubis/` and `tests/devops/`; they are
specification tests (input → expected findings/severity/confidence/handoff/
non-findings) intended for LLM-driven or manual execution.

## Known Limitations

1. **No automated LLM harness.** Behavioural tests are specifications, not
   machine-executed assertions; there is no runner that invokes a model and
   checks findings.
2. **Pre-existing count discrepancy.** The source claimed "42 rules
   (10/19/13)" but contained 41 unique IDs (10 CRITICAL, 17 HIGH, 14 MEDIUM).
   This report and the references use the accurate count; the original claim is
   recorded in `docs/refactoring-baseline.md`.
3. **`AZDO-SEC009` gap.** The id never existed in the source and is intentionally
   absent; it is not a lost rule.
4. **Legacy companion agents.** Anubis-Runtime / Anubis-Arch / Anubis-GreenOps
   are not part of this repository; the README now labels them under
   *Planned Agents*.

## Follow-up Recommendations

1. Add a CI job running `tests/regression.sh`, `tests/validate.sh` and
   `tests/install_test.sh`.
2. Add an optional LLM-driven test runner that executes `tests/anubis/*` and
   `tests/devops/*` and asserts the expected findings.
3. Add `docs/usage.md` / `docs/devops/usage.md` sections describing the
   Finding/Review/Handoff contracts and confidence.
4. Consider assigning explicit IDs to any future Anubis patterns using the
   family registry in `references/review-protocol.md` §11.

## Final Verification

- Installer verified
- Runtime references verified
- Schemas verified
- Regression tests passed
- Installer idempotency verified

## Acceptance Criteria Mapping

| Criterion | Status |
| --- | --- |
| Common Review Protocol created | ✅ `references/review-protocol.md` |
| Finding / Handoff Contract centralised | ✅ protocol + schemas |
| JSON Schemas created and valid | ✅ 3 schemas, Gate 9 |
| `Anubis.agent.md` refactored, Scope/Non-Scope | ✅ 209 lines |
| Workflow deterministic, evidence-first, confidence | ✅ |
| BLOCKER separated from Severity | ✅ Gate 8 |
| Verification mandatory | ✅ protocol §8 + skill sections |
| Knowledge base in references | ✅ 7 Anubis + 1 DevOps |
| `Anubis.devops.md` refactored | ✅ 260 lines |
| Azure DevOps rules & IDs preserved | ✅ 41/41 Gate 5 |
| Rules moved to references | ✅ `azure-devops-rules.md` |
| False positives documented | ✅ rule catalogue + tests |
| Structural parsing preferred to regex | ✅ Detection section |
| Security score secondary only | ✅ Gate 7 |
| No rule/handoff lost; Quick Pass/Full Review kept | ✅ Gates 3–6 |
| Tests + regression created | ✅ `tests/` |
| README updated; refactoring report created | ✅ |
| Runtime references installed with the skills | ✅ `install.sh` copies `references/` + `schemas/` |
| Installer idempotent | ✅ `tests/install_test.sh` |
| Missing runtime file fails installation | ✅ post-install verification |
| Broken references detected automatically | ✅ `tests/validate.sh` |
| README distinguishes current vs planned agents | ✅ `## Planned Agents` |

---

## Extended Agents (Arch / Runtime / GreenOps)

Follow-up pass applying the same architecture to `Anubis.Arch.md`,
`Anubis.Runtime.md` and `Anubis.GreenOps.md`, previously monolithic and
absent from `install.sh`/`tests/`/README as implemented components.

Plan reference: *Anubis — Extended Agents Refactoring Plan (Arch ·
Runtime · GreenOps)*. Baseline: `docs/refactoring-baseline.md` →
`## Extended Agents`. Full change list and installer/regression output:
`docs/final-audit-report.md` → `## Extended Agents`.

### Files Changed

| File | Before | After | Change |
| --- | --- | --- | --- |
| `Anubis.Arch.md` | 597 lines, monolithic manifesto + pattern catalogue + model table | 211 lines, operating contract | NetArchTest/SBOM catalogues moved to `references/`; Scope/Non-Scope/Review Workflow added; `BLOCKER` removed from severity; `Confidence` introduced; model names replaced by capability labels |
| `Anubis.Runtime.md` | 543 lines, same pattern | 209 lines, operating contract | anti-pattern catalogue moved to `references/runtime-performance.md`; CRAP formula de-duplicated (reused from `references/testing.md`); same Scope/BLOCKER/Confidence/model fixes |
| `Anubis.GreenOps.md` | 567 lines, same pattern | 199 lines, operating contract | carbon/cost/green-pattern catalogue moved to `references/sustainability.md`; same Scope/BLOCKER/Confidence/model fixes |
| `references/review-protocol.md` | normative for `Anubis`/`Anubis-devops` only | normative for all 5 skills | opening line updated; §11 ID table extended (`ARCH-*`/`RT-*`/`GRN-*`); new §13 Agent Interoperability Matrix (single source, replacing 3 near-identical copies previously embedded per skill) |
| `schemas/finding.schema.json`, `schemas/handoff.schema.json`, `schemas/review.schema.json` | `id` pattern `(ANB\|AZDO)-…`; `category` enum without dependency/runtime/sustainability values; `handoff.target` without the 3 new agents | extended in lockstep across all three files | `id` pattern → `(ANB\|AZDO\|ARCH\|RT\|GRN)-…`; `category` +8 values; `handoff.target` +3 values |
| `install.sh` | v1.2, two agents hardcoded (`ANUBIS_FILE`/`DEVOPS_FILE`, two cache vars, two-branch `case` in every function) | v1.3, declarative registry (`AGENT_IDS` + 5 parallel arrays), bash-3.2-compatible | `get_agent_body`, `install_one_agent`, `install_dir`, `uninstall_agent`, `install_local`'s `settings.json` generation all loop over the registry; `--suite` accepts `arch`/`runtime`/`greenops`; `REQUIRED_RUNTIME_FILES` +5 |
| `tests/validate.sh` | `SKILL_FILES` = 2 files | 5 files | reference validation now covers the 3 new skills automatically |
| `tests/regression.sh` | 141 checks, 12 gates | 228 checks, 14 gates | Gates 2–4 loop over 5 skills; Gate 8 extended; new Gate 13 (`ARCH-*`/`RT-*`/`GRN-*` id thresholds) and Gate 14 (no hardcoded LLM model name) |
| `tests/install_test.sh` | `REQUIRED_FILES` = 14 entries, broken-source fixture = 2 skill files | `REQUIRED_FILES` = 21 entries, fixture = 5 skill files | installer regression now exercises all 5 skills + 5 new references |
| `README.md` | 2-skill table; `## Planned Agents` (3 agents marked 🗺️ pianificato) | 5-skill table; `## Agent Suite` (all ✅ implementato) | architecture tree, References table, Tests/Handoff/Quick Start sections extended |
| `docs/installation.md` | manual-install examples copied only `Anubis.agent.md`/`Anubis.devops.md` | copies all 5 skill files; `--suite` documented | stale example fixed |

### Files Added

- `references/architecture-governance.md`, `references/netarchtest-rules.md`,
  `references/sbom.md` — Anubis-Arch knowledge base (`ARCH-LAYER`,
  `ARCH-DEP`, `ARCH-LIC`, `ARCH-DEBT`).
- `references/runtime-performance.md` — Anubis-Runtime knowledge base
  (`RT-N1`, `RT-ASYNC`, `RT-LOCK`, `RT-MEM`, `RT-CRAP`), with an explicit
  rule to reuse `ANB-PERF-*`/`ANB-EFCORE-*` instead of duplicating a
  static-only pattern.
- `references/sustainability.md` — Anubis-GreenOps knowledge base
  (`GRN-CARBON`, `GRN-COST`, `GRN-PROV`, `GRN-REGION`, `GRN-PATTERN`),
  GHG Protocol formula, regional emission factors, worked examples.
- `examples/arch-review.md`, `examples/runtime-review.md`,
  `examples/greenops-review.md` — worked reviews, each with a rejected
  false positive.
- `tests/arch/{layering,dependency-drift,license,false-positive}.md`.
- `tests/runtime/{n-plus-one,async-lock,memory,false-positive}.md`.
- `tests/greenops/{over-provisioning,carbon,false-positive}.md`.
- `docs/arch/`, `docs/runtime/`, `docs/greenops/` —
  `usage.md`/`installation.md`/`examples.md` per agent (installation.md
  points to the unified installer instead of duplicating it).

### Files Removed

None. No file was deleted; content was relocated (skill → reference) or
extended in place (protocol, schemas, tests, README, install.sh).

### Rules Migrated

`Anubis.Arch.md`/`Anubis.Runtime.md`/`Anubis.GreenOps.md` had **no
formal finding IDs before this pass** (confirmed in the STEP 0
baseline). `ARCH-*`, `RT-*` and `GRN-*` are therefore a **first
assignment**, not a migration — no OLD ID → NEW ID mapping applies to
these three families, unlike the `AZDO-SEC0NN` legacy-ID preservation
done for `Anubis-devops`.

### Rules Preserved

All pre-existing `ANB-*` and `AZDO-*` families are unchanged by this
pass (Gates 5, 6, 11 of `tests/regression.sh` still pass at their
original counts).

### Contract Changes

- `references/review-protocol.md` §13 (Agent Interoperability Matrix)
  is new; every skill's `## Handoff` section links to it instead of
  redefining the same table (previously duplicated 3× near-identically
  across `Anubis.Arch.md`/`Anubis.Runtime.md`/`Anubis.GreenOps.md`).
- `schemas/*.schema.json` — `id` pattern, `category` enum and
  `handoff.target` enum extended in `finding.schema.json`,
  `handoff.schema.json` and `review.schema.json` in lockstep (the third
  file carries its own duplicate copies of these enums; all three were
  updated together to avoid drift).

### Skill Changes

Both `Anubis.Arch.md`/`Anubis.Runtime.md`/`Anubis.GreenOps.md` now
follow the same section order as `Anubis.agent.md`/`Anubis.devops.md`:
`Mission / Scope / Non-Scope / Operating Contract / Review Workflow /
Evidence Contract / Finding Contract / Severity / Confidence /
Remediation / Verification / Handoff / Output Contract / References`,
each with a Quick Pass / Full Review split and a `BLOCKED` short-circuit
mirroring `Anubis.agent.md`.

### Test Results

```text
$ bash tests/validate.sh
VALIDATION OK

$ bash tests/regression.sh
REGRESSION OK
  passed: 228   failed: 0

$ bash tests/install_test.sh
INSTALLATION TEST: PASS
IDEMPOTENCY TEST: PASS
REFERENCE TEST: PASS
SCHEMA TEST: PASS
```

### Known Limitations

- No automated LLM harness: `tests/arch/*`, `tests/runtime/*` and
  `tests/greenops/*` are specifications, not machine-executed assertions
  (same limitation already recorded for `tests/anubis/*`/`tests/devops/*`).
- `Anubis-azure` remains referenced only as a handoff/interoperability
  target; it is not implemented in this repository.

### Follow-up Recommendations

1. Consider an automated LLM harness that actually runs each
   `tests/{anubis,devops,arch,runtime,greenops}/*.md` scenario against a
   live agent invocation and diffs the reported findings.
2. If `Anubis-azure` is ever implemented in this repository, extend the
   installer registry (`AGENT_IDS` + parallel arrays in `install.sh`)
   and `references/review-protocol.md` §11/§13 the same way this pass
   extended them for Arch/Runtime/GreenOps — the mechanism is now
   generic, not agent-count-specific.
