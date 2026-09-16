# Reference — Runtime performance

Pattern catalogue for `Anubis-Runtime`. Families: `RT-N1`, `RT-ASYNC`,
`RT-LOCK`, `RT-MEM`, `RT-CRAP`. Evidence First applies: a pattern match in
source is a **candidate**; it becomes a finding only when confirmed by a
trace, profiler output, or measured metric — static-only matches with no
runtime evidence belong to `Anubis` (`references/performance.md`,
`references/efcore.md`), not here.

## Overlap with static reference pages

Several shapes below already exist as static patterns in
`references/performance.md` (`ANB-PERF-*`) and `references/efcore.md`
(`ANB-EFCORE-*`), used by `Anubis` for source-only review. Do **not**
duplicate those entries here. Assign an `RT-*` id only when the finding
requires runtime evidence a static review cannot produce (an actual
trace span, a measured query count, a profiler sample). When a candidate
is confirmed purely from source with no trace involved, cite the
existing `ANB-PERF-*`/`ANB-EFCORE-*` id instead of minting a new one.

---

## RT-N1-001 — N+1 confirmed by trace/query count

- **Detection**: `foreach` over a collection with lazy navigation access,
  **and** a trace/log showing N nearly-identical queries for one logical
  request (N > 1, expected 1).
- **Context**: the request's OpenTelemetry span tree or SQL query log.
- **Evidence Required**: the loop, the navigation access, and the actual
  query count from the trace.
- **Typical Impact**: linear-in-N round trips; latency scales with
  result-set size.
- **Possible Severity**: CRITICAL (N >> 1, e.g. 1000 queries/request) –
  HIGH (N > 10) – MEDIUM (3–10).
- **False Positives**: `Include()`/eager loading already applied but the
  trace tool double-counts a split query — verify against the actual SQL
  text before reporting.
- **Remediation**: `Include()`/`ThenInclude()`, `AsSplitQuery()`, or a
  batch load replacing the per-item query.
- **Verification**: re-run the same request; trace shows a single (or
  bounded) query count; add a regression test asserting query count.
- Note: the static shape alone (loop + lazy navigation, no trace) is
  `ANB-EFCORE-001` — use that id when no runtime evidence is available.

## RT-ASYNC-001 — Deadlock risk: `.Result` / `.Wait()` in ASP.NET context

- **Detection**: `.Result` or `.Wait()` called on a `Task` inside a
  request-handling method, confirmed by a hang/timeout in trace or a
  reproduced deadlock.
- **Evidence Required**: the call site and the hang evidence (trace
  timeout, thread dump showing blocked `SynchronizationContext`).
- **Typical Impact**: guaranteed deadlock under load on contexts with a
  captured `SynchronizationContext`.
- **Possible Severity**: CRITICAL.
- **Remediation**: `await` end to end; never block on async code in a
  request path.
- **Verification**: load test confirming no hang; static analyzer rule
  (e.g. `CA2007`/`VSTHRD002`) added to prevent regression.

## RT-ASYNC-002 — `async void` event handler not observed

- **Detection**: `async void` method whose exceptions are not surfaced
  anywhere (no correlation id, no logged unhandled exception), confirmed
  by a trace gap where an expected downstream call never happened.
- **Evidence Required**: the method signature and the missing
  correlation/log entry.
- **Typical Impact**: silent failures, no error tracking, broken
  distributed trace.
- **Possible Severity**: HIGH.
- **Remediation**: `async Task` + `await` externally, or explicit
  try/catch with structured logging if the signature must stay `void`
  (event handler contract).
- **Verification**: fault-injection test confirming the exception is now
  observed/logged.

## RT-ASYNC-003 — Nested `await` inside `lock`

- **Detection**: `await` used inside a `lock` block.
- **Evidence Required**: the block and the awaited call.
- **Typical Impact**: thread-pool thread blocked holding the lock while
  other work starves; compiler may reject this outright in some cases,
  but equivalent patterns via `Monitor.Enter`/`Exit` compile silently.
- **Possible Severity**: CRITICAL.
- **Remediation**: extract the lock scope to exclude the `await`, or
  replace with `SemaphoreSlim` (async-aware).
- **Verification**: concurrency test under load; no thread-pool
  starvation observed.
- Related: see `RT-LOCK-002` when the blocking is on I/O specifically.

## RT-ASYNC-004 — `Task.Run()` in a request/UI thread

- **Detection**: `Task.Run()` wrapping I/O-bound work inside an ASP.NET
  request handler, confirmed by a trace span showing thread-pool queueing
  delay.
- **Evidence Required**: the call site and the queueing-delay evidence.
- **Typical Impact**: context loss, unnecessary thread-pool pressure.
- **Possible Severity**: HIGH.
- **Remediation**: `await` the I/O call directly; reserve `Task.Run()`
  for genuine CPU-bound work, ideally with `TaskScheduler.LongRunning`.
- **Verification**: trace shows the queueing delay removed.

## RT-ASYNC-005 — Thread pool starvation

- **Detection**: `ThreadPool` queue depth growing under load, confirmed
  by `dotnet-counters`/trace showing task scheduling delay.
