# Test — Regression

Executable: `bash tests/regression.sh` (JSON checks require `python3`; optional).

Verifies the refactoring did not lose rules, severities, modes, handoffs, output
structure, schemas or internal references.

## Checks

| Gate | Check |
| --- | --- |
| 1 | All expected files exist (skills, references, schemas, examples, tests, docs). |
| 2 | Both skills are operating contracts with Mission/Scope/Non-Scope/Workflow; Quick Pass, Full Review and BLOCKED preserved; DevOps prefers structural parsing. |
| 3 | Common Output Contract (`Decisioni chiave`, `Assunzioni`, `Rischi`, `Blocchi`, `Artefatti prodotti`, `Handoff al prossimo agente`) present in both skills. |
| 4 | Handoff targets preserved (`anubis-devops`, `anubis`, `human`, `none`). |
| 5 | All 41 Azure DevOps rule IDs preserved, exactly 41 unique. |
| 6 | MSBuild `AP-01`…`AP-09` and key .NET/EF Core/MSTest/CRAP patterns preserved. |
| 7 | Security Score formula preserved and explicitly secondary. |
| 8 | `BLOCKER` is not a severity in either skill. |
| 9 | JSON schemas parse and constrain severity/confidence/review-status enums. |
| 10 | No broken internal references. |

## Expected

```text
REG... OK
  passed: N   failed: 0
```

## Rule

If an existing test fails after a change: STOP, identify the regression, fix it,
re-run, then continue. Never accumulate failing tests.

## Manual gate

"All existing tests pass" reduces to "no existing tests existed at baseline"
(see `docs/refactoring-baseline.md`). This regression suite is the first
executable verification layer for the suite.
