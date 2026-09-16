# Test — Anubis / performance

## Input

```csharp
public async Task ProcessAllAsync(IEnumerable<Order> orders)
{
    await Task.WhenAll(orders.Select(async o => await _api.SendAsync(o)));

    var text = "";
    foreach (var o in orders) text += o.Id.ToString();

    var emails = await _db.Customers.ToListAsync();
    var active = emails.Where(c => c.IsActive).Count() > 0;
}
```

## Expected Findings

| ID | Title |
| --- | --- |
| `ANB-PERF-001` | Unbounded concurrency in `Task.WhenAll` |
| `ANB-PERF-002` | `string +=` in a loop |
| `ANB-PERF-010` | Materialise-before-filter (`ToListAsync` then `Where`) |
| `ANB-DOTNET-010` | `Count() > 0` instead of `Any()` |

## Expected Severity

- `ANB-PERF-001` — `HIGH` if the input size is unbounded, else `MEDIUM`.
- `ANB-PERF-002` — `HIGH`.
- `ANB-PERF-010` — `HIGH`.
- `ANB-DOTNET-010` — `MEDIUM`.

## Expected Confidence

- `ANB-PERF-001` — `MEDIUM` (depends on runtime input size).
- `ANB-PERF-002` — `HIGH`.
- `ANB-PERF-010` — `HIGH`.
- `ANB-DOTNET-010` — `HIGH`.

## Expected Handoff

`none` (application performance only).

## Expected Non-Findings

- If `orders` is proven to be a bounded, small, known collection, `ANB-PERF-001`
  must be rejected as a false positive (documented bounded fan-out), not emitted.
- `ANB-PERF-005` (capacity) must not fire when the collection size is unknown.

## Note

After `WhenAll`, any `.Result` would surface only the first exception, not the
full `AggregateException`; if present it must be flagged under `ANB-DOTNET-002`
with that explanation as `impact`.
