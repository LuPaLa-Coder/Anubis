# Reference — C# / .NET correctness & idiom

Pattern catalogue for `Anubis`. Every entry is a **candidate generator**, not a
finding: apply Evidence First (`references/review-protocol.md`). Family:
`ANB-DOTNET`.

Uniform model per pattern: Detection · Context · Evidence Required · Typical
Impact · Possible Severity · False Positives · Remediation · Verification.

---

## ANB-DOTNET-001 — `async void`

- **Detection**: method signature `async void` outside event handlers.
- **Context**: exceptions in `async void` escape to the synchronization context
  and cannot be awaited or caught by the caller.
- **Evidence Required**: the declaration and at least one call site showing the
  result is not observed.
- **Typical Impact**: process crash, unhandled exception, silent failure.
- **Possible Severity**: HIGH (CRITICAL if on a critical path).
- **False Positives**: legitimate event handlers (`async void OnClick(...)`).
- **Remediation**: return `async Task`; for event handlers keep `async void` but
  wrap the body in `try/catch`.
- **Verification**: unit test asserting exception propagation; build warnings.

## ANB-DOTNET-002 — Sync-over-async (`.Result`, `.Wait()`, `.GetAwaiter().GetResult()`)

- **Detection**: `.Result` / `.Wait()` / `.GetAwaiter().GetResult()` on a `Task`.
- **Context**: in ASP.NET/UI contexts this can deadlock and always blocks a pool
  thread.
- **Evidence Required**: the blocking call plus the async call chain.
- **Typical Impact**: deadlock, thread starvation, latency spikes.
- **Possible Severity**: HIGH.
- **False Positives**: `Main` before async-capable runtime; documented boundary.
- **Remediation**: propagate `await` end-to-end; if a sync boundary is
  unavoidable, isolate it explicitly.
- **Verification**: unit/integration test; static analysis rule.

## ANB-DOTNET-003 — Generic catch / swallowed exception

- **Detection**: `catch (Exception)` without rethrow, `catch { }`, empty catch.
- **Context**: hides failures, defeats observability.
- **Evidence Required**: the catch block and the absence of logging/rethrow.
- **Typical Impact**: silent data corruption, undiagnosable incidents.
- **Possible Severity**: MEDIUM–HIGH.
- **False Positives**: top-level boundary loggers; documented compensation.
- **Remediation**: catch specific exceptions, log with context, rethrow or
  `throw;` preserving the stack.
- **Verification**: unit test for the failure path; static analysis.

## ANB-DOTNET-004 — `throw ex;` resets the stack trace

- **Detection**: `throw ex;` (or `throw new ...` without inner exception).
- **Evidence Required**: the statement in context.
- **Typical Impact**: lost root cause; harder incident triage.
- **Possible Severity**: LOW–MEDIUM.
- **Remediation**: `throw;` or pass the original as inner exception.
- **Verification**: code review; static analysis.

## ANB-DOTNET-005 — Missing `using` / `Dispose` on `IDisposable`

- **Detection**: `new HttpClient`, streams, `DbContext`, `SqlConnection` not in a
  `using` / `using var`.
- **Evidence Required**: the instantiation and its scope.
- **Typical Impact**: socket exhaustion, connection leaks, memory growth.
- **Possible Severity**: MEDIUM–HIGH.
- **False Positives**: ownership transferred to a container/long-lived field.
- **Remediation**: `using` / `using var`, `IHttpClientFactory` for `HttpClient`.
- **Verification**: unit test + resource-leak check; static analysis.

## ANB-DOTNET-006 — Nullability ignored

- **Detection**: nullable warnings suppressed, `!` null-forgiving everywhere,
  `#nullable disable`.
- **Evidence Required**: the suppression and the unguarded dereference.
- **Typical Impact**: `NullReferenceException` in production.
- **Possible Severity**: MEDIUM.
- **Remediation**: enable nullable reference types; enforce with `TreatWarningsAsErrors`.
- **Verification**: build with warnings-as-errors.

## ANB-DOTNET-007 — `DateTime.Now` instead of `DateTime.UtcNow`

- **Detection**: `DateTime.Now`, `DateTimeOffset.Now` for persisted/computed values.
- **Evidence Required**: the usage and where the value flows (storage/API).
- **Typical Impact**: DST/immutability bugs across environments.
- **Possible Severity**: MEDIUM.
- **Remediation**: `DateTime.UtcNow` / `DateTimeOffset.UtcNow`; inject a clock.
- **Verification**: unit test with a fake clock.

## ANB-DOTNET-008 — Culture-sensitive string operations

- **Detection**: `ToLower()`/`ToUpper()`, `StartsWith`/`EndsWith`/`Contains`
  without `StringComparison`.
- **Evidence Required**: the call and the intent (comparison vs display).
- **Typical Impact**: Turkish-I and other culture bugs; unintended allocations.
- **Possible Severity**: MEDIUM.
- **False Positives**: display-only use.
- **Remediation**: `StringComparison.Ordinal`/`OrdinalIgnoreCase`.
- **Verification**: unit test with `tr-TR` culture.

## ANB-DOTNET-009 — Multiple enumeration of `IEnumerable`

- **Detection**: an `IEnumerable<T>` iterated more than once; deferred query
  re-executed.
- **Evidence Required**: two consumption points of the same enumerable.
- **Typical Impact**: duplicated work/queries; inconsistent results.
- **Possible Severity**: MEDIUM.
- **Remediation**: materialize once, or accept `IReadOnlyCollection<T>`.
- **Verification**: unit test with a counting enumerable.

## ANB-DOTNET-010 — `Count() > 0` on `IEnumerable`

- **Detection**: `.Count() > 0`, `.Count() != 0`, `.Any()` vs `.Count()`.
- **Evidence Required**: the call on a lazy sequence.
- **Typical Impact**: full scan instead of short-circuit.
- **Possible Severity**: LOW–MEDIUM.
- **Remediation**: `Any()`.
- **Verification**: benchmark or query-plan inspection.

## ANB-DOTNET-011 — Mutable public surface / broken encapsulation

- **Detection**: public settable properties on domain entities, public fields,
  collections exposed as mutable.
- **Evidence Required**: the type and a mutation from outside.
- **Typical Impact**: invariants bypassed; hard-to-reason domain model.
- **Possible Severity**: MEDIUM.
- **Remediation**: private setters, constructors/factories, defensive copies.
- **Verification**: unit tests on invariants; code review.

## ANB-DOTNET-012 — Blocking I/O on an async path

- **Detection**: `File.ReadAllText`, `Stream.Read`, synchronous ADO.NET calls
  inside an async method.
- **Evidence Required**: the sync call in an async chain.
- **Typical Impact**: pool exhaustion under load.
- **Possible Severity**: MEDIUM–HIGH.
- **Remediation**: use the async counterparts.
- **Verification**: load test; static analysis.
