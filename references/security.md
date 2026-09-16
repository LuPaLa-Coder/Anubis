# Reference — Application security

Pattern catalogue for `Anubis`. Candidates only; apply Evidence First
(`references/review-protocol.md`). Family: `ANB-SEC`. DevOps pipeline secrets are
out of scope here (see `Anubis-devops`).

---

## ANB-SEC-001 — SQL / command injection

- **Detection**: string concatenation or interpolation into SQL; `FromSqlRaw`
  with interpolated strings; `Process.Start` built from user input.
- **Context**: untrusted input reaching a query or shell.
- **Evidence Required**: the sink and the untrusted source, with the data flow.
- **Typical Impact**: data breach, data loss, remote code execution.
- **Possible Severity**: CRITICAL.
- **False Positives**: constant strings; `FromSqlInterpolated` with parameters.
- **Remediation**: parameterised queries (`FromSqlInterpolated`, `SqlParameter`),
  EF LINQ; never concatenate.
- **Verification**: security regression test with a malicious payload.
- **CWE**: CWE-89, CWE-78.

## ANB-SEC-002 — Hardcoded credentials / secrets

- **Detection**: literal passwords, API keys, connection strings, tokens in
  source or config.
- **Evidence Required**: the literal (mask the value; show key name + line).
- **Typical Impact**: credential compromise; secrets in VCS history.
- **Possible Severity**: CRITICAL.
- **False Positives**: placeholders in samples/tests; `appsettings.Development`.
- **Remediation**: secret manager / Key Vault / environment; rotate the leaked
  secret.
- **Verification**: secret scanning (e.g. GHAS, gitleaks); config review.
- **CWE**: CWE-798.

## ANB-SEC-003 — Sensitive data in logs

- **Detection**: logging passwords, tokens, PII, full connection strings.
- **Evidence Required**: the log call and the sensitive value.
- **Typical Impact**: credential/PII exposure via log aggregation.
- **Possible Severity**: HIGH (CRITICAL for regulated PII).
- **Remediation**: redact, log identifiers not values; structured logging with
  explicit fields.
- **Verification**: log-scrubbing test.
- **CWE**: CWE-532.

## ANB-SEC-004 — Missing input validation

- **Detection**: external input bound without validation; `[FromBody]`/query
  params used unchecked; missing length/range/format checks.
- **Evidence Required**: the entry point and the missing validation.
- **Typical Impact**: injection, DoS, business-rule bypass.
- **Possible Severity**: MEDIUM–HIGH.
- **Remediation**: FluentValidation / DataAnnotations at the boundary; reject by
  default.
- **Verification**: unit tests for invalid inputs; fuzzing.
- **CWE**: CWE-20.

## ANB-SEC-005 — Weak / misused cryptography

- **Detection**: MD5/SHA1 for passwords, DES/3DES, ECB mode, static IV, custom
  crypto, `Rfc2898` with weak iterations.
- **Evidence Required**: the algorithm and its use.
- **Typical Impact**: password cracking, data decryption.
- **Possible Severity**: CRITICAL.
- **Remediation**: Argon2/bcrypt for passwords; AES-GCM; vetted libraries.
- **Verification**: security regression test; crypto review.
- **CWE**: CWE-327, CWE-916.

## ANB-SEC-006 — Insecure randomness

- **Detection**: `System.Random` for tokens, secrets, salts, nonces.
- **Evidence Required**: the `Random` usage and the security intent.
- **Typical Impact**: predictable tokens.
- **Possible Severity**: HIGH.
- **Remediation**: `RandomNumberGenerator`.
- **Verification**: security regression test.
- **CWE**: CWE-338.

## ANB-SEC-007 — Path traversal

- **Detection**: user input joined to a filesystem path; `Path.Combine` with
  untrusted segments; missing canonicalisation.
- **Evidence Required**: the path construction and the input source.
- **Typical Impact**: arbitrary file read/write.
- **Possible Severity**: HIGH–CRITICAL.
- **Remediation**: allow-list, `Path.GetFullPath` containment check.
- **Verification**: security regression test with `../` payloads.
- **CWE**: CWE-22.

## ANB-SEC-008 — XXE / unsafe XML

- **Detection**: `XmlDocument`, `XmlReader` with DTD/entities enabled.
- **Evidence Required**: the reader configuration.
- **Typical Impact**: file disclosure, SSRF, DoS.
- **Possible Severity**: HIGH.
- **Remediation**: `DtdProcessing = Prohibit`, `XmlResolver = null`.
- **Verification**: malicious-XML regression test.
- **CWE**: CWE-611.

## ANB-SEC-009 — Insecure deserialization

- **Detection**: `BinaryFormatter`, `NetDataContractSerializer`, polymorphic JSON
  with untrusted input and type handling.
- **Evidence Required**: the deserializer and its input source.
- **Typical Impact**: remote code execution.
- **Possible Severity**: CRITICAL.
- **Remediation**: `System.Text.Json` with explicit contracts; no type metadata.
- **Verification**: security regression test.
- **CWE**: CWE-502.

## ANB-SEC-010 — Overly permissive CORS

- **Detection**: `AllowAnyOrigin` + credentials; `AllowAnyOrigin/Header/Method`.
- **Evidence Required**: the CORS policy and its consumer.
- **Typical Impact**: cross-site data exposure.
- **Possible Severity**: MEDIUM–HIGH.
- **Remediation**: explicit allow-list per environment.
- **Verification**: integration test on the CORS preflight.
- **CWE**: CWE-942.

## ANB-SEC-011 — TLS validation disabled

- **Detection**: `ServerCertificateCustomValidationCallback` returning `true`,
  `ServicePointManager` bypass.
- **Evidence Required**: the callback/policy.
- **Typical Impact**: MITM.
- **Possible Severity**: CRITICAL.
- **Remediation**: validate certificates; pin only with a documented rotation plan.
- **Verification**: security regression test.
- **CWE**: CWE-295.

## ANB-SEC-012 — Overly broad authorization

- **Detection**: `[AllowAnonymous]` on sensitive endpoints, role checks missing,
  IDOR (object referenced without ownership check).
- **Evidence Required**: the endpoint and the missing check.
- **Typical Impact**: privilege escalation, data exposure.
- **Possible Severity**: HIGH–CRITICAL.
- **Remediation**: deny by default, explicit policies, ownership validation.
- **Verification**: authorization integration tests.
- **CWE**: CWE-862, CWE-639.
