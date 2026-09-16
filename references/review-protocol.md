# Review Protocol

Shared contract for the Anubis agent suite (`Anubis`, `Anubis-devops`,
`Anubis-Arch`, `Anubis-Runtime`, `Anubis-GreenOps`).

This document is **normative**. Both skills inherit it. A skill may narrow the
protocol (defined in its own Scope/Non-Scope) but must not contradict it.

---

## 1. Core principle — Evidence First

A pattern never *is* a finding. A pattern is an observation that becomes a
finding only after it is validated against the concrete artifact under review.

```text
Pattern
   ↓
Candidate
   ↓
Evidence
   ↓
Impact
   ↓
Finding
```

```text
NO EVIDENCE = NO FINDING
```

- **Pattern** — a known risk shape (e.g. `.Result` on a `Task`, hardcoded secret).
- **Candidate** — a location where the pattern appears to match.
- **Evidence** — the concrete code/config lines that prove the candidate is real
  in the reviewed artifact.
- **Impact** — the concrete consequence in the reviewed context.
- **Finding** — the candidate promoted to a reported item, carrying the full
  Finding Contract.

A candidate that cannot be backed by evidence is either **rejected** or reported
as a **false-positive rejection** in the review (see §7), never as a finding.

---

## 2. Review lifecycle

Every review of either skill follows this lifecycle, in order:

```text
SCOPE
  ↓
CONTEXT
  ↓
EVIDENCE
  ↓
CANDIDATES
  ↓
VALIDATION
  ↓
CLASSIFICATION
  ↓
REMEDIATION
  ↓
VERIFICATION
  ↓
HANDOFF
  ↓
REPORT
```

| Phase | Goal |
| --- | --- |
| SCOPE | Determine files, project and review objective. |
| CONTEXT | Inspect solution, projects, dependencies and relevant configuration. |
| EVIDENCE | Inspect the implementation details relevant to the review. |
| CANDIDATES | Identify potential issues. |
| VALIDATION | Validate each candidate against concrete evidence. |
| CLASSIFICATION | Assign category, severity and confidence. |
| REMEDIATION | Provide practical, classified remediation. |
| VERIFICATION | Define how each remediation must be validated. |
| HANDOFF | Route work only when another specialist is required. |
| REPORT | Produce the structured review. |

The lifecycle may short-circuit to `BLOCKED` (see §5); it must never skip
VALIDATION before CLASSIFICATION.

---

## 3. Severity vs Review Status

Severity and review status are **different axes** and must never be conflated.

### Severity (per finding)

```text
CRITICAL
HIGH
MEDIUM
LOW
```

### Review status (per review)

```text
COMPLETE   — review carried out on sufficient evidence
PARTIAL    — review carried out on incomplete but usable evidence
BLOCKED    — required context missing; review cannot be trusted
```

`BLOCKER` is **not** a severity. When a prerequisite is missing, the **review**
is `BLOCKED`; an individual finding is never `BLOCKER`.

```yaml
status: BLOCKED
blocker:
  reason: pipeline extends refs/heads/main of an external repo not available locally
```

A `BLOCKED` review does not publish findings; it publishes the blocker and the
handoff that resolves it.

---

## 4. Confidence (per finding)

```text
HIGH    — evidence directly verifiable in the reviewed code/config
MEDIUM  — evidence significant but depends on behaviour/config not fully visible
LOW     — issue plausible but requires more information / runtime validation
```

Confidence is orthogonal to severity: a `CRITICAL` pattern confirmed only by a
guess is `confidence: LOW` until validated.

---

## 5. Finding Contract

Every finding, in either skill, carries these fields.

```yaml
id:            # stable rule/finding id, e.g. ANB-SEC-001 or AZDO-SEC001
title:         # short human title
category:      # family, e.g. security | architecture | performance | dotnet |
               # efcore | testing | build | secrets | identity | supply-chain | pipeline
severity:      # CRITICAL | HIGH | MEDIUM | LOW
confidence:    # HIGH | MEDIUM | LOW
file:          # path to the artifact
location:      # line / range / symbol / resource path
evidence:      # concrete excerpt proving the candidate (required)
impact:        # concrete consequence in this context
root_cause:    # why it exists
recommendation:# what should change (see §6)
fix:           # concrete, localised change (optional if remediation is a migration)
verification:  # how to prove the fix (see §8)
references:    # rules / standards / docs
```

