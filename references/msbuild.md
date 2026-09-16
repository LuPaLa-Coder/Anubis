# Reference — MSBuild / build & packaging

Pattern catalogue for `Anubis`. Family: `ANB-BUILD`. Evidence First applies.
Legacy IDs `AP-01`…`AP-09` are preserved as aliases of the new IDs.

| New ID | Legacy | Pattern | Severity | Fix |
| --- | --- | --- | --- | --- |
| `ANB-BUILD-001` | AP-01 | `<Exec>` used for mkdir/copy/del | MEDIUM | `<MakeDir>` / `<Copy>` / `<Delete>` |
| `ANB-BUILD-002` | AP-02 | Unquoted condition `Condition="$(Foo) == bar"` | MEDIUM | Quote always: `'$(Foo)' == 'bar'` |
| `ANB-BUILD-003` | AP-03 | Hardcoded absolute paths in `.csproj` | HIGH | `$(MSBuildThisFileDirectory)` or variables |
| `ANB-BUILD-004` | AP-04 | Re-defining an SDK default property | LOW | Remove — redundant, source of drift |
| `ANB-BUILD-005` | AP-05 | `<Compile Include="**\*.cs" />` in SDK-style | LOW | SDK already globs — remove |
| `ANB-BUILD-006` | AP-06 | `<Reference HintPath>` for NuGet | HIGH | Use `<PackageReference>` |
| `ANB-BUILD-007` | AP-07 | Analyzer NuGet without `PrivateAssets="all"` | MEDIUM | Add `<PrivateAssets>all</PrivateAssets>` |
| `ANB-BUILD-008` | AP-08 | Same `PropertyGroup` repeated in 3+ `.csproj` | MEDIUM | Centralise in `Directory.Build.props` |
| `ANB-BUILD-009` | AP-09 | Same package at different versions in a solution | HIGH | CPM: `Directory.Packages.props` + `ManagePackageVersionsCentrally` |

Detailed model (per pattern): Detection · Context · Evidence Required ·
Typical Impact · Possible Severity · False Positives · Remediation · Verification.

## ANB-BUILD-003 — Hardcoded absolute path

- Detection: absolute path literal in a project/build file.
- Evidence Required: the literal and its usage.
- Typical Impact: build breaks on other machines/agents.
- Possible Severity: HIGH.
- False Positives: none meaningful (documented generation output only).
- Remediation: derive from `$(MSBuildThisFileDirectory)` / well-known props.
- Verification: build on a clean agent.

## ANB-BUILD-006 — `HintPath` reference instead of `PackageReference`

- Detection: `<Reference ...><HintPath>...`.
- Evidence Required: the reference.
- Typical Impact: non-reproducible (vulnerable) builds; version drift.
- Possible Severity: HIGH.
- Remediation: `<PackageReference>`.
- Verification: restore/build; SCA scan.

## ANB-BUILD-009 — Mixed package versions

- Detection: the same package at different versions across projects.
- Evidence Required: the conflicting versions.
- Typical Impact: diamond conflicts, runtime `MissingMethodException`.
- Possible Severity: HIGH.
- Remediation: Central Package Management.
- Verification: restore; `dotnet list package --outdated` / SCA.
