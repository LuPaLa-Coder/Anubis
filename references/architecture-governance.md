# Reference — Architecture governance & dependencies

Pattern catalogue for `Anubis-Arch`. Families: `ARCH-LAYER`, `ARCH-DEP`,
`ARCH-LIC`, `ARCH-DEBT`. Evidence First applies: a dependency graph or a
license scan result is not a finding until it is confirmed against the
actual solution/package metadata under review.

---

## ARCH-LAYER-001 — Back-reference between layers

- **Detection**: outer/lower layer referenced by an inner/higher one (e.g.
  `Domain` referencing `Infrastructure`, `Application` referencing `UI`) —
  see the architecture pattern reference below for the expected direction
  per style.
- **Context**: identify the architectural style in use (Clean, DDD, Onion,
  CQRS, Layered) from namespace structure before flagging a violation; the
  allowed direction differs per style.
- **Evidence Required**: the project/namespace reference and the direction
  it violates.
- **Typical Impact**: untestable core, fragile boundaries, inability to
  swap infrastructure without touching business rules.
- **Possible Severity**: HIGH (if it breaks the declared architecture
  boundary) – MEDIUM (isolated, low-traffic violation).
- **False Positives**: intentional vertical slice, documented pragmatic
  exception, shared kernel project referenced by design.
- **Remediation**: invert the dependency (introduce an abstraction in the
  inner layer, implement it in the outer one).
- **Verification**: NetArchTest rule (`references/netarchtest-rules.md`)
  added to the suite and passing in CI.

## ARCH-LAYER-002 — Dependency cycle (assembly / type / namespace)

- **Detection**: two assemblies, types or namespaces referencing each
  other directly or transitively.
- **Evidence Required**: the cycle path (A → B → A).
- **Typical Impact**: unbuildable/untestable boundary, forced big-bang
  deploys, impossible incremental compilation.
- **Possible Severity**: CRITICAL.
- **False Positives**: none — a true cycle is always a defect; the only
  valid rejection is a false detection (e.g. tool reporting a resolved
  interface reference as a cycle).
- **Remediation**: extract a shared abstraction that both sides depend on;
  invert one direction.
- **Verification**: `dotnet list <solution>.sln package --include-transitive`
  plus a dedicated cycle-detection tool (NDepend, `dependency-cruiser`) in
  CI — NetArchTest does not expose a native cycle check, see
  `references/netarchtest-rules.md`.

## ARCH-DEP-001 — Version proliferation

- **Detection**: the same NuGet package resolved at 3+ distinct versions
  across the solution.
- **Evidence Required**: the package id and the set of resolved versions
  per project.
- **Typical Impact**: binding redirect fragility, inconsistent behaviour
  across projects, harder CVE remediation.
- **Possible Severity**: HIGH.
- **False Positives**: intentional pinning during a staged migration,
  documented and time-boxed.
- **Remediation**: consolidate via Central Package Management
  (`Directory.Packages.props`), single version principle.
- **Verification**: `dotnet list package` diff before/after; CPM lockfile
  review.

## ARCH-DEP-002 — Deep transitive chain with CVE exposure

- **Detection**: a transitive dependency chain deeper than ~5 levels that
  carries a known CVE.
- **Evidence Required**: the chain and the CVE identifier/CVSS score.
- **Typical Impact**: supply-chain exposure that is not visible from the
  direct `.csproj` reference list.
