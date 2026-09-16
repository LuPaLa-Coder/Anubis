# Test — Anubis-Arch / layering

## Input

```text
src/MyApp.Domain/MyApp.Domain.csproj
    <ProjectReference Include="..\MyApp.Infrastructure\MyApp.Infrastructure.csproj" />
src/MyApp.Infrastructure/MyApp.Infrastructure.csproj
    <ProjectReference Include="..\MyApp.Domain\MyApp.Domain.csproj" />
```

## Expected Findings

| ID | Title |
| --- | --- |
| `ARCH-LAYER-002` | Assembly dependency cycle (Domain ↔ Infrastructure) |

## Expected Severity

- `ARCH-LAYER-002` — `CRITICAL`

## Expected Confidence

- `ARCH-LAYER-002` — `HIGH` (both `.csproj` references are directly
  inspectable).

## Expected Handoff

`anubis` if the fix requires extracting/moving an interface that touches
application-level DI wiring; otherwise `none` if the fix is a pure
reference change with no interface extraction needed.

## Expected Non-Findings

- Must **not** be reported as `ARCH-LAYER-001` (back-reference) in
  addition to `ARCH-LAYER-002`: a true bidirectional cycle is reported
  once, as a cycle, not twice under two different rules.
