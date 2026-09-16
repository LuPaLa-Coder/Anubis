# Test — Anubis-Arch / false positive

Purpose: prove the review rejects candidates that match a pattern but
whose context neutralises the risk, and never emits them as findings.

## Input

```text
Directory.Packages.props:
  <PackageVersion Include="Roslyn.Analyzer.Sample" Version="1.2.0" />
  # PrivateAssets="all" build-time analyzer, GPL-3.0 licensed,
  # never shipped with the compiled product.

MyApp.Tools.csproj:
  <PackageReference Include="SomeUtilityLib" Version="4.0.0" />
  # Referenced but no type/namespace from it appears anywhere in source
  # (build-time source generator only, no runtime usage expected).

Namespace: MyApp.Web.Features -> MyApp.Web.Features.Orders
  # Vertical-slice module, documented exception to the Layered
  # Architecture blueprint approved for this repository.
```

## Expected Findings

None. Every candidate is a documented false positive.

## Expected Non-Findings (rejected candidates, with reason)

| Candidate | Reason for rejection |
| --- | --- |
| `ARCH-LIC-001` on `Roslyn.Analyzer.Sample` (GPL-3.0) | build-time-only analyzer, `PrivateAssets="all"`, never distributed with the product |
| `ARCH-DEP-003` (unused dependency) on `SomeUtilityLib` | build-time source generator, no runtime type usage expected by design |
| `ARCH-LAYER-001` on the `Features.Orders` vertical slice | documented, approved exception to the Layered blueprint |

## Expected Severity

N/A (no findings).

## Expected Confidence

N/A.

## Expected Handoff

`none`. `summary.false_positives_rejected` must equal the number of
rejected candidates (3).

## Rule

`NO EVIDENCE = NO FINDING`. A candidate whose context shows the risk is
absent must be recorded as rejected, never promoted to a finding and
never silently dropped.
