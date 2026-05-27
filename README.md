# Anubis .NET Agent

**Senior code reviewer specializzato in .NET architecture** — review tecnica strutturata per progetti .NET con severity condivisa, refactoring concreti e handoff opzionali verso agenti specializzati (DevOps, Performance, Architecture).

## Cosa Fa

Anubis è un agent esperto di revisione codice .NET che:

- **Analizza codice C# e .NET 8+** per identificare vulnerabilità, code smell, e anti-pattern
- **Valuta architettura cloud** (AWS, Azure, GCP) e layering architetturale
- **Fornisce refactoring concreti** con proposte di miglioramento implementabili
- **Correla rischi di codice con delivery** (CI/CD, pipeline YAML)
- **Crea report tecnici completi** con severity condivisa e priorità chiare

## Target Users

- Sviluppatori .NET che cercano feedback tecnico approfondito
- Architetti che vogliono validare decisioni di design
- Team DevSecOps che integrano review di codice nel workflow
- Organizzazioni che richiedono standard di qualità rigorosi

## Quick Features

✅ **Code Review Strutturata** — analisi file-by-file di codice C#, identificazione di duplicazioni e pattern ricorrenti  
✅ **Security & Vulnerability Scanning** — detection di vulnerabilità OWASP, input validation, secrets management  
✅ **Architecture Assessment** — valutazione di layering, SOLID principles, Clean Architecture compliance  
✅ **Performance Analysis** — identificazione di colli di bottiglia, inefficienze di query, problemi di concurrency  
✅ **Handoff Intelligence** — riconoscimento automatico di problemi che richiedono agent specializzati (pipeline, performance, architecture)

## Quick Start

1. **Install** — See [`docs/installation.md`](docs/installation.md) for detailed setup
2. **Use** — See [`docs/usage.md`](docs/usage.md) for workflow and examples
3. **Examples** — Check [`docs/examples.md`](docs/examples.md) for real scenarios

## Input Requirements

- **Code files**: C# sorgente (`.cs`), project files (`.csproj`), solutions (`.sln`)
- **Context**: Descrizione dell'obiettivo di review (bug, refactoring, security audit)
- **Architecture info**: Blueprint desiderato, layer structure, componenti critici (opzionale)
- **Related artifacts**: Pipeline YAML se il codice è strettamente legato a CI/CD

## Output Format

Report strutturato con:

```json
{
  "summary": "Overview della review",
  "severity_distribution": { "critical": 0, "high": 2, "medium": 5, "low": 1 },
  "findings": [
    {
      "file": "src/Services/UserService.cs",
      "severity": "high",
      "category": "security",
      "issue": "SQL injection vulnerability in query construction",
      "recommendation": "Use parameterized queries with Entity Framework"
    }
  ],
  "refactoring_proposals": [ ... ],
  "architectural_insights": { ... },
  "handoff_recommendation": "Consider Anubis-devops if pipeline review is needed"
}
```

## Support & Contacts

- **Documentation**: [GitHub Copilot CLI Docs](https://github.com/github/copilot-cli)
- **Issues & Feedback**: Copilot CLI community channels
- **Related Agents**: Anubis-devops (pipeline security), Anubis-Runtime (performance), Anubis-Arch (architecture governance)

---

**Quando usare Anubis:**
- Focus principale è la qualità e sicurezza del **codice .NET**
- Analisi architetturale di componenti applicativi
- Security review di sorgente

**Quando usare un altro agent:**
- Se il focus è una **pipeline Azure DevOps YAML** → usa **Anubis-devops**
- Se il focus è **performance runtime e optimization** → usa **Anubis-Runtime**
- Se il focus è **governance architetturale e compliance** → usa **Anubis-Arch**
- Se il focus è **cost/carbon footprint** → usa **Anubis-GreenOps**
