# Reference — NetArchTest rule generation

Checklist and worked example for `Anubis-Arch` when generating
enforcement tests for `ARCH-LAYER-*` findings
(`references/architecture-governance.md`).

## Checklist (mandatory before proposing rules)

- [ ] Layer isolation rules (no back-references)
- [ ] Namespace convention rules
- [ ] Forbidden type rules (e.g. no `HttpClient` in Domain, no
      `DbContext` outside Infrastructure)
- [ ] Naming convention rules (e.g. `Service`, `Repository`, `Handler`
      suffixes)
- [ ] Sealed-class enforcement for concrete implementations
- [ ] Custom, organisation-specific governance rules

## Technical note — cycle detection

NetArchTest does **not** expose a `BeAcyclicGraph()` method or
equivalent. Dependency-cycle detection (`ARCH-LAYER-002`) must use a
dedicated tool as a separate CI step:

```bash
dotnet list <solution>.sln package --include-transitive --vulnerable
dotnet list <solution>.sln package --outdated
```

plus `NDepend`, `dependency-cruiser`, or `Roslynator.Analyzers` for
project/type-level cycle detection. NetArchTest rules below are limited
to explicit, directional dependency constraints between namespaces.

## Worked example

```csharp
[TestClass]
public sealed class ArchitectureTests
{
    [TestMethod]
    public void Domain_Should_Not_Depend_On_Application()
    {
        var result = Types.InNamespace("MyApp.Domain")
            .Should().NotDependOnAny("MyApp.Application")
            .GetResult();
        Assert.IsTrue(result.IsSuccessful, result.FailingTypeNames is null
            ? string.Empty
            : string.Join(", ", result.FailingTypeNames));
    }

    [TestMethod]
    public void Domain_Should_Not_Reference_EntityFramework()
    {
        var result = Types.InNamespace("MyApp.Domain")
            .ShouldNot().HaveDependencyOn("Microsoft.EntityFrameworkCore")
            .GetResult();
        Assert.IsTrue(result.IsSuccessful);
    }

    [TestMethod]
    public void Services_Should_Be_In_Service_Namespace()
    {
        var result = Types.That()
            .HaveNameEndingWith("Service")
            .Should().ResideInNamespaceMatching(@".*\.Services(\..*)?$")
            .GetResult();
        Assert.IsTrue(result.IsSuccessful);
    }

    [TestMethod]
    public void Handlers_Should_Be_Sealed()
    {
        var result = Types.That()
            .HaveNameEndingWith("Handler")
            .Should().BeSealed()
            .GetResult();
        Assert.IsTrue(result.IsSuccessful);
    }
}
```

Generated rules are a **verification artifact** for `ARCH-LAYER-*`
findings: a finding's `verification` field should point to the specific
generated test method, not just "NetArchTest" generically.
