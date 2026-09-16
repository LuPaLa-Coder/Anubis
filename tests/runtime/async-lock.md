# Test — Anubis-Runtime / async & lock

## Input

```csharp
public void Process(Order order)
{
    lock (_gate)
    {
        var total = _pricing.GetTotalAsync(order.Id).Result;  // sync-over-async inside a lock
        order.Total = total;
    }
}
```

```text
Thread dump under load: 6 threads blocked on `_gate`; the holder thread
is itself blocked awaiting `GetTotalAsync` on a starved thread pool.
Request timeout after 30s (hang confirmed).
```

## Expected Findings

| ID | Title |
| --- | --- |
| `RT-LOCK-002` | `lock` around I/O (blocking async call inside a lock, thread-pool starvation) |
| `RT-ASYNC-001` | Deadlock risk: `.Result` in a blocking context |

## Expected Severity

- `RT-LOCK-002` — `CRITICAL` (hold time unbounded, confirmed hang)
- `RT-ASYNC-001` — `CRITICAL`

## Expected Confidence

- Both — `HIGH` (thread dump and timeout directly confirm the hang).

## Expected Handoff

`none` — this is a self-contained code fix with a concurrency test as
verification; escalate to `human` only if the fix requires an API
contract change agreed elsewhere.

## Expected Non-Findings

- Must **not** report `RT-LOCK-001` (nested locks without global order):
  there is only one lock involved here, not a multi-lock ordering issue.
