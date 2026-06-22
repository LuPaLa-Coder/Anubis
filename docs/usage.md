# Anubis .NET Agent — Usage Guide

## How to Invoke Anubis

### Via Claude Code

```bash
# Use the Anubis agent
claude -p "Use Anubis to review this C# code..."

# Or if you have the agent registered
claude --agent Anubis --prompt "Review this code..."
```

### Via OpenCode

```bash
# Direct invocation with agent
opencode --agent anubis

# Or reference the agent file
opencode --agent Anubis.agent.md --prompt "Review this code..."
```

### Via GitHub Copilot CLI

```bash
# Direct invocation
copilot task Anubis --prompt "Review this code..."

# With file input
copilot task Anubis < my-code.cs
```

### Via GitHub Copilot Chat (VS Code)

```
@Anubis review my service layer for security issues
```

## Typical Workflow

### Step 1: Prepare Input

Gather the code and context you want Anubis to review:

```bash
# Single file
cat src/Services/PaymentService.cs

# Multiple files with context
cat src/Models/Payment.cs src/Services/PaymentService.cs

# Entire project summary (if small)
find src -name "*.cs" -type f -exec wc -l {} \; | sort -rn | head -10
```

### Step 2: Invoke Anubis with Context

```bash
# Example with Claude Code
claude --agent Anubis --prompt "
Code Review Request:

Project: E-commerce Payment System
Objective: Security audit of payment processing layer
Files: PaymentService.cs, PaymentValidator.cs, PaymentRepository.cs

Key context:
- Uses Entity Framework Core 8.0
- Azure SQL Database backend
- PCI-DSS compliance required
- Currently processing $10M+ annually

Please review for:
1. SQL injection / parameterization
2. Secure credential handling
3. Transaction safety
4. Error logging (no sensitive data leakage)
5. Architectural fit with domain model

Include severity ranking and concrete refactoring proposals.
"
```

### Step 3: Review Findings

Anubis returns structured report:

```
📋 ANUBIS CODE REVIEW REPORT

Project: E-commerce Payment System
Files Analyzed: 3
Total Lines: 847

SEVERITY SUMMARY
├─ Critical: 1
├─ High: 2
├─ Medium: 4
└─ Low: 2

KEY FINDINGS

[Critical] SQL Injection Risk
File: PaymentRepository.cs:42
Issue: String concatenation in SQL query
Recommendation: Use parameterized EF Core queries

[High] Hardcoded Connection String
File: PaymentService.cs:15
Issue: ConnectionString in appsettings (no encryption)
Recommendation: Move to Key Vault, use managed identity

REFACTORING PROPOSALS

1. Parameterize all EF Core queries
   Impact: Eliminates SQL injection class
   Effort: Low
   
2. Extract secrets to Azure Key Vault
   Impact: PCI-DSS compliance
   Effort: Medium

ARCHITECTURAL INSIGHTS
✓ Repository pattern correctly isolated
✓ Service layer provides good abstraction
⚠ Payment validation missing input range checks

HANDOFF RECOMMENDATION
Consider Anubis-Runtime if performance profiling needed for high-volume transactions.
```

### Step 4: Optional Handoff

If Anubis identifies issues that need specialized analysis:

```bash
# Handoff to Anubis-devops for pipeline security
claude --agent Anubis-devops --prompt "
Based on code review findings from Anubis, 
audit our Azure DevOps pipeline for:
1. Secret exposure in logs
2. Artifact signing
3. Deployment approval gates
..."

# Handoff to Anubis-Runtime for performance
claude --agent Anubis-Runtime --prompt "
E-commerce payment service processes 10M transactions/year.
Profile for:
- N+1 query patterns in PaymentRepository
- Transaction deadlock risks
- Memory allocation in payment processing
..."
```

> **Note**: Anubis-devops, Anubis-Runtime, and Anubis-Arch are companion agents available in the same repository.

## Input Schema

### Minimal Input

```json
{
  "code": "C# source code or snippet",
  "objective": "What to focus on (security/architecture/performance/quality)"
}
```

### Full Input (Recommended)

```json
{
  "project_name": "E-commerce Payment System",
  "files": [
    {
      "path": "src/Services/PaymentService.cs",
      "language": "csharp",
      "content": "...",
      "is_critical": true
    },
    {
      "path": "src/Models/Payment.cs",
      "content": "..."
    }
  ],
  "context": {
    "architecture": "Clean Architecture with Repository pattern",
    "frameworks": ["Entity Framework Core 8", "ASP.NET Core 8"],
    "target_environment": "Azure SQL + Azure App Service",
    "compliance": ["PCI-DSS", "GDPR"],
    "known_issues": ["N+1 in payment queries", "connection pooling tuning needed"]
  },
  "review_focus": [
    "security",
    "architecture",
    "performance",
    "maintainability"
  ],
  "severity_threshold": "medium"
}
```

