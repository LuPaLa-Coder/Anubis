# Example — Security review

Frontend of a security-focused review. Input · Evidence · Finding · Severity ·
Confidence · Remediation · Verification.

## Input

```csharp
// src/Controllers/InvoiceController.cs
[HttpGet("download")]
[AllowAnonymous]
public IActionResult Download(string fileName)
{
    var path = Path.Combine("/var/invoices", fileName);
    return File(System.IO.File.ReadAllBytes(path), "application/pdf");
}

// src/Services/UserService.cs
public string HashPassword(string password)
{
    using var md5 = MD5.Create();
    return Convert.ToBase64String(md5.ComputeHash(Encoding.UTF8.GetBytes(password)));
}
```

## Evidence

- `InvoiceController.cs:2` — `[AllowAnonymous]` on a data-returning endpoint.
- `InvoiceController.cs:5` — user-controlled `fileName` combined into a path.
- `UserService.cs:12` — `MD5` used for password hashing.

## Findings

### ANB-SEC-007 — Path traversal — CRITICAL / HIGH

- **Evidence**: `Path.Combine("/var/invoices", fileName)` with no containment check.
- **Impact**: `fileName = "../../etc/passwd"` reads arbitrary files.
- **Recommendation**: never trust a client-supplied path.
- **Fix**:
  ```csharp
  var root = "/var/invoices";
  var full = Path.GetFullPath(Path.Combine(root, fileName));
  if (!full.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.Ordinal))
      return BadRequest();
  ```
- **Verification**: security regression test with `../` payloads.

### ANB-SEC-012 — Overly broad authorization — HIGH / MEDIUM

- **Evidence**: `[AllowAnonymous]` on `Download`.
- **Impact**: unauthenticated invoice retrieval (IDOR/data exposure).
- **Recommendation**: require authentication + ownership check.
- **Verification**: authorization integration test (401/403).

### ANB-SEC-005 — Weak password hashing (MD5) — CRITICAL / HIGH

- **Evidence**: `MD5.Create()` in `HashPassword`.
- **Impact**: unsalted, fast hash; rainbow-table cracking of the password store.
- **Recommendation**: use Argon2id / bcrypt with a per-user salt.
- **Fix**:
  ```csharp
  using var hasher = new Argon2id();
  return hasher.Hash(password);   // vetted library, per-user salt
  ```
- **Migration**: rehash on next successful login; force reset for stale hashes.
- **Verification**: security regression test asserting algorithm + salt; crypto review.

## Severity summary

| Severity | Count |
| --- | --- |
| CRITICAL | 2 |
| HIGH | 1 |
| MEDIUM | 0 |
| LOW | 0 |

False positives rejected: 0.

## Handoff

```yaml
handoff:
  target: none
  reason: review is self-sufficient
  findings: []
  files: []
  required_context: []
  artifacts: [review report]
```
