# Example — Architecture governance review

Worked Full Review demonstrating the output shape:
Input · Evidence · Finding · Severity · Confidence · Remediation · Verification.

## Input

```text
# Solution structure (partial)
src/MyApp.Domain/MyApp.Domain.csproj
    <ProjectReference Include="..\MyApp.Infrastructure\MyApp.Infrastructure.csproj" />

src/MyApp.Infrastructure/MyApp.Infrastructure.csproj
    <ProjectReference Include="..\MyApp.Domain\MyApp.Domain.csproj" />

# Directory.Packages.props (partial)
<PackageVersion Include="Newtonsoft.Json" Version="12.0.3" />
# src/MyApp.Api/MyApp.Api.csproj also pins:
<PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
# src/MyApp.Legacy/MyApp.Legacy.csproj also pins:
<PackageReference Include="Newtonsoft.Json" Version="9.0.1" />
```

## Evidence

- `MyApp.Domain.csproj` references `MyApp.Infrastructure`, which in turn
  references `MyApp.Domain` back — a project reference cycle.
- `Newtonsoft.Json` resolves to three different versions
  (`9.0.1`, `12.0.3`, `13.0.3`) across the solution despite
  `Directory.Packages.props` declaring a central version.

## Findings

### ARCH-LAYER-002 — Assembly dependency cycle (Domain ↔ Infrastructure) — CRITICAL / HIGH

- **Evidence**: `MyApp.Domain.csproj:12` references `MyApp.Infrastructure`;
  `MyApp.Infrastructure.csproj:9` references `MyApp.Domain` back.
- **Impact**: the two assemblies cannot be built or tested independently;
  Domain can no longer stay framework-agnostic.
- **Recommendation**: extract the interface Domain needs from
  Infrastructure into a Domain-owned abstraction.
- **Fix**:
  ```text
  1. Move the interface Domain currently gets from Infrastructure into
     MyApp.Domain (e.g. IEventPublisher).
  2. Remove MyApp.Domain -> MyApp.Infrastructure reference entirely.
  3. Infrastructure implements the interface defined in Domain.
  ```
- **Migration**: none — this is a localised reference change plus one
  interface move.
- **Verification**: `Domain_Should_Not_Depend_On_Application`-style
  NetArchTest rule (`references/netarchtest-rules.md`) added and passing;
  build succeeds without the reverse reference.

### ARCH-DEP-001 — Version proliferation (`Newtonsoft.Json` at 3 versions) — HIGH / HIGH

- **Evidence**: `12.0.3` in `Directory.Packages.props`, `13.0.3` in
  `MyApp.Api.csproj`, `9.0.1` in `MyApp.Legacy.csproj` — CPM is declared
  but not enforced (per-project `Version` attributes override it).
- **Impact**: inconsistent JSON behaviour across projects; CVEs fixed in
  one version may still be present via the other two.
- **Recommendation**: remove per-project `Version` attributes so CPM's
  central version is the single source of truth.
- **Fix**:
  ```xml
  <!-- MyApp.Api.csproj / MyApp.Legacy.csproj -->
  <PackageReference Include="Newtonsoft.Json" />
  ```
- **Verification**: `dotnet list package` shows a single resolved version
  across all projects.

## Rejected candidate (false positive)

- Candidate: `ARCH-LIC-001` on `Newtonsoft.Json` (MIT license — not
  copyleft). The package license is confirmed MIT via the SBOM
  (`references/sbom.md`), which does not trigger `ARCH-LIC-001`. No
  finding emitted for this rule on this package.

## Severity summary

| Severity | Count |
| --- | --- |
| CRITICAL | 1 |
| HIGH | 1 |
| MEDIUM | 0 |
| LOW | 0 |

False positives rejected: 1.

## Handoff

```yaml
handoff:
  target: anubis
  reason: the interface extraction to break the cycle touches application-level wiring, not just the reference graph
  findings: [ARCH-LAYER-002]
  files: [src/MyApp.Domain, src/MyApp.Infrastructure]
  required_context: [current DI registration for the extracted interface]
  artifacts: [review report, generated NetArchTest rule]
```