- **Evidence Required**: the queue-depth metric or scheduling-delay trace.
- **Typical Impact**: cascading latency across unrelated requests sharing
  the pool.
- **Possible Severity**: HIGH.
- **False Positives**: expected burst absorbed within SLA, no sustained
  queue growth.
- **Remediation**: remove blocking calls from the pool (see
  `RT-ASYNC-001`/`RT-ASYNC-004`); tune `ThreadPool.SetMinThreads` only as
  a stopgap, not a fix.
- **Verification**: load test confirming queue depth stays bounded.

## RT-LOCK-001 — Nested locks without a global order

- **Detection**: two or more `lock`/`Monitor`/`SemaphoreSlim` acquired in
  different orders on different code paths.
- **Context**: thread dump or reproduced hang showing circular wait.
- **Evidence Required**: both acquisition orders and the thread dump.
- **Typical Impact**: deadlock (thread A holds X waits Y, thread B holds
  Y waits X).
- **Possible Severity**: CRITICAL.
- **Remediation**: enforce a single global lock-acquisition order, or
  replace with a lock-free/`ReaderWriterLockSlim` design.
- **Verification**: stress test exercising both paths concurrently; no
  hang observed.

## RT-LOCK-002 — `lock` around I/O

- **Detection**: `lock` block containing network/database/file I/O,
  confirmed by measured hold time.
- **Evidence Required**: the block and the measured lock hold time.
- **Typical Impact**: thread-pool starvation; hold time bounded by I/O
  latency instead of CPU work.
- **Possible Severity**: CRITICAL (hold time > 100ms under load) – HIGH
  (10–100ms).
- **Remediation**: move I/O outside the lock; use `SemaphoreSlim` with
  async support if serialisation is still required.
- **Verification**: measured hold time after fix; concurrency test.

## RT-LOCK-003 — Busy-wait without signaling

- **Detection**: a spin/poll loop checking a shared flag instead of using
  `Monitor.Wait`/`Pulse`, `ManualResetEvent`, or `SemaphoreSlim`,
  confirmed by sustained CPU usage with no forward progress.
- **Evidence Required**: the loop and the CPU profile.
- **Typical Impact**: CPU burn, no throughput to show for it.
- **Possible Severity**: HIGH.
- **Remediation**: replace with a proper signaling primitive.
- **Verification**: CPU profile after fix shows idle time during wait.

## RT-MEM-001 — Memory leak: event handler never unsubscribed

- **Detection**: `+=` subscription with no matching `-=`, confirmed by
  gen2 GC growing monotonically across a load test / production window.
- **Evidence Required**: the subscription site and the GC growth trend
  (heap snapshot diff or `dotnet-counters gc-collection` output).
- **Typical Impact**: unbounded memory growth, eventual `OutOfMemory`.
- **Possible Severity**: CRITICAL.
- **Remediation**: pair subscribe/unsubscribe explicitly, or use a weak
  event pattern.
- **Verification**: heap snapshot before/after over a soak test; growth
  eliminated.

## RT-MEM-002 — Unbounded static cache

- **Detection**: `static` mutable collection used as a cache with no
  eviction policy, confirmed by heap size trending with cache key
  cardinality.
- **Evidence Required**: the cache declaration and the heap trend.
- **Typical Impact**: unbounded growth proportional to distinct keys seen.
- **Possible Severity**: CRITICAL (unbounded key space) – HIGH (bounded
  but large key space, no expiry).
- **Remediation**: `MemoryCache` with `SlidingExpiration`/size limit.
- **Verification**: heap snapshot after fix shows bounded growth.

## RT-MEM-003 — Excessive GC pressure on a hot path

- **Detection**: gen0 collection frequency or allocation rate measured on
  a specific endpoint/method exceeds the agreed threshold.
- **Evidence Required**: the `dotnet-counters`/profiler output and the
  code path it attributes to.
- **Typical Impact**: pause time and throughput loss concentrated on the
  hot path.
- **Possible Severity**: HIGH (gen0 > 1000/sec or allocation rate >
  500MB/sec) – MEDIUM (below that, still above baseline).
- **False Positives**: allocation spike from a one-off admin/batch
  operation, not the request path under review.
- **Remediation**: pool/reuse buffers (`ArrayPool<T>`), reduce boxing,
  avoid LINQ intermediate enumerables in the hot path (see
  `references/performance.md` for the static shapes).
- **Verification**: allocation rate re-measured after fix.

## RT-CRAP-001 — High CRAP score on the latency-critical path

- **Detection**: a method in the top-10 latency contributors (by trace
  span duration) has a CRAP score above threshold.
- **Context**: CRAP formula and thresholds are defined once in
  `references/testing.md` (`ANB-TEST-010`) — reused here, not redefined.
- **Evidence Required**: the trace ranking and the CRAP score.
- **Typical Impact**: the method most likely to regress under change is
  also the one contributing most to latency.
- **Possible Severity**: HIGH (CRAP > 20 on a top-10 contributor) –
  CRITICAL (CRAP > 30 on the top-3 contributor).
- **Remediation**: split the method, raise coverage before optimising
  further (see `references/testing.md` for the practical rule of thumb).
- **Verification**: CRAP re-measured; latency re-profiled after refactor.
