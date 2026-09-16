# Anubis .NET Agent

**Senior code reviewer specializzato in .NET architecture** — review tecnica
strutturata per progetti .NET con severity condivisa, finding evidence-based,
refactoring concreti e handoff opzionali verso agenti specializzati
(Azure DevOps, delivery).

## Cosa Fa

Anubis è un agent esperto di revisione codice .NET che:

- **Analizza codice C# e .NET 8+** per identificare vulnerabilità, code smell e anti-pattern
- **Valuta architettura cloud** (AWS, Azure, GCP) e layering architetturale
- **Fornisce refactoring concreti** con proposte di miglioramento implementabili
- **Correla rischi di codice con delivery** (CI/CD, pipeline YAML)
- **Crea report tecnici completi** con severity condivisa e priorità chiare

La suite include due skill:

| Skill | Focus |
| --- | --- |
| `Anubis` | codice .NET applicativo, architettura, security, performance, testing, build |
| `Anubis-devops` | security di pipeline YAML Azure DevOps |

## Target Users

- Sviluppatori .NET che cercano feedback tecnico approfondito
- Architetti che vogliono validare decisioni di design
- Team DevSecOps che integrano review di codice nel workflow
- Organizzazioni che richiedono standard di qualità rigorosi

## Architettura

Le skill sono **operating contract** compatti; la conoscenza tecnica vive in
`references/`, i contratti machine-readable in `schemas/`.

```text
Anubis.agent.md / Anubis.devops.md      # comportamento + workflow
        │
        ├── references/                 # knowledge base + regole
        │     ├── review-protocol.md    # contratto condiviso (normativo)
        │     ├── dotnet.md · security.md · architecture.md
        │     ├── performance.md · efcore.md · testing.md · msbuild.md
        │     └── azure-devops-rules.md # 41 regole AZDO-SEC
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

## Schemas

`schemas/finding.schema.json`, `schemas/review.schema.json`,
`schemas/handoff.schema.json` — JSON Schema (draft 2020-12). Severity, confidence
e review status sono enum vincolati; `BLOCKED` è separato dalla severity.

## Tests

`tests/anubis/` e `tests/devops/` — test comportamentali (input atteso, finding
attesi, severity, confidence, handoff, non-finding). `tests/regression.sh` verifica
che il refactoring non abbia perso regole, severity, modalità, handoff, struttura
di output, schema o riferimenti interni:

```bash
bash tests/regression.sh
```

## Handoff

`Anubis` ⇄ `Anubis-devops` è bidirezionale e avviene **solo quando serve un
altro specialista**. Handoff verso `human` per permessi/approvazioni/contesto
mancante. Il contratto è in `references/review-protocol.md` e
`schemas/handoff.schema.json`.

## Output Format

Report strutturato con severity `CRITICAL | HIGH | MEDIUM | LOW`, confidence,
evidence, remediation (`recommendation` / `fix` / `migration`) e `verification`
per ogni finding. Chiusura con il Common Output Contract (`Decisioni chiave`,
`Assunzioni`, `Rischi`, `Blocchi`, `Artefatti prodotti`, `Handoff al prossimo
agente`).

## Quick Start

1. **Install** — vedi [`docs/installation.md`](docs/installation.md)
2. **Use** — vedi [`docs/usage.md`](docs/usage.md) e
   [`docs/devops/usage.md`](docs/devops/usage.md)
3. **Examples** — [`docs/examples.md`](docs/examples.md),
   [`docs/devops/examples.md`](docs/devops/examples.md) e `examples/`
4. **Reference and refactoring** — [`docs/refactoring-report.md`](docs/refactoring-report.md)

## Input Requirements

- **Code files**: C# sorgente (`.cs`), project files (`.csproj`), solutions (`.sln`)
- **Context**: obiettivo della review (bug, refactoring, security audit)
- **Architecture info**: blueprint, layer structure, componenti critici (opzionale)
- **Related artifacts**: pipeline YAML se il codice è legato a CI/CD

## Support & Contacts

- **Issues & Feedback**: [GitHub Issues](https://github.com/LuPaLa-Coder/anubis/issues)
- **Related Agents**: Anubis-devops (pipeline security), Anubis-Runtime (performance),
  Anubis-Arch (architecture governance)

---

**Quando usare Anubis:**
- Focus principale è la qualità e sicurezza del **codice .NET**
- Analisi architetturale di componenti applicativi
- Security review di sorgente

**Quando usare un altro agent:**
- Focus su **pipeline Azure DevOps YAML** → usa **Anubis-devops**
- Focus su **performance runtime e optimization** → usa **Anubis-Runtime**
- Focus su **governance architetturale e compliance** → usa **Anubis-Arch**
- Focus su **cost/carbon footprint** → usa **Anubis-GreenOps**
