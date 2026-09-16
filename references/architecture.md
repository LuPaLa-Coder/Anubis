# Reference — Architecture & design

Pattern catalogue for `Anubis`. Family: `ANB-ARCH`. Evidence First applies.

---

## ANB-ARCH-001 — Layering violation

- **Detection**: domain referencing infrastructure; controllers containing
  persistence/business logic; circular project references.
- **Evidence Required**: the reference/using and the offending dependency.
- **Typical Impact**: untestable core, fragile boundaries.
- **Possible Severity**: MEDIUM–HIGH.
- **False Positives**: intentional vertical slices / documented pragmatic design.
- **Remediation**: invert dependencies; ports & adapters.
- **Verification**: architecture tests (NetArchTest/ArchUnitNET); build.

## ANB-ARCH-002 — Dependency on concrete types (tight coupling)

- **Detection**: instantiating collaborators with `new` inside services;
  depending on concrete classes instead of abstractions.
- **Evidence Required**: the instantiation and the dependency.
- **Typical Impact**: hard to test/mock, high change cost.
- **Possible Severity**: MEDIUM.
- **Remediation**: constructor injection against interfaces.
- **Verification**: unit tests with fakes.

## ANB-ARCH-003 — Service locator / static access

- **Detection**: `IServiceProvider.GetService` used as a locator; static mutable
  singletons; `HttpContext.Current`-style ambient state.
- **Evidence Required**: the locator/static call site.
- **Typical Impact**: hidden dependencies, flaky tests.
- **Possible Severity**: MEDIUM.
- **Remediation**: explicit constructor injection.
- **Verification**: unit tests without a container.

## ANB-ARCH-004 — God class / SRP violation

- **Detection**: large classes (>500 LOC rigidly), many unrelated public methods,
  low cohesion.
- **Evidence Required**: the class and its mixed responsibilities.
- **Typical Impact**: merge conflicts, low testability, high cognitive load.
- **Possible Severity**: MEDIUM.
- **Remediation**: split by responsibility; extract collaborators.
- **Verification**: complexity metrics + tests after extraction.

## ANB-ARCH-005 — Anemic domain / logic in the wrong layer

- **Detection**: domain entities with only getters/setters; business rules in
  controllers or repositories.
- **Evidence Required**: the rule and the layer hosting it.
- **Typical Impact**: duplicated rules, inconsistent invariants.
- **Possible Severity**: MEDIUM.
- **Remediation**: move invariants into the domain model / application services.
- **Verification**: domain unit tests.

## ANB-ARCH-006 — Circular dependencies

- **Detection**: project or namespace cycles; two services referencing each other.
- **Evidence Required**: the cycle.
- **Typical Impact**: unbuildable/testable traps, tangled modules.
- **Possible Severity**: HIGH.
- **Remediation**: extract shared abstraction; invert one direction.
- **Verification**: dependency graph check in CI; build.

## ANB-ARCH-007 — `DbContext` lifetime misuse

- **Detection**: `DbContext` captive in a singleton; shared across threads;
  static instance.
- **Evidence Required**: the registration and the injection.
- **Typical Impact**: concurrency exceptions, stale data, memory leaks.
- **Possible Severity**: CRITICAL.
- **False Positives**: explicitly `AddDbContextFactory` with per-operation scope.
- **Remediation**: scoped lifetime per request; `IDbContextFactory` for
  background work.
- **Verification**: integration tests under concurrency; DI validation on start.

## ANB-ARCH-008 — Missing `CancellationToken` propagation

- **Detection**: async methods without a `CancellationToken`; token accepted but
  not passed downstream.
- **Evidence Required**: the signature and the unpropagated call.
- **Typical Impact**: work continues after client disconnects; wasted resources.
- **Possible Severity**: MEDIUM.
- **Remediation**: accept and forward the token to all awaitable calls.
- **Verification**: unit test asserting cancellation.

## ANB-ARCH-009 — Leaky abstraction

- **Detection**: EF entities / data-layer types returned by the API; persistence
  concerns leaking into contracts.
- **Evidence Required**: the contract and the leaked type.
- **Typical Impact**: brittle API, over-posting, coupling to schema.
- **Possible Severity**: MEDIUM.
- **Remediation**: DTOs / projections at the boundary.
- **Verification**: contract tests; serialization review.

## ANB-ARCH-010 — Missing transaction boundary

- **Detection**: multiple related writes without a transaction; `SaveChanges` per
  item where atomicity is required.
- **Evidence Required**: the writes and the absence of a unit of work.
- **Typical Impact**: partial updates, data inconsistency.
- **Possible Severity**: HIGH.
- **Remediation**: wrap in an explicit transaction / unit of work.
- **Verification**: integration test forcing a mid-operation failure.
