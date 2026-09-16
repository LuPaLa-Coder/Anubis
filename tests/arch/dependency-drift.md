# Test — Anubis-Arch / dependency drift

## Input

```text
Directory.Packages.props:   <PackageVersion Include="Newtonsoft.Json" Version="12.0.3" />
MyApp.Api.csproj:           <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
MyApp.Legacy.csproj:        <PackageReference Include="Newtonsoft.Json" Version="9.0.1" />
```

## Expected Findings

| ID | Title |
| --- | --- |
| `ARCH-DEP-001` | Version proliferation (`Newtonsoft.Json` at 3 versions) |

## Expected Severity

- `ARCH-DEP-001` — `HIGH`

## Expected Confidence

- `ARCH-DEP-001` — `HIGH` (all three versions are directly visible in
  project files).

## Expected Handoff

`none` — the fix is a self-contained CPM cleanup with no cross-agent
dependency.

## Expected Non-Findings

- Must **not** report `ARCH-DEP-002` (transitive chain / CVE exposure)
  unless a CVE is actually cited for one of the three versions — version
  proliferation alone, with no CVE evidence, is `ARCH-DEP-001` only.
