# Test — Anubis-Runtime / N+1

## Input

```csharp
var products = await _db.Products.Where(p => p.CategoryId == categoryId).ToListAsync();
foreach (var p in products)
{
    result.Add(new ProductDto { Name = p.Name, SupplierName = p.Supplier.Name });
}
```

```text
Trace: 1 query (Products, 40 rows) + 40x "SELECT Suppliers WHERE Id=?" (360ms of 412ms total)
```

## Expected Findings

| ID | Title |
| --- | --- |
| `RT-N1-001` | N+1 confirmed by trace (Supplier lazy-loaded per product) |

## Expected Severity

- `RT-N1-001` — `HIGH` (N=40, in the 10 < N range described as HIGH;
  reserve `CRITICAL` for N >> 1, e.g. hundreds/thousands).

## Expected Confidence

- `RT-N1-001` — `HIGH` (trace directly attributes the 40 queries to this
  request).

## Expected Handoff

`anubis-devops` if a query-count regression test should be added to the
pipeline; `none` if the fix and a local test are sufficient.

## Expected Non-Findings

- Must **not** report `ANB-EFCORE-001` in addition to `RT-N1-001` for
  the same evidence — once trace evidence confirms the pattern, it is
  reported once under the `RT-N1-*` id, not duplicated under the static
  `ANB-EFCORE-*` id.