## Output Schema

```json
{
  "summary": {
    "project": "...",
    "files_analyzed": 3,
    "lines_of_code": 847,
    "duration_seconds": 45
  },
  "severity_distribution": {
    "critical": 1,
    "high": 2,
    "medium": 4,
    "low": 2
  },
  "findings": [
    {
      "severity": "critical",
      "file": "src/PaymentRepository.cs",
      "line": 42,
      "category": "security",
      "issue": "SQL injection vulnerability through string concatenation",
      "code_snippet": "var query = $\"SELECT * FROM Payments WHERE Id = {paymentId}\";",
      "recommendation": "Use parameterized EF Core queries: context.Payments.Where(p => p.Id == paymentId)",
      "cwe": "CWE-89",
      "owasp": "A03:2021 – Injection"
    }
  ],
  "refactoring_proposals": [
    {
      "title": "Parameterize EF Core Queries",
      "impact": "Eliminates SQL injection class",
      "effort": "Low",
      "priority": 1,
      "code_before": "var q = $\"SELECT * FROM Payments WHERE Id = {id}\";",
      "code_after": "var payments = context.Payments.Where(p => p.Id == id).ToList();"
    }
  ],
  "architectural_insights": {
    "strengths": [
      "Repository pattern correctly isolates data access",
      "Service layer provides clean abstraction"
    ],
    "weaknesses": [
      "Payment validation missing range checks",
      "No circuit breaker for external payment gateway"
    ],
    "recommendations": [
      "Add FluentValidation for input validation",
      "Implement Polly for resilience"
    ]
  },
  "handoff_recommendation": {
    "agent": "Anubis-Runtime",
    "reason": "High-volume transaction processing needs performance profiling",
    "scope": ["N+1 query patterns", "transaction deadlock risks", "memory allocation"]
  }
}
```

## Configuration Options

Anubis is configured via the agent file frontmatter. Edit the `Anubis.agent.md` file for your platform to customize behavior.

### Platform-specific configuration

- **Claude Code**: edit the agent file or configure via `.claude/settings.json`
- **OpenCode**: register in `opencode.json`
- **GitHub Copilot**: edit `~/.copilot/config.json` to set the model

```json
{
  "agents": {
    "Anubis": {
      "path": "~/.copilot/agents/Anubis.agent.md",
      "enabled": true
    }
  }
}
```

## Best Practices

### ✅ DO

- **Provide clear context** — project type, frameworks, compliance requirements
- **Specify review focus** — security, architecture, performance, or quality
- **Include known issues** — helps Anubis prioritize and correlate findings
- **Provide architecture blueprint** — helps validate layering and boundaries
- **Iterate** — review findings, refactor, request follow-up review

### ❌ DON'T

- **Review without context** — vague requests yield generic feedback
- **Mix multiple systems** — separate reviews for different codebases
- **Expect refactored code** — Anubis proposes, doesn't implement automatically
- **Ignore severity distribution** — prioritize critical and high findings first
- **Combine with pipeline review** — if pipeline is focus, use Anubis-devops first

## Example Prompts

### Security Audit
```
Security Review Request:

Project: Healthcare API
Files: AuthService.cs, PatientService.cs, EncryptionHelper.cs

Compliance: HIPAA
Requirements:
- No hardcoded secrets
- Input validation on all external endpoints
- Secure password handling (bcrypt/Argon2)
- Audit logging without PII

Focus: Security vulnerabilities, cryptographic best practices
```

### Architecture Validation
```
Architecture Review Request:

Project: Microservices Platform
Architecture: Domain-Driven Design with Repository pattern
Files: [list of critical service files]

Expected Layers:
- API Controllers
- Application Services
- Domain Models
- Infrastructure/Repository

Validate:
- Layer separation and dependencies
- Entity/ValueObject boundaries
- Bounded context integrity
```

### Quality & Maintainability
```
Code Quality Review:

Project: Legacy .NET Framework upgrade to .NET 8
Objective: Identify modernization opportunities
Files: [list]

Review for:
- Modern C# features (records, nullable, async/await)
- LINQ vs imperative patterns
- Test coverage and testability
- Performance hot spots
```

## Limitations & Known Issues

- **Large codebases** (>10k LOC per file): May timeout; split into multiple reviews
- **Binary analysis**: Provide source code for best results
- **Third-party integrations**: Requires code context or documentation
- **Async/await patterns**: Best results with realistic scenarios, not synthetic examples

## Support & More Information

- [Anubis GitHub Repository](https://github.com/LuPaLa-Coder/anubis)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [Microsoft .NET Security Best Practices](https://learn.microsoft.com/en-us/dotnet/standard/security/)
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
