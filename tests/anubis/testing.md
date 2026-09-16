# Test — Anubis / testing

## Input

```xml
<!-- tests/App.Tests/App.Tests.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
  <ItemGroup>
    <PackageReference Include="MSTest.TestFramework" Version="3.6.0" />
    <PackageReference Include="MSTest.TestAdapter" Version="3.6.0" />
  </ItemGroup>
</Project>
```

```csharp
public class OrderTests               // not sealed
{
    public TestContext TestContext { get; set; }   // property instead of ctor

    [TestInitialize]
    public void Setup() { }

    [TestMethod]
    public void Valid_order_succeeds()
    {
        var result = Create();
        Assert.AreEqual(result, "ok");             // wrong argument order
        Thread.Sleep(500);                         // async sync hack
        Assert.ThrowsException<InvalidOperationException>(() => Bad());
    }
}
```

## Expected Findings

| ID | Title |
| --- | --- |
| `ANB-TEST-001` | `MSTest.Sdk` not used (separate package references) |
| `ANB-TEST-002` | Test class not `sealed` |
| `ANB-TEST-003` | `[TestInitialize]` instead of constructor |
| `ANB-TEST-009` | `TestContext` via property instead of constructor |
| `ANB-TEST-004` | `Assert.AreEqual(actual, expected)` order |
| `ANB-TEST-007` | `Thread.Sleep` for async synchronisation |
| `ANB-TEST-005` | `ThrowsException` instead of `ThrowsExactly` |

## Expected Severity

- `ANB-TEST-001` — `MEDIUM`
- `ANB-TEST-002` / `003` / `004` / `005` / `009` — `LOW`
- `ANB-TEST-007` — `MEDIUM`

## Expected Confidence

All `HIGH` (statically visible).

## Expected Handoff

`none`.

## Expected Non-Findings

- Do not report `ANB-DOTNET-*` for `Thread.Sleep`; the testing family owns it.
- If a test genuinely mixes setup in `[TestInitialize]` for non-deterministic
  reasons, `ANB-TEST-003` is rejected with a stated reason.
