---
name: anubis-sdd-workflow
description: Guida completa Specs Driven Development (SDD) in Claude Code. Usa questa skill quando l'utente vuole sviluppare una feature o un progetto seguendo un processo strutturato a 6 step basato su specifica, design, task e implementazione controllata. Trigger su "sdd", "specs driven", "sviluppo strutturato", "6 step", "workflow sviluppo", "implementa con metodo".
---

<!-- File generato da scripts/build-plugin.sh — non modificare a mano.
     Sorgente: Anubis.sdd.workflow.md (root). Rieseguire lo script dopo ogni modifica. -->

# Specs Driven Development (SDD) – Workflow a 6 Step

Guida l'utente attraverso un processo rigoroso di sviluppo basato su specifica. La specifica è la fonte di verità, il codice è solo un artefatto generato.

## Principi fondamentali

- Non scrivere mai codice prima che la specifica sia approvata.
- Ogni step produce un artefatto leggibile (markdown).
- L'utente deve approvare esplicitamente prima di passare allo step successivo.
- Preferisci sessioni fresche per l'implementazione (evita che Claude si attacchi al piano precedente).

## I 6 Step

### Step 1 – Clarify & Spec (Requirements)
Obiettivo: trasformare l'idea vaga in una specifica chiara.

Azioni:
1. Usa lo strumento AskUserQuestion per intervistare l'utente in modo approfondito.
2. Chiedi: obiettivi, utenti, edge case, vincoli tecnici, cosa è fuori scope, criteri di accettazione.
3. Scrivi un file `docs/specs/01-requirements.md` con:
   - User stories
   - Acceptance criteria (formato EARS o checklist)
   - Non-goals (cosa NON fare)
   - Success metrics

Fermati e chiedi approvazione esplicita prima di continuare.

### Step 2 – Explore & Research
Obiettivo: capire il contesto esistente.

Azioni:
1. Esplora il codebase (struttura, pattern, dipendenze, test esistenti).
2. Identifica file e moduli che saranno impattati.
3. Documenta in `docs/specs/02-research.md`:
   - Pattern esistenti da rispettare
   - Rischi tecnici
   - Alternative valutate

### Step 3 – Design
Obiettivo: decidere l'architettura della feature.

Azioni:
1. Proponi design (componenti, data model, API, flussi).
2. Usa diagrammi se utili (Mermaid o skill diagrammi se disponibile).
3. Scrivi `docs/specs/03-design.md` con:
   - Decisioni architetturali + motivazioni
   - File che saranno creati/modificati
   - Contratti (input/output)
   - Error handling e edge case

Chiedi approvazione.

### Step 4 – Task Breakdown
Obiettivo: spezzare il lavoro in unità piccole e verificabili.

Azioni:
1. Trasforma il design in una lista ordinata di task.
2. Ogni task deve essere:
   - Indipendente o con dipendenze esplicite
   - Completabile in 1-3 commit
   - Testabile isolatamente
3. Scrivi `docs/specs/04-tasks.md` con checklist numerata.

### Step 5 – Implement (TDD + Subagents)
Obiettivo: eseguire i task uno per uno.

Regole:
- Lavora su un branch dedicato.
- Per ogni task:
  1. Scrivi i test (o verifica esistenza)
  2. Implementa il minimo necessario
  3. Fai passare i test
  4. Commit atomico
- Preferisci sub-agent o sessioni fresche per task complessi.
- Non modificare file fuori dal perimetro del task.

### Step 6 – Review, Verify & Merge
Obiettivo: garantire qualità e chiudere il ciclo.

Azioni:
1. Confronta il codice prodotto con la specifica originale (requirements + design).
2. Esegui test completi + eventuale review adversariale (se hai skill/verify).
3. Aggiorna documentazione se necessario.
4. Se il codice è C#/.NET, passa da `Anubis` prima di PR o merge (obbligatorio); per pipeline YAML usa `Anubis-devops`.
5. Crea PR o fai merge sul branch principale.
6. Aggiorna lo stato in `docs/specs/05-status.md` (Done / Follow-ups).

## Come attivare il workflow

Quando l'utente dice cose come:
- "Voglio sviluppare questa feature con il metodo SDD"
- "Usa i 6 step"
- "Partiamo da una specifica"
- "Implementa in modo strutturato"

Inizia sempre dallo **Step 1** e procedi solo dopo approvazione esplicita dell'utente.

Mantieni un tono da senior engineer: chiaro, pragmatico, orientato al risultato.
