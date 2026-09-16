# Reference — Performance

Pattern catalogue for `Anubis`. Family: `ANB-PERF`. Evidence First applies:
allocations and hot paths must be evidenced, not assumed.

---

## ANB-PERF-001 — Unbounded concurrency

- **Detection**: `Task.WhenAll(list.Select(async ...))` without throttling.
- **Context**: fan-out to I/O or CPU without a concurrency cap.
- **Evidence Required**: the fan-out and the collection size/source.
- **Typical Impact**: thread-pool starvation, socket exhaustion, outage.
- **Possible Severity**: HIGH.
- **False Positives**: bounded, small, known-size collections.
- **Remediation**: `Parallel.ForEachAsync` with `MaxDegreeOfParallelism`, or
  `SemaphoreSlim`.
- **Verification**: load test; concurrency benchmark.
- Note: after `WhenAll`, `.Result` surfaces only the first exception, not the
  full `AggregateException`.

## ANB-PERF-002 — `string +=` in a loop

- **Detection**: cumulative string concatenation inside a loop or large join.
- **Evidence Required**: the loop and the accumulation.
- **Typical Impact**: O(n²) allocations; GC pressure.
- **Possible Severity**: HIGH.
- **Remediation**: `StringBuilder` or `string.Create`/`string.Join`.
- **Verification**: benchmark or allocation profiler.

## ANB-PERF-003 — `new Regex` per call

- **Detection**: regex constructed inside a method invoked frequently.
- **Evidence Required**: construction inside a hot path.
- **Typical Impact**: repeated compilation; allocations.
- **Possible Severity**: MEDIUM.
- **Remediation**: `static readonly Regex` or `[GeneratedRegex]`.
- **Verification**: benchmark.

## ANB-PERF-004 — `Substring` in hot path

- **Detection**: `.Substring(...)` on high-frequency paths.
- **Evidence Required**: the call site frequency.
- **Typical Impact**: string allocation per call.
- **Possible Severity**: MEDIUM.
- **Remediation**: `AsSpan().Slice()`.
- **Verification**: benchmark.

## ANB-PERF-005 — Collection without initial capacity

- **Detection**: `new List<T>()` / `new Dictionary<K,V>()` with a known size.
- **Evidence Required**: the known/derivable size.
- **Typical Impact**: repeated re-allocations and copies.
- **Possible Severity**: LOW–MEDIUM.
- **Remediation**: pass capacity.
- **Verification**: benchmark.

## ANB-PERF-006 — Non-`sealed` concrete class

- **Detection**: concrete classes not `sealed`, no inheritance.
- **Evidence Required**: absence of derived types.
- **Typical Impact**: minor vtable / devirtualization overhead.
- **Possible Severity**: LOW.
- **Remediation**: `sealed`.
- **Verification**: benchmark / code review.

## ANB-PERF-007 — `params T[]` on hot methods

- **Detection**: `params` array parameters called in tight loops.
- **Evidence Required**: the call frequency.
- **Typical Impact**: array allocation per call.
- **Possible Severity**: LOW.
- **Remediation**: specific overloads or `ReadOnlySpan<T>`.
- **Verification**: benchmark.

## ANB-PERF-008 — `static readonly Dictionary` on hot read path

- **Detection**: read-mostly dictionary lookups on a hot path.
- **Evidence Required**: the read path.
- **Typical Impact**: unnecessary hashing overhead / lock-free benefit missed.
- **Possible Severity**: LOW.
- **Remediation**: `FrozenDictionary<K,V>` (.NET 8+).
- **Verification**: benchmark.

## ANB-PERF-009 — `RegexOptions.Compiled` at scale

- **Detection**: many distinct compiled regexes (>~10).
- **Evidence Required**: count and usage.
- **Typical Impact**: high memory / JIT cost.
- **Possible Severity**: LOW.
- **Remediation**: `[GeneratedRegex]` source generator.
- **Verification**: startup benchmark; memory profile.

## ANB-PERF-010 — Materialising before filtering

- **Detection**: `.ToList()`/`.ToArray()` before a `.Where(...)`, or repeated
  `Where` over a materialised collection.
- **Evidence Required**: the materialisation and the later filter.
- **Typical Impact**: extra memory and work proportional to the unfiltered set.
- **Possible Severity**: MEDIUM–HIGH.
- **Remediation**: filter first, materialise last. See also `ANB-EFCORE-002`.
- **Verification**: benchmark; query plan.

## ANB-PERF-011 — Synchronous I/O on a hot path

- **Detection**: blocking file/network/DB calls under load.
- **Evidence Required**: the call and its frequency.
- **Typical Impact**: thread-pool starvation.
- **Possible Severity**: MEDIUM.
- **Remediation**: async I/O. See `ANB-DOTNET-012`.
- **Verification**: load test.

## ANB-PERF-012 — Boxing / struct copies through abstraction

- **Detection**: value types passed as `object`/interface on hot paths;
  `foreach` over `List<T>` causing copies of large structs.
- **Evidence Required**: the hot path and the conversion.
- **Typical Impact**: allocations and copies.
- **Possible Severity**: LOW–MEDIUM.
- **Remediation**: generics with constraints; `ref`/`in` parameters.
- **Verification**: benchmark; allocation profiler.
