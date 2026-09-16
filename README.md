# Anubis Agent Suite

**Suite di code reviewer specializzati per .NET e Azure** — review tecnica
strutturata con severity condivisa, finding evidence-based, refactoring
concreti e handoff tra specialisti (codice, pipeline, architettura,
runtime, sostenibilità).

## Cosa Fa

Anubis è una suite di agent esperti che:

- **Analizza codice C# e .NET 8+** per identificare vulnerabilità, code smell e anti-pattern
- **Valuta architettura cloud** (AWS, Azure, GCP) e layering architetturale
- **Governa dipendenze, licenze e SBOM** per l'intera solution
- **Analizza performance runtime** da tracce OpenTelemetry (N+1, lock contention, memory/GC)
- **Stima carbon footprint e cost waste** su infrastruttura Azure (IaC)
- **Correla rischi di codice con delivery** (CI/CD, pipeline YAML)
- **Crea report tecnici completi** con severity condivisa e priorità chiare

La suite include cinque skill:

| Skill | Focus |
| --- | --- |
| `Anubis` | codice .NET applicativo, architettura, security, performance, testing, build |
| `Anubis-devops` | security di pipeline YAML Azure DevOps |
| `Anubis-Arch` | governance architetturale, dependency graph, license compliance, SBOM |
| `Anubis-Runtime` | performance runtime da tracce OpenTelemetry, N+1, lock contention, memory/GC |
| `Anubis-GreenOps` | carbon footprint, cost waste, over-provisioning, green pattern su IaC Azure |

## Target Users

- Sviluppatori .NET che cercano feedback tecnico approfondito
- Architetti che vogliono validare decisioni di design
- Team DevSecOps che integrano review di codice nel workflow
- Organizzazioni che richiedono standard di qualità rigorosi

## Architettura

Le skill sono **operating contract** compatti; la conoscenza tecnica vive in
`references/`, i contratti machine-readable in `schemas/`.

```text
Anubis.agent.md · Anubis.devops.md              # comportamento + workflow
Anubis.Arch.md · Anubis.Runtime.md · Anubis.GreenOps.md
        │
        ├── references/                 # knowledge base + regole
        │     ├── review-protocol.md    # contratto condiviso (normativo, §13 = interop matrix)
        │     ├── dotnet.md · security.md · architecture.md
        │     ├── performance.md · efcore.md · testing.md · msbuild.md
        │     ├── azure-devops-rules.md # 41 regole AZDO-SEC
        │     ├── architecture-governance.md · netarchtest-rules.md · sbom.md
        │     ├── runtime-performance.md
        │     └── sustainability.md
        │
        ├── schemas/                    # finding / review / handoff
        ├── examples/                   # review svolte (incl. false positive)
        └── tests/                      # test comportamentali + regressione
```

## Skills

### Anubis (.NET)

- Due modalità: **Quick Pass** (lightweight) e **Full Review** (default).
- Severity `CRITICAL | HIGH | MEDIUM | LOW`; `BLOCKED` è uno **stato di review**,
  non una severity.
- Ogni finding porta `confidence` (`HIGH | MEDIUM | LOW`), `evidence`,
  `remediation` e `verification`.
- Handoff verso `Anubis-devops`, `human` o `nessuno`.

### Anubis-devops (Azure DevOps)

- Analisi security di `azure-pipelines.yml`: secrets, identity, supply chain,
  pipeline governance.
- **Structural YAML parsing first, regex fallback**.
- 41 regole con ID preservati `AZDO-SEC001`…`AZDO-SEC042`, mapping CWE,
  false positives documentati.
- Security Score come **metrica secondaria** (formula deterministica).

### Anubis-Arch (governance architetturale)

- Pattern detection (Clean/DDD/Onion/CQRS/Layered), layer isolation,
  dependency graph, version drift, license compliance (SPDX), SBOM
  (CycloneDX/SPDX).
- Genera regole NetArchTest pronte da committare.
- Regole `ARCH-LAYER` / `ARCH-DEP` / `ARCH-LIC` / `ARCH-DEBT`.

### Anubis-Runtime (performance runtime)

- Analisi tracce OpenTelemetry: N+1 confermato da query count, thread
  pool/async, lock contention, memory/GC, correlazione CRAP-latenza.
- **Evidence First rinforzato**: un pattern statico senza traccia runtime
  non diventa un finding `RT-*` — resta di competenza di `Anubis`.
- Regole `RT-N1` / `RT-ASYNC` / `RT-LOCK` / `RT-MEM` / `RT-CRAP`.

### Anubis-GreenOps (sostenibilità cloud)

- Carbon footprint (GHG Protocol Scope 2/3), cost waste, over-provisioning,
  green pattern (auto-shutdown, auto-scaling, RI/Spot, tiering), regional
  energy mix.
- Regole `GRN-CARBON` / `GRN-COST` / `GRN-PROV` / `GRN-REGION` / `GRN-PATTERN`.

## References

