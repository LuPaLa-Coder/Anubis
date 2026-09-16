# Anubis-Runtime Agent — Usage Guide

## How to Invoke Anubis-Runtime

### Via Claude Code

```bash
claude -p "Use Anubis-Runtime to analyse this OpenTelemetry trace and the related source..."
```

### Via OpenCode

```bash
opencode --agent anubis-runtime --prompt "Find N+1 queries and lock contention from this trace..."
```

### Via GitHub Copilot Chat

```
@Anubis-Runtime analyse this endpoint's trace for N+1 and lock contention
```

## Typical Workflow

### Step 1: Gather runtime evidence

Anubis-Runtime requires trace/metric/profiler evidence to promote a
candidate to a finding (see `references/runtime-performance.md`). Bring:

- OpenTelemetry trace (file/OTLP export) or a span summary
- The source code for the request path under review
- A baseline (latency, throughput, error rate) if available

### Step 2: Invoke with the objective

```bash
claude -p "Use Anubis-Runtime to:
- identify the critical path and its latency breakdown
- confirm any N+1 pattern using the query count in the trace
- flag lock contention / deadlock risk with hold-time evidence
- correlate CRAP score with the top latency contributors
Trace: <attached> · Source: src/Services/CatalogService.cs
"
```

### Step 3: Review the output

Findings carry severity, confidence, the trace excerpt as evidence, and
a concrete fix with measured/expected impact. See
`examples/runtime-review.md` for a full worked example, including a
rejected false positive (a static-only candidate with no trace evidence).

## Choosing Quick Pass vs Full Review

- **Quick Pass**: a single trace/metric question, fast triage.
- **Full Review** (default): full trace analysis across N+1, async,
  lock contention, memory/GC, and CRAP-latency correlation.

## Reference

- Pattern catalogue: `references/runtime-performance.md`
- CRAP score formula: `references/testing.md` (`ANB-TEST-010`, reused)
- Shared protocol: `references/review-protocol.md`
