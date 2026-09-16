# Test — Anubis / architecture

## Input

```csharp
// Infrastructure project references Domain; Domain references Infrastructure
public class OrderService
{
    private static OrderService _instance;                 // static singleton
    public static OrderService Instance => _instance;

    public void Handle(Order order)
    {
        var repo = new SqlOrderRepository();               // new to concrete type
        var provider = Program.Services;                   // service locator
        var db = provider.GetService(typeof(AppDbContext)); // captive DbContext
        using var tx = ((AppDbContext)db).Database.BeginTransaction();
        repo.Save(order);
        _mapper.Map(order);                                // data type leaking out
    }
}
```

## Expected Findings

| ID | Title |
| --- | --- |
| `ANB-ARCH-001` | Layering violation (Infrastructure ↔ Domain cycle) |
| `ANB-ARCH-002` | Dependency on a concrete type (`new SqlOrderRepository()`) |
| `ANB-ARCH-003` | Service locator / static access |
| `ANB-ARCH-007` | `DbContext` lifetime misuse |
| `ANB-ARCH-010` | Transaction boundary handled ad hoc / missing ownership |

## Expected Severity

- `ANB-ARCH-001` — `HIGH`
- `ANB-ARCH-002` — `MEDIUM`
- `ANB-ARCH-003` — `MEDIUM`
- `ANB-ARCH-007` — `CRITICAL` (only if the container scope proves captive; without
  registration evidence downgrade to `MEDIUM` / `confidence: LOW`)
- `ANB-ARCH-010` — `HIGH`

## Expected Confidence

- `ANB-ARCH-001` — `HIGH` if project references are inspectable, else `MEDIUM`.
- `ANB-ARCH-007` — `MEDIUM` unless DI registration is visible (`HIGH`).

## Expected Handoff

`none` unless the transaction/lifetime issue implies a delivery risk, in which
case document it as a `Rischi` item (no DevOps handoff for pure code design).

## Expected Non-Findings

- The `using var tx` must **not** be flagged as a missing `Dispose`
  (`ANB-DOTNET-005`); it is correctly scoped.
- Static singleton alone must not be reported as `ANB-PERF-*`.
