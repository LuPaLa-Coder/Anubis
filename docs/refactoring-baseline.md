# Refactoring Baseline

Snapshot captured before the skills refactoring described in
*Anubis — Coding Agent Refactoring Plan* (STEP 0).

## Repository

- Path: `/Users/paolo/repo/GitHUbLupala/anubis`
- VCS: git, branch `main`, working tree clean at baseline
- Remote: `git@github.com:LuPaLa-Coder/anubis.git`
- Last commit at baseline: `96c2144 feat: Implement uninstaller script for Anubis Agent Suite`
- No `.github/` workflows, no CI configuration.

## Existing Skills

| FILE | PURPOSE | REFERENCED BY | REFERENCES |
| --- | --- | --- | --- |
| `Anubis.agent.md` | Operating contract + knowledge base for the .NET review agent (431 lines) | `install.sh`, `README.md`, `docs/usage.md`, `docs/installation.md`, `docs/examples.md`, `EVOLUTIONS.md` | none (self-contained) |
| `Anubis.devops.md` | Operating contract + knowledge base for the Azure DevOps pipeline security agent (780 lines) | `install.sh`, `README.md`, `docs/devops/usage.md`, `docs/devops/installation.md`, `docs/devops/examples.md` | none (self-contained) |

Cross-skill references already present inside the skill bodies:

- `Anubis.agent.md` → hands off to `Anubis-devops` / `human` / `nessuno`.
- `Anubis.devops.md` → hands off to `Anubis` / `human`.

## Existing Tests

None. The repository has no test framework, no test runner, no CI, no linter.
The only executable tooling is:

- `install.sh` — multi-platform installer (Claude Code, OpenCode, Copilot, Cursor,
  Windsurf, Codex). It extracts the body of each skill (everything after the YAML
  frontmatter) and writes it to the platform agent directory.
- `uninstall.sh` — removes the installed skill files.

Implication: STEP 0 "run all existing tests" is a no-op; there is nothing to run.
The regression suite created by this refactoring is therefore the first
verifiable behaviour layer for the suite, and `install.sh` is the only artifact
whose contract must not be broken (frontmatter stripping + body install).

## Existing Rules

### Anubis (.NET)

No rule IDs existed. Patterns were grouped by *category and severity*:

- Performance anti-patterns: CRITICAL (`FromSqlRaw` interpolation, `DbContext`
  lifecycle), HIGH (`async void`, `.Result`/`.Wait()`, unbounded `Task.WhenAll`,
  `string +=` in loop, EF Core N+1, `ToList()` before `Where()`), MEDIUM
  (culture-sensitive string ops, `Substring` in hot path, `new Regex` per call,
  collections without capacity, `Count() > 0`, missing `AsNoTracking()`), LOW
  (`FrozenDictionary`, `RegexOptions.Compiled`, non-`sealed`, `params T[]`).
- EF Core pattern table (6 rows).
- MSTest 3.x/4.x expectations (9 bullets).
- MSBuild anti-patterns table `AP-01` … `AP-09`.
- CRAP score quick reference.

### Anubis-devops (Azure DevOps)

41 unique rule IDs with the prefix `AZDO-SEC` (`AZDO-SEC001` … `AZDO-SEC042`),
actually distributed as 10 CRITICAL, 17 HIGH, 14 MEDIUM. The source document's
completion checklist claimed "42 rules (10 CRITICAL, 19 HIGH, 13 MEDIUM)"; the
mismatch is a pre-existing documentation error recorded here and corrected
during the refactoring (see `docs/refactoring-report.md`).

- CRITICAL: `AZDO-SEC001`–`AZDO-SEC008`, `AZDO-SEC033`, `AZDO-SEC034`
- HIGH: `AZDO-SEC010`–`AZDO-SEC019`, `AZDO-SEC031`, `AZDO-SEC032`, `AZDO-SEC035`–`AZDO-SEC039`
- MEDIUM: `AZDO-SEC020`–`AZDO-SEC030`, `AZDO-SEC040`–`AZDO-SEC042`

Note: `AZDO-SEC009` is not present in the source (gap between SEC008 and SEC010,
and the SEC033–SEC042 block was appended by the v2.0 changelog). The refactoring
preserves this numbering exactly.

Additional inventories preserved by the refactoring:

- Security analysis areas (10 areas).
- CWE mapping + OWASP Top 10 CI/CD, NIST SSDF, SLSA, OSSF Scorecard mappings.
- Known false positives table (6 rows).
- Security Score formula `max(0, 100 − (CRITICAL×20 + HIGH×10 + MEDIUM×3 + LOW×1))`
  + 5 bands.
- Azure Policy recommendations (organization + project).
- 6 YAML remediation examples (secrets, WIF, NuGet trusted publishing, container,
  template, `System.AccessToken`, `setvariable`).
- 8 first-pass regexes.
- Analysis behaviour steps (6), completion workflow (10), static-analysis limits (6),
  untrusted-input guardrails (5).

## Shared Behaviour Already Present (must survive)

- Severity scale `BLOCKER | CRITICAL | HIGH | MEDIUM | LOW` (BLOCKER used in both).
- Two run modes for Anubis: **Quick Pass** and **Full Review**.
- Common output contract (`Decisioni chiave`, `Assunzioni`, `Rischi`, `Blocchi`,
  `Artefatti prodotti`, `Handoff al prossimo agente`).
- Bidirectional handoff Anubis ↔ Anubis-devops and handoff to `human`.
- Interoperability matrix.
- Anubis-devops security score and remediation split
  (`YAML fix` / `Infrastructure fix` / `Code or config fix`).

## Known Failures

- No automated tests exist, therefore **no known failing tests** at baseline.
- No automated link/reference checker exists; "no broken links" is a manual gate.
- `install.sh` only distributes the two skill files — it does not distribute any
  companion assets (there were none before this refactoring).

## Files Affected

Created by the refactoring (planned):

```text
references/review-protocol.md
references/dotnet.md
references/security.md
references/architecture.md
references/performance.md
references/efcore.md
references/testing.md
references/msbuild.md
references/azure-devops-rules.md
schemas/finding.schema.json
schemas/review.schema.json
schemas/handoff.schema.json
examples/dotnet-review.md
examples/security-review.md
examples/performance-review.md
examples/devops-review.md
tests/anubis/{security,architecture,performance,testing,false-positive}.md
tests/devops/{secrets,identity,supply-chain,pipeline,false-positive}.md
tests/regression.md
docs/refactoring-baseline.md
docs/refactoring-report.md
```

Modified:

```text
Anubis.agent.md
Anubis.devops.md
README.md
```

Unchanged (compatibility surface):

```text
install.sh
uninstall.sh
docs/usage.md
docs/installation.md
docs/examples.md
docs/devops/usage.md
docs/devops/installation.md
docs/devops/examples.md
```

Rules for this baseline step: do **not** fix unrelated issues here.
