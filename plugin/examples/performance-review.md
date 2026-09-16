# Example — Performance review

Input · Evidence · Finding · Severity · Confidence · Remediation · Verification.

## Input

```csharp
// src/Reporting/ReportService.cs
public async Task<Report> BuildAsync(int customerId)
{
    var customer = await _db.Customers.FindAsync(customerId);
    var orders = await _db.Orders.Where(o => o.CustomerId == customerId).ToListAsync();

    var sb = "";
    foreach (var order in orders)
    {
        // navigation access without Include -> N+1
        var name = order.Product.Name;
        sb += $"{order.Id}:{name};";
    }

    var lines = await _db.OrderLines
        .Where(l => l.Order.CustomerId == customerId)
        .ToListAsync()
        .ContinueWith(t => t.Result.Where(l => l.Quantity > 0).ToList());

    return new Report(customer, sb, lines);
}
```

## Evidence

- `ReportService.cs:9` — `order.Product.Name` inside the loop, `Product` not loaded.
- `ReportService.cs:10` — `sb += ...` inside the loop.
- `ReportService.cs:13-16` — `.ToListAsync()` before `.Where(l => l.Quantity > 0)`,
  plus `.Result` inside `ContinueWith`.

## Findings

### ANB-EFCORE-001 — N+1 via navigation access — HIGH / HIGH

- **Evidence**: `order.Product.Name` in the loop; no `Include`/projection.
- **Impact**: 1 query per order; latency scales with order count.
- **Fix**:
  ```csharp
  var orders = await _db.Orders
      .Where(o => o.CustomerId == customerId)
      .Select(o => new { o.Id, ProductName = o.Product.Name })
      .ToListAsync();
  ```
- **Verification**: query-count assertion (EF logging) in an integration test.

### ANB-PERF-002 — `string +=` in a loop — HIGH / HIGH

- **Evidence**: `sb += $"{order.Id}:{name};"` inside `foreach`.
- **Impact**: O(n²) allocations and GC pressure.
- **Fix**: use `StringBuilder`, or `string.Join` over a projected list.
- **Verification**: allocation benchmark / profiler.

### ANB-EFCORE-002 — `ToList()` before `Where()` — HIGH / HIGH

- **Evidence**: materialisation then in-memory filter.
- **Impact**: fetches all order lines, filters in memory.
- **Fix**: filter server-side before materialising.
- **Verification**: SQL inspection; query logging.

### ANB-DOTNET-002 — `.Result` inside `ContinueWith` — HIGH / MEDIUM

- **Evidence**: `t.Result.Where(...)`.
- **Impact**: blocks a pool thread; can deadlock.
- **Fix**: `await` the query, then filter in memory only if required.
- **Verification**: integration test; static analysis.

## Rejected candidate (false positive)

- Candidate: `ANB-PERF-005` (collection without capacity) on
  `.Select(...).ToList()`.
- The final size is not known before the query, so passing a capacity is not
  possible; the evidence (unknown size) neutralises the pattern. Rejected, no
  finding.

## Severity summary

| Severity | Count |
| --- | --- |
| CRITICAL | 0 |
| HIGH | 3 |
| MEDIUM | 1 |
| LOW | 0 |

False positives rejected: 1.

## Handoff

```yaml
handoff:
  target: none
  reason: application-level performance only; no pipeline impact
  findings: []
  files: []
  required_context: []
  artifacts: [review report, benchmark plan]
```
