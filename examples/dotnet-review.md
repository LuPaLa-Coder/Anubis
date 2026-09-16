# Example — .NET review

Worked Full Review demonstrating the output shape:
Input · Evidence · Finding · Severity · Confidence · Remediation · Verification.

## Input

```csharp
// src/Services/OrderService.cs
public class OrderService
{
    private const string ConnectionString =
        "Server=prod-sql.database.windows.net;User Id=app;Password=P@ssw0rd!";

    public void Process(Order order)
    {
        var total = GetTotalAsync(order.Id).Result;          // sync-over-async
        SendConfirmation(order.CustomerEmail);               // async void
        using var conn = new SqlConnection(ConnectionString);
        conn.Open();
        var cmd = new SqlCommand(
            "UPDATE Orders SET Total=" + total + " WHERE Id=" + order.Id, conn);
        cmd.ExecuteNonQuery();
    }

    private async void SendConfirmation(string email)        // async void
    {
        await _mailer.SendAsync(email, "Order confirmed");
    }
}
```

## Evidence

- `OrderService.cs:3-4` — literal connection string including password.
- `OrderService.cs:10` — `.Result` on `GetTotalAsync` inside a synchronous method.
- `OrderService.cs:11` / `:17` — `async void SendConfirmation`.
- `OrderService.cs:14` — SQL built by string concatenation with `order.Id`.

## Findings

### ANB-SEC-002 — Hardcoded connection string with password — CRITICAL / HIGH

- **Evidence**: `Password=P@ssw0rd!` literal at line 3-4.
- **Impact**: production SQL credential in VCS; full DB compromise, and it is now
  in git history.
- **Recommendation**: move to a secret manager; never store credentials in source.
- **Fix**: read from configuration bound to Key Vault / environment:
  ```csharp
  public OrderService(IConfiguration cfg) =>
      _connectionString = cfg.GetConnectionString("Orders")
          ?? throw new InvalidOperationException("Orders connection missing");
  ```
- **Migration**: rotate the leaked credential; purge via secret scanning; enforce
  secret scanning in CI.
- **Verification**: secret scanning (GHAS / gitleaks) + configuration review.

### ANB-SEC-001 — SQL injection via string concatenation — CRITICAL / HIGH

- **Evidence**: `"UPDATE Orders SET Total=" + total + " WHERE Id=" + order.Id`.
- **Impact**: injectable query; data corruption/breach.
- **Recommendation**: parameterise.
- **Fix**:
  ```csharp
  await using var cmd = new SqlCommand(
      "UPDATE Orders SET Total=@total WHERE Id=@id", conn);
  cmd.Parameters.AddWithValue("@total", total);
  cmd.Parameters.AddWithValue("@id", order.Id);
  ```
- **Migration**: migrate the data access to EF Core / Dapper with parameters.
- **Verification**: security regression test with a `'; DROP TABLE` payload.

### ANB-DOTNET-002 — Sync-over-async (`.Result`) — HIGH / HIGH

- **Evidence**: `GetTotalAsync(order.Id).Result`.
- **Impact**: deadlock/thread starvation under ASP.NET load.
- **Fix**: make `Process` `async Task` and `await GetTotalAsync(...)`.
- **Verification**: integration test; static analysis rule.

### ANB-DOTNET-001 — `async void` — HIGH / HIGH

- **Evidence**: `private async void SendConfirmation(...)`.
- **Impact**: unobservable exceptions → process crash or silent failure.
- **Fix**: return `async Task` and `await` it from an async `Process`.
- **Verification**: unit test asserting exception propagation.

## Rejected candidate (false positive)

- Candidate: `ANB-DOTNET-002` on `conn.Open()` (synchronous ADO.NET call).
- The evidence proves it is a **synchronous** method, so there is no
  sync-over-async there; it is instead reported as `ANB-DOTNET-012` (blocking
  I/O on an async path) only after `Process` becomes async. Recorded as a
  rejected candidate for `ANB-DOTNET-002`; **no finding emitted** for that rule.

## Severity summary

| Severity | Count |
| --- | --- |
| CRITICAL | 2 |
| HIGH | 2 |
| MEDIUM | 0 |
| LOW | 0 |

False positives rejected: 1.

## Handoff

```yaml
handoff:
  target: anubis-devops
  reason: the connection string and SQL command touch build/config and secret handling
  findings: [ANB-SEC-002, ANB-SEC-001]
  files: [src/Services/OrderService.cs, appsettings.json]
  required_context: [configuration sources, pipeline secret handling]
  artifacts: [review report]
```