Required: `id`, `title`, `category`, `severity`, `confidence`, `file`,
`location`, `evidence`, `impact`, `verification`.
Recommended: `root_cause`, `recommendation`, `references`.
Optional: `fix` (absent when the remediation is a migration).

Machine-readable form: `schemas/finding.schema.json`.

---

## 6. Remediation — Recommendation vs Fix vs Migration

Three distinct levels. Do not call a recommendation a "fix".

| Level | Meaning |
| --- | --- |
| **Recommendation** | What should be modified and why. Not localised. |
| **Fix** | A concrete, localised change (snippet / config delta). |
| **Migration** | A change spanning multiple components or phases (e.g. Classic → YAML, SP secret → WIF, CPM rollout). |

Remediation must be classified (see the skill's Remediation section) and every
item must carry an effort class (`S` <1h, `M` 1–4h, `L` >4h / coordination) and a
priority (`P0` blocker, `P1` current sprint, `P2` backlog).

---

## 7. Evidence validity & false positives

Before classification, every candidate passes a false-positive check.

A pattern match is **rejected** (not a finding) when the context demonstrably
neutralises the risk, e.g.:

- documentation examples or comments;
- test fixtures / sample configuration;
- parameterised secrets, Key Vault references, pipeline variables;
- an explicit safe setting (`persistCredentials: false`);
- a documented, justified deviation.

When a pattern matches but the context justifies it, do **not** silently
suppress: either reject it with a stated reason, or downgrade it to an
informational `LOW` finding. The review's `summary` records counts of rejected
false positives.

---

## 8. Verification Contract

Every remediation defines how the fix is validated. Allowed verification kinds:

```text
Unit test
Integration test
Build
Static analysis
Benchmark
Security regression test
Pipeline validation
Configuration validation
Manual review (last resort, justified)
```

Rule:

```text
EVERY REMEDIATION MUST DEFINE HOW TO VERIFY THE FIX
```

---

## 9. Review Contract

```yaml
review:
  status:       # COMPLETE | PARTIAL | BLOCKED
  scope:        # reviewed artifacts, objective, boundaries
  summary:      # counts per severity, rejected false positives, key takeaways
  findings:     # list[Finding] (see §5)
  remediation:  # classified remediation items
  verification: # per-finding verification statements
  handoff:      # Handoff or null (see §10)
```

Machine-readable form: `schemas/review.schema.json`.

Optional secondary metrics (e.g. Anubis-devops security score) are allowed only
under `metrics`, never as a replacement for findings:

```yaml
metrics:
  score:       # numeric
  methodology: # deterministic, documented formula
```

---

## 10. Handoff Contract

```yaml
handoff:
  target:           # anubis | anubis-devops | anubis-arch | anubis-runtime |
                     # anubis-greenops | human | none
  reason:           # short reason
  findings:         # finding ids or short descriptors being transferred
  files:            # artifacts the next agent must read
  required_context: # context the next agent needs to continue
  artifacts:        # produced artifacts to transfer
```

Handoff happens **only when another specialist is actually required**. Never
hand off for convenience. `target: none` is a valid, explicit outcome.

Machine-readable form: `schemas/handoff.schema.json`.

---

## 11. Rule & finding IDs

IDs are stable and never recomputed from severity or order.

### Anubis (.NET) families

| Prefix | Family |
| --- | --- |
| `ANB-SEC` | application security |
| `ANB-ARCH` | architecture & design |
| `ANB-PERF` | performance |
| `ANB-DOTNET` | C#/.NET correctness & idiom |
| `ANB-EFCORE` | EF Core / data access |
| `ANB-TEST` | testing & testability |
| `ANB-BUILD` | build / MSBuild / packaging |

### Anubis-devops (Azure DevOps) families

| Prefix | Family |
| --- | --- |
| `AZDO-SEC` | secrets, credentials, common security |
| `AZDO-IDENTITY` | identity, RBAC, PAT, WIF |
| `AZDO-SUPPLY` | supply chain, tasks, artifacts, images |
| `AZDO-PIPELINE` | pipeline structure, governance, environments |

### Anubis-Arch (architecture governance) families

| Prefix | Family |
| --- | --- |
| `ARCH-LAYER` | layer isolation, back-reference, circular dependency |
| `ARCH-DEP` | dependency drift, version proliferation, transitive risk |
| `ARCH-LIC` | license compliance |
| `ARCH-DEBT` | complexity vs architecture correlation |

### Anubis-Runtime (runtime performance) families

| Prefix | Family |
| --- | --- |
| `RT-N1` | N+1 query pattern confirmed by trace/profiling |
| `RT-ASYNC` | async/await inefficiency, thread pool |
| `RT-LOCK` | lock contention, deadlock risk |
| `RT-MEM` | memory leak, GC pressure, allocations (runtime-confirmed) |
| `RT-CRAP` | CRAP score / latency correlation on hot path |

### Anubis-GreenOps (sustainability) families

| Prefix | Family |
| --- | --- |
| `GRN-CARBON` | carbon footprint estimation |
| `GRN-COST` | cloud cost waste |
| `GRN-PROV` | over/under-provisioning, sizing |
| `GRN-REGION` | regional energy mix / geography |
| `GRN-PATTERN` | green pattern absent (auto-shutdown, RI/spot, tiering) |

`ARCH-*`, `RT-*` and `GRN-*` are a **first assignment**: Anubis-Arch,
Anubis-Runtime and Anubis-GreenOps had no formal finding IDs before this
extension, so there is no legacy ID to preserve or map for these three
families.

Legacy DevOps IDs `AZDO-SEC001`…`AZDO-SEC042` are **preserved verbatim**.
Their family is recorded per rule; the canonical dashed form (e.g.
`AZDO-SEC-001`) is a documented alias, not a replacement. See
`references/azure-devops-rules.md` and `docs/refactoring-report.md`.

```text
Preservation rule: an ID that existed before the refactoring is never removed;
renames (if any) are recorded as OLD ID → NEW ID.
```

---

## 12. Output structure

Both skills end their run with the shared output contract:

```markdown
## Decisioni chiave
## Assunzioni
## Rischi
## Blocchi
## Artefatti prodotti
## Handoff al prossimo agente
```

- `Rischi` use `CRITICAL|HIGH|MEDIUM|LOW`.
- `Blocchi` describe a `BLOCKED` review, never a severity.
- `Handoff al prossimo agente` follows §10.

Model independence: the protocol must not require a specific LLM. Capability
labels are used instead — `lightweight model`, `reasoning-capable model`,
`large-context model`.

---

## 13. Agent interoperability matrix

Single source of truth for cross-agent routing. Every skill's `## Handoff`
section links here instead of redefining this table.

| Agent | Input minimo | Output minimo | Next agent tipico |
| --- | --- | --- | --- |
| `Anubis` | codice .NET, architettura, obiettivo review | finding applicativi, severity, refactoring | `Anubis-devops` / `Anubis-Arch` / `Anubis-Runtime` / `human` |
| `Anubis-devops` | YAML pipeline, contesto applicativo | finding pipeline, remediation, security score | `Anubis` / `Anubis-Arch` / `Anubis-GreenOps` / `human` |
| `Anubis-Arch` | codebase, `.sln`/`.csproj`, NuGet config, blueprint | NetArchTest rules, SBOM, compliance matrix, refactoring plan | `Anubis` / `Anubis-Runtime` / `Anubis-GreenOps` / `Anubis-devops` / `human` |
| `Anubis-Runtime` | tracce OpenTelemetry, codice sorgente, baseline | trace analysis, N+1 detection, refactoring + impact metrics | `Anubis` / `Anubis-Arch` / `Anubis-GreenOps` / `Anubis-devops` / `human` |
| `Anubis-GreenOps` | IaC (Bicep/Terraform), metriche Azure, baseline | carbon footprint, cost analysis, refactoring IaC, ROI | `Anubis-devops` / `Anubis` / `Anubis-Arch` / `Anubis-Runtime` / `human` |

Handoff happens only when another specialist is actually required (§10).
`target: none` remains a valid, explicit outcome for every agent.