| File | Contenuto |
| --- | --- |
| `references/review-protocol.md` | Lifecycle, Finding/Review/Handoff Contract, severity vs status, confidence, Evidence First |
| `references/dotnet.md` | Async, eccezioni, nullability, LINQ, stringhe (`ANB-DOTNET`) |
| `references/security.md` | Injection, secrets, crypto, validation (`ANB-SEC`) |
| `references/architecture.md` | Layering, coupling, DI, domain model (`ANB-ARCH`) |
| `references/performance.md` | Allocazioni, regex, collezioni, concurrency (`ANB-PERF`) |
| `references/efcore.md` | N+1, tracking, lifetime (`ANB-EFCORE`) |
| `references/testing.md` | MSTest 3.x/4.x, CRAP score (`ANB-TEST`) |
| `references/msbuild.md` | MSBuild / csproj anti-pattern `AP-01`…`AP-09` (`ANB-BUILD`) |
| `references/azure-devops-rules.md` | 41 regole Azure DevOps (`AZDO-SEC0NN`) |
| `references/architecture-governance.md` | Layer isolation, dependency drift, license compliance, complexity (`ARCH-LAYER`/`ARCH-DEP`/`ARCH-LIC`/`ARCH-DEBT`) |
| `references/netarchtest-rules.md` | Checklist e worked example per la generazione di regole NetArchTest |
| `references/sbom.md` | Checklist e worked example SBOM (CycloneDX) |
| `references/runtime-performance.md` | N+1, async, lock, memory/GC confermati da trace (`RT-N1`/`RT-ASYNC`/`RT-LOCK`/`RT-MEM`/`RT-CRAP`) |
| `references/sustainability.md` | Formula GHG Protocol, emission factor, green pattern (`GRN-CARBON`/`GRN-COST`/`GRN-PROV`/`GRN-REGION`/`GRN-PATTERN`) |

## Schemas

`schemas/finding.schema.json`, `schemas/review.schema.json`,
`schemas/handoff.schema.json` — JSON Schema (draft 2020-12). Severity, confidence
e review status sono enum vincolati; `BLOCKED` è separato dalla severity.

## Tests

`tests/anubis/`, `tests/devops/`, `tests/arch/`, `tests/runtime/` e
`tests/greenops/` — test comportamentali (input atteso, finding attesi,
severity, confidence, handoff, non-finding). `tests/regression.sh`
verifica che il refactoring non abbia perso regole, severity, modalità,
handoff, struttura di output, schema o riferimenti interni, per tutte e
cinque le skill:

```bash
bash tests/regression.sh
```

## Handoff

Ogni coppia di skill scambia handoff **solo quando serve un altro
specialista**: `Anubis` ⇄ `Anubis-devops` ⇄ `Anubis-Arch` ⇄
`Anubis-Runtime` ⇄ `Anubis-GreenOps`. Handoff verso `human` per
permessi/approvazioni/contesto mancante. Il contratto e la matrice di
interoperabilità completa sono in `references/review-protocol.md`
(§10, §13) e `schemas/handoff.schema.json`.

## Output Format

Report strutturato con severity `CRITICAL | HIGH | MEDIUM | LOW`, confidence,
evidence, remediation (`recommendation` / `fix` / `migration`) e `verification`
per ogni finding. Chiusura con il Common Output Contract (`Decisioni chiave`,
`Assunzioni`, `Rischi`, `Blocchi`, `Artefatti prodotti`, `Handoff al prossimo
agente`).

## Quick Start

1. **Install** — vedi [`docs/installation.md`](docs/installation.md)
   (`--suite anubis|devops|arch|runtime|greenops` per una singola skill)
2. **Use** — vedi [`docs/usage.md`](docs/usage.md),
   [`docs/devops/usage.md`](docs/devops/usage.md),
   [`docs/arch/usage.md`](docs/arch/usage.md),
   [`docs/runtime/usage.md`](docs/runtime/usage.md),
   [`docs/greenops/usage.md`](docs/greenops/usage.md)
3. **Examples** — [`docs/examples.md`](docs/examples.md) e le rispettive
   `docs/<skill>/examples.md`, oppure direttamente `examples/`
4. **Reference and refactoring** — [`docs/refactoring-report.md`](docs/refactoring-report.md)

## Input Requirements

- **Code files**: C# sorgente (`.cs`), project files (`.csproj`), solutions (`.sln`)
- **Context**: obiettivo della review (bug, refactoring, security audit)
- **Architecture info**: blueprint, layer structure, componenti critici (opzionale)
- **Related artifacts**: pipeline YAML se il codice è legato a CI/CD

## Support & Contacts

- **Issues & Feedback**: [GitHub Issues](https://github.com/LuPaLa-Coder/anubis/issues)
- **Related Agents**: **Anubis-devops** (pipeline security), **Anubis-Arch**
  (governance architetturale), **Anubis-Runtime** (performance runtime) e
  **Anubis-GreenOps** (sostenibilità cloud) sono tutte parte di questo
  repository (vedi [Agent Suite](#agent-suite)). `Anubis-azure` (audit
  security su subscription Azure) non esiste in questo repository.

---

**Quando usare Anubis:**
- Focus principale è la qualità e sicurezza del **codice .NET**
- Analisi architetturale di componenti applicativi
- Security review di sorgente

**Quando usare un altro agent:**
- Focus su **pipeline Azure DevOps YAML** → usa **Anubis-devops**
- Focus su **governance architetturale, dipendenze, licenze, SBOM** → usa **Anubis-Arch**
- Focus su **performance runtime e OpenTelemetry** → usa **Anubis-Runtime**
- Focus su **carbon footprint e cost optimization** → usa **Anubis-GreenOps**

## Agent Suite

Tutti e cinque gli agenti sono **implementati e installabili** da questo
repository.

| Agent | Stato | Focus |
| --- | --- | --- |
| Anubis | ✅ implementato | codice .NET, architettura applicativa, security, performance, testing, build |
| Anubis-devops | ✅ implementato | security di pipeline YAML Azure DevOps |
| Anubis-Arch | ✅ implementato | governance architetturale, dependency graph, license compliance, SBOM |
| Anubis-Runtime | ✅ implementato | performance runtime da tracce OpenTelemetry, N+1, lock contention, memory/GC |
| Anubis-GreenOps | ✅ implementato | carbon footprint, cost waste, over-provisioning, green pattern |

`Anubis-azure` (audit security su Azure subscription) resta fuori dal
perimetro di questo repository: non esiste ancora come skill installabile.
