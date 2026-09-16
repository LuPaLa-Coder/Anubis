# Example — Runtime performance review

Worked Full Review demonstrating the output shape:
Input · Evidence · Finding · Severity · Confidence · Remediation · Verification.

## Input

```csharp
// src/Services/CatalogService.cs
public async Task<List<ProductDto>> GetProductsAsync(int categoryId)
{
    var products = await _db.Products
        .Where(p => p.CategoryId == categoryId)
        .ToListAsync();

    var result = new List<ProductDto>();
    foreach (var p in products)
    {
        result.Add(new ProductDto
        {
            Name = p.Name,
            SupplierName = p.Supplier.Name   // lazy navigation
        });
    }
    return result;
}
```

```text
# OpenTelemetry trace excerpt, GET /api/catalog?categoryId=12
span "GetProductsAsync"           412ms
  span "SELECT Products WHERE CategoryId=12"   8ms   (1 query, 40 rows)
  span "SELECT Suppliers WHERE Id=?"           9ms   x 40  (360ms total)
```

## Evidence

- `CatalogService.cs:10` — `foreach` accessing `p.Supplier.Name`, a lazy
  navigation property, inside the loop.
- Trace: 1 query for products, followed by 40 near-identical
  `SELECT Suppliers WHERE Id=?` spans — confirmed N+1, not just a static
  shape.

## Findings

### RT-N1-001 — N+1 confirmed by trace (Supplier lazy-loaded per product) — HIGH / HIGH

- **Evidence**: trace shows 40 `SELECT Suppliers` queries for one
  `GetProductsAsync` call (categoryId=12, 40 rows); 360ms of the 412ms
  total span is these 40 queries.
- **Impact**: latency scales linearly with result-set size; at 40 rows
  it is already 87% of the endpoint's total time.
- **Recommendation**: eager-load `Supplier` in the original query instead
  of accessing it lazily inside the loop.
- **Fix**:
  ```csharp
  var products = await _db.Products
      .Where(p => p.CategoryId == categoryId)
      .Include(p => p.Supplier)
      .ToListAsync();
  ```
- **Verification**: re-run the same request; trace shows 1 query
  instead of 41; add a regression test asserting query count ≤ 2 for
  this endpoint.

## Rejected candidate (false positive)

- Candidate: `RT-MEM-003` (GC pressure) on the `new List<ProductDto>()`
  allocation inside the loop. The allocation rate measured for this
  endpoint (40 small DTOs per call) is far below the GRN threshold
  (gen0 > 1000/sec) and contributes < 1% of the span's own timing —
  the actual cost is entirely the N+1 queries above. No finding emitted
  for `RT-MEM-003`; recorded as a rejected candidate.

## Severity summary

| Severity | Count |
| --- | --- |
| CRITICAL | 0 |
| HIGH | 1 |
| MEDIUM | 0 |
| LOW | 0 |

False positives rejected: 1.

## Handoff

```yaml
handoff:
  target: anubis-devops
  reason: a query-count regression test should be added to the pipeline to prevent this N+1 from reappearing
  findings: [RT-N1-001]
  files: [src/Services/CatalogService.cs]
  required_context: [existing integration test suite location, CI stage for performance regression tests]
  artifacts: [review report, trace excerpt]
```
