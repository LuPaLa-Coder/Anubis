# Test — Anubis / false positive

Purpose: prove the review rejects candidates that match a pattern but whose
context neutralises the risk, and never emits them as findings.

## Input

```csharp
public class Sample
{
    // Documentation example — placeholder, not a real credential
    // Password: "changeme-on-first-login"

    [TestMethod]
    public void Reads_key_from_environment()
    {
        var key = Environment.GetEnvironmentVariable("API_KEY")
                  ?? throw new InvalidOperationException("API_KEY not set");
        Assert.IsNotNull(key);
    }

    public string Normalize(string s) => s.ToUpperInvariant(); // culture-safe
}
```

## Expected Findings

None. Every candidate is a documented false positive.

## Expected Non-Findings (rejected candidates, with reason)

| Candidate | Reason for rejection |
| --- | --- |
| `ANB-SEC-002` (hardcoded credential) on `"changeme-on-first-login"` | documentation/placeholder comment, not a real secret |
| `ANB-SEC-002` on `API_KEY` | value is read from the environment, not hardcoded |
| `ANB-DOTNET-008` (culture-sensitive string) on `ToUpperInvariant()` | `Invariant` is the culture-safe form, explicitly correct |
| `ANB-TEST-002` (test not sealed) | `Sample` is a snippet, not a complete test class file |

## Expected Severity

N/A (no findings).

## Expected Confidence

N/A.

## Expected Handoff

`none`. `summary.false_positives_rejected` must equal the number of rejected
candidates (4).

## Rule

`NO EVIDENCE = NO FINDING`. A candidate whose context shows the risk is absent
must be recorded as rejected, never promoted to a finding and never silently
dropped.
