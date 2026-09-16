# Reference — EF Core & data access

Pattern catalogue for `Anubis`. Family: `ANB-EFCORE`. Evidence First applies.
Severity depends on query frequency and data volume — never assign it blindly.

---

## ANB-EFCORE-001 — N+1 via lazy navigation in a loop

- **Detection**: `foreach` over entities then accessing a navigation property
  (`order.Customer.Name`) without eager loading / projection.
- **Context**: lazy loading enabled or navigation not included.
- **Evidence Required**: the loop and the navigation access.
- **Typical Impact**: one query per row; latency grows with data.
- **Possible Severity**: HIGH.
- **False Positives**: explicitly documented small bounded collections.
- **Remediation**: `Include`, projection (`Select`), or `AsSplitQuery`.
- **Verification**: query logging (assert query count); integration test.

## ANB-EFCORE-002 — `ToList()` before `Where()`

- **Detection**: `.ToList().Where(...)` or materialisation before filtering.
- **Evidence Required**: the order of operations.
- **Typical Impact**: full table fetch then in-memory filter.
- **Possible Severity**: HIGH.
- **Remediation**: invert — filter in the query, materialise last.
- **Verification**: query logging; SQL inspection.

## ANB-EFCORE-003 — Missing `AsNoTracking()` on read queries

- **Detection**: read-only queries without `AsNoTracking()`.
- **Evidence Required**: the query and its read-only usage.
- **Typical Impact**: change-tracker overhead and memory.
- **Possible Severity**: MEDIUM.
- **False Positives**: entities later updated in the same scope.
- **Remediation**: `AsNoTracking()` / `AsNoTrackingWithIdentityResolution()`.
- **Verification**: benchmark; query logging.

## ANB-EFCORE-004 — `Count() > 0` instead of `Any()`

- **Detection**: `.Count() > 0` / `.Count() != 0` on a query.
- **Evidence Required**: the call.
- **Typical Impact**: counts all rows instead of short-circuiting.
- **Possible Severity**: MEDIUM.
- **Remediation**: `.Any()`.
- **Verification**: SQL inspection; benchmark.

## ANB-EFCORE-005 — `FromSqlRaw` with interpolation

- **Detection**: interpolated or concatenated SQL in `FromSqlRaw`.
- **Evidence Required**: the query string.
- **Typical Impact**: SQL injection (see `ANB-SEC-001`).
- **Possible Severity**: CRITICAL.
- **Remediation**: `FromSqlInterpolated` or explicit `SqlParameter`.
- **Verification**: security regression test.

## ANB-EFCORE-006 — `DbContext` lifetime misuse

- **Detection**: `DbContext` singleton/captive, shared across threads.
- **Evidence Required**: the DI registration and injection.
- **Typical Impact**: concurrency failures, stale data, leaks.
- **Possible Severity**: CRITICAL.
- **Remediation**: scoped per request; `IDbContextFactory` for background work.
- **Verification**: DI validation; concurrency integration test.
- Cross-reference: `ANB-ARCH-007`.

## ANB-EFCORE-007 — Client-side evaluation

- **Detection**: queries that force client evaluation (untranslatable methods,
  `AsEnumerable()` mid-query).
- **Evidence Required**: the untranslatable construct and the query.
- **Typical Impact**: full-table pull; performance collapse at scale.
- **Possible Severity**: HIGH.
- **Remediation**: rewrite to provider-translatable LINQ; project server-side.
- **Verification**: EF logging for client-eval warnings; query plan.

## ANB-EFCORE-008 — `SaveChanges` inside a loop

- **Detection**: per-entity `SaveChanges`/`SaveChangesAsync` in a loop.
- **Evidence Required**: the loop and the per-item save.
- **Typical Impact**: transaction overhead per row; partial writes.
- **Possible Severity**: MEDIUM.
- **Remediation**: batch the unit of work, save once (with a transaction).
- **Verification**: integration test; DB round-trip count.