- **Possible Severity**: CRITICAL (CVSS ≥ 9.0) – HIGH (CVSS 7.0–8.9).
- **False Positives**: CVE affecting a code path not reachable/compiled in
  (documented, e.g. via a vulnerability scanner's reachability analysis).
- **Remediation**: upgrade the direct dependency that pulls the vulnerable
  transitive package, or add an explicit override pin.
- **Verification**: `dotnet list package --include-transitive --vulnerable`
  clean run.

## ARCH-DEP-003 — Unused dependency

- **Detection**: package referenced in a project file but no type/namespace
  from it is used in source.
- **Evidence Required**: the reference and the absence of usage (grep/
  symbol search across the project).
- **Typical Impact**: unnecessary attack surface, slower restore/build,
  noise in SBOM and license scans.
- **Possible Severity**: MEDIUM.
- **False Positives**: analyzer-only or build-time packages (source
  generators, `PrivateAssets="all"` tooling) that produce no runtime type
  usage by design.
- **Remediation**: remove the reference; re-run restore/build to confirm.
- **Verification**: build after removal; no missing-symbol errors.

## ARCH-LIC-001 — Copyleft license in proprietary product

- **Detection**: a package license (direct or transitive) is GPL/AGPL/LGPL
  or another copyleft license, while the product is closed-source/
  proprietary.
- **Evidence Required**: the package id, resolved license (SPDX
  identifier), and the product's declared distribution model.
- **Typical Impact**: legal/compliance risk, forced disclosure obligation.
- **Possible Severity**: CRITICAL.
- **False Positives**: license applies only to a build-time/dev-only tool
  never distributed with the product; dual-licensed package with a
  permissive option explicitly selected.
- **Remediation**: replace with a permissively-licensed alternative, or
  obtain a compatible commercial license; legal review before shipping.
- **Verification**: license compliance matrix regenerated and clean;
  legal sign-off recorded.

## ARCH-LIC-002 — Incompatible license conflict

- **Detection**: two dependencies in the same deployable unit carry
  licenses that cannot be legally combined (e.g. two different copyleft
  variants, or a copyleft license alongside a non-compatible proprietary
  term).
- **Evidence Required**: the two packages and the specific clause in
  conflict.
- **Typical Impact**: same as ARCH-LIC-001, compounded by the conflict
  itself.
- **Possible Severity**: HIGH.
- **Remediation**: replace one of the two dependencies; isolate them into
  separately-distributed components if legally sufficient.
- **Verification**: license compliance matrix; legal review.

## ARCH-DEBT-001 — Complexity hotspot correlated with architecture violation

- **Detection**: a class/method with cyclomatic complexity > 10 or CRAP
  score > 30 (see `references/testing.md`, `ANB-TEST-010`, for the
  formula) that also sits on a layer boundary already flagged by
  `ARCH-LAYER-*`.
- **Evidence Required**: the complexity/CRAP measurement and the co-located
  layer violation.
- **Typical Impact**: the highest-risk refactoring target — fixing the
  layer violation alone leaves an untested, hard-to-change hotspot behind.
- **Possible Severity**: HIGH (complexity + layer violation both present) –
  MEDIUM (complexity alone, no layer violation).
- **False Positives**: complexity driven by an exhaustive `switch`/pattern
  match over a closed, stable set of cases (documented, low-risk shape).
- **Remediation**: split by responsibility while fixing the layering issue
  in the same change, so the boundary is enforced by a smaller, testable
  unit.
- **Verification**: complexity/CRAP re-measured after refactor; NetArchTest
  rule added for the boundary.

---

## Architecture pattern reference

Used to establish the expected dependency direction before applying
`ARCH-LAYER-*`. Not a finding source by itself — a pattern mismatch is
only a candidate until confirmed against the actual namespace/reference
graph.

### Clean Architecture

- **Layers**: UI → Application → Domain → Infrastructure.
- **Rule**: Domain is framework-agnostic (no EF Core, no `HttpClient`);
  Application depends on Domain, not the reverse; Infrastructure implements
  interfaces defined in Application; UI depends on Application only.
- **Namespace pattern**: `<Company>.<Project>.Domain.*` →
  `...Application.*` → `...Infrastructure.*` → `...UI.*`.
- **Anti-pattern**: `EntityFrameworkCore`/`HttpClient` usings in Domain;
  direct DB calls from Application.

### Domain-Driven Design (DDD)

- **Layers**: Presentation → Application → Domain (aggregate root, entity,
  value object) → Persistence.
- **Rule**: aggregate root is the transaction boundary; value objects are
  immutable; repositories abstract persistence; domain services are
  stateless.
- **Namespace pattern**: `...Domain.{BoundedContext}.{AggregateRoot}.*`.
- **Anti-pattern**: anemic domain (getters/setters only); repository
  types referenced from Domain; circular bounded-context dependencies.

### Onion Architecture

- **Layers** (inner → outer): Domain → Domain Services → Application
  Services → UI/API/Infrastructure.
- **Rule**: dependencies always point inward; outer layers depend on
  inner ones, never the reverse; infrastructure is injected via DI, never
  `new`'d from Application.
- **Namespace pattern**: `...Core.Domain.*` → `...Core.Services.*` →
  `...Application.*` → `...Web.*` / `...Persistence.*`.
- **Anti-pattern**: Application calling Infrastructure directly; an outer
  layer imported by an inner one.

### CQRS

- **Layers**: API → Commands/Queries → Domain/Read model → DB (separate
  write/read stores).
- **Rule**: commands mutate state (Domain); queries read state (read
  model/cache); write and read stores may be physically separate; event
  sourcing is optional, not required.
- **Namespace pattern**: `...Commands.*` → `...Queries.*` → `...Events.*`
  → `...ReadModel.*`.
- **Anti-pattern**: a query that mutates state; a single DB serving both
  write and read paths with no read-model projection.

### Layered Architecture

- **Layers**: Presentation → Business Logic → Persistence → Database.
- **Rule**: layer N+1 depends only on layer N (no skipping); boundaries
  are crossed only at defined interfaces.
- **Namespace pattern**: `...Presentation.*` → `...Business.*` →
  `...Data.*`.
- **Anti-pattern**: Presentation calling Persistence directly; circular
  layer dependencies.
