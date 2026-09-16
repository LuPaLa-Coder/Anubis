# Test — Anubis / security

## Input

```csharp
public IActionResult Get(string id)
{
    var sql = "SELECT * FROM Users WHERE Id = " + id;
    var user = _db.Database.ExecuteSqlRaw(sql);
    Console.WriteLine("conn=" + _connString + " user=" + user);
    return Ok(user);
}
// _connString = "Server=...;Password=Prod#123;"
```

## Expected Findings

| ID | Title |
| --- | --- |
| `ANB-SEC-001` | SQL injection via string concatenation |
| `ANB-SEC-002` | Hardcoded credential / connection string |
| `ANB-SEC-003` | Sensitive data written to log |

## Expected Severity

- `ANB-SEC-001` — `CRITICAL`
- `ANB-SEC-002` — `CRITICAL`
- `ANB-SEC-003` — `HIGH`

## Expected Confidence

- `ANB-SEC-001` — `HIGH` (sink and source visible)
- `ANB-SEC-002` — `HIGH` (literal visible)
- `ANB-SEC-003` — `HIGH`

## Expected Handoff

`target: anubis-devops` if the credential also appears in pipeline/build config;
otherwise `none`. Every finding must define a verification method.

## Expected Non-Findings

- No finding for `Ok(user)` serialisation unless evidence of over-posting exists.
- `ANB-SEC-002` must mask the secret value in the report (line + key only).
