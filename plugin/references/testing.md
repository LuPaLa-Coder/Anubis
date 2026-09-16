# Reference — Testing & testability

Pattern catalogue for `Anubis`. Family: `ANB-TEST`. Evidence First applies.

---

## ANB-TEST-001 — `MSTest.Sdk` not used

- **Detection**: test project with separate `MSTest.TestFramework` +
  `MSTest.TestAdapter` package references instead of `MSTest.Sdk`.
- **Evidence Required**: the `.csproj` package references.
- **Typical Impact**: drift, missing runner features.
- **Possible Severity**: LOW–MEDIUM.
- **Remediation**: use `<Project Sdk="MSTest.Sdk/...">`.
- **Verification**: build + `dotnet test`.

## ANB-TEST-002 — Test class not `sealed`

- **Detection**: non-`sealed` test classes.
- **Evidence Required**: the class declaration.
- **Typical Impact**: unintended inheritance; MSTest 3+ has no test inheritance.
- **Possible Severity**: LOW.
- **Remediation**: mark test classes `sealed`.
- **Verification**: code review.

## ANB-TEST-003 — `[TestInitialize]` instead of constructor

- **Detection**: `[TestInitialize]` / `[TestCleanup]` for simple setup/teardown.
- **Evidence Required**: the attribute usage.
- **Typical Impact**: less idiomatic; harder to reason about state.
- **Possible Severity**: LOW.
- **Remediation**: constructor for setup, `IAsyncLifetime`/`Dispose` for async.
- **Verification**: code review.

## ANB-TEST-004 — Assert argument order

- **Detection**: `Assert.AreEqual(actual, expected)`.
- **Evidence Required**: the assertion.
- **Typical Impact**: confusing failure messages.
- **Possible Severity**: LOW.
- **Remediation**: `Assert.AreEqual(expected, actual)` — expected first.
- **Verification**: code review; analyzer.

## ANB-TEST-005 — `ThrowsException` instead of `ThrowsExactly`

- **Detection**: `Assert.ThrowsException<T>`.
- **Evidence Required**: the assertion.
- **Typical Impact**: derived types pass unintentionally.
- **Possible Severity**: LOW.
- **Remediation**: `Assert.ThrowsExactly<T>()`.
- **Verification**: code review.

## ANB-TEST-006 — `DynamicData` with `object[]`

- **Detection**: `DynamicData` / `DataRow` supplying `object[]`.
- **Evidence Required**: the data source.
- **Typical Impact**: lost type safety.
- **Possible Severity**: LOW.
- **Remediation**: `ValueTuple` payloads.
- **Verification**: code review.

## ANB-TEST-007 — `Thread.Sleep` for async synchronisation

- **Detection**: `Thread.Sleep` in async tests.
- **Evidence Required**: the call.
- **Typical Impact**: flaky, slow tests.
- **Possible Severity**: MEDIUM.
- **Remediation**: `CancellationToken` + `Task`/`await`, or a synchronisation
  primitive.
- **Verification**: test run stability.

## ANB-TEST-008 — Shared mutable static state

- **Detection**: static mutable fields used across test classes/parallel runs.
- **Evidence Required**: the static state and its mutation.
- **Typical Impact**: flakiness under parallelisation.
- **Possible Severity**: MEDIUM.
- **Remediation**: instance state, fixtures, test isolation.
- **Verification**: repeated/parallel test runs.

## ANB-TEST-009 — `TestContext` via property instead of constructor

- **Detection**: public `TestContext` property with setter.
- **Evidence Required**: the property.
- **Typical Impact**: less idiomatic (MSTest 3.6+).
- **Possible Severity**: LOW.
- **Remediation**: inject `TestContext` via the constructor.
- **Verification**: code review.

## ANB-TEST-010 — High CRAP score

- **Detection**: methods with high cyclomatic complexity and low coverage.
- **Evidence Required**: complexity and coverage numbers for the method.
- **Typical Impact**: high change risk; untested branches.
- **Possible Severity**: see thresholds below.
- **Remediation**: extract methods, add tests, reduce branching.
- **Verification**: coverage report + complexity report.

Formula: `CRAP(m) = comp(m)² × (1 − cov(m))³ + comp(m)`.

| Score | Risk |
| --- | --- |
| < 5 | Low — acceptable |
| 5–15 | Moderate — monitor |
| 15–30 | High — refactoring recommended |
| > 30 | Critical — refactoring required |

Rule of thumb: complexity 10 needs ≥ 80% coverage to stay under CRAP 30;
complexity ≥ 15 is almost always High/Critical regardless of coverage.

Report complexity > 10 with low coverage as HIGH; > 15 without tests as CRITICAL.
