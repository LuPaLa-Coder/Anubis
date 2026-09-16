# Reference — SBOM generation

Checklist and worked example for `Anubis-Arch` when producing a Software
Bill of Materials as an artifact of the review (`ARCH-DEP-*`,
`ARCH-LIC-*` findings reference the SBOM as evidence).

## Checklist

- [ ] Format: CycloneDX JSON 1.4+ or SPDX JSON 2.3+
- [ ] Direct dependencies + versions
- [ ] Complete transitive dependencies
- [ ] License metadata per package
- [ ] CVE mappings (when available)
- [ ] Manifest (`serialNumber`, `specVersion`, `timestamp`)
- [ ] Component list with BOM-Ref
- [ ] Services section (optional, microservice architectures)

## Recommended tools

- `dotnet CycloneDX` (`dotnet tool install --global CycloneDX`)
- `Microsoft.Sbom.Tool` (Microsoft SBOM Tool, SPDX 2.2 output)
- `Syft` (`anchore/syft`) for multi-format output

## Worked example — CycloneDX JSON 1.4 (minimal)

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "serialNumber": "urn:uuid:3e671687-395b-41f5-a30f-a58921a69b79",
  "version": 1,
  "metadata": {
    "timestamp": "2026-04-30T10:00:00Z",
    "component": {
      "bom-ref": "myapp",
      "type": "application",
      "name": "MyApp",
      "version": "1.0.0"
    }
  },
  "components": [
    {
      "bom-ref": "pkg:nuget/Serilog@3.0.0",
      "type": "library",
      "name": "Serilog",
      "version": "3.0.0",
      "purl": "pkg:nuget/Serilog@3.0.0",
      "licenses": [
        { "license": { "id": "Apache-2.0" } }
      ]
    }
  ]
}
```

The SBOM is a produced artifact (`Artefatti prodotti` in the Common
Output Contract, `references/review-protocol.md` §12), not itself a
finding. License and CVE data extracted from it feed `ARCH-LIC-*` and
`ARCH-DEP-002` findings.
