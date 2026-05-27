# Anubis .NET Agent — Usage Examples

## Example 1: Security Review of Payment Service (Happy Path)

### Input

```bash
copilot task Anubis --prompt "
Code Security Review:

Project: E-commerce Payment System
Files:
  - src/Services/PaymentService.cs (120 lines)
  - src/Data/PaymentRepository.cs (85 lines)  
  - src/Models/Payment.cs (45 lines)

Code:
---
// PaymentRepository.cs
public class PaymentRepository
{
    private readonly DbContext _context;
    
    public async Task<Payment> GetByIdAsync(int paymentId)
    {
        // ❌ BUG: String interpolation in SQL
        var payment = _context.Payments
            .FromSqlInterpolated(\$\"SELECT * FROM Payments WHERE Id = {paymentId}\")
            .FirstOrDefault();
        return payment;
    }
    
    public async Task SaveAsync(Payment payment)
    {
        _context.Payments.Add(payment);
        await _context.SaveChangesAsync();
    }
}

// PaymentService.cs
public class PaymentService
{
    private readonly PaymentRepository _repo;
    private readonly ILogger<PaymentService> _logger;
    
    public async Task<PaymentResult> ProcessPaymentAsync(
        int userId, 
        decimal amount, 
        string cardToken)
    {
        // ❌ BUG: Card token logged
        _logger.LogInformation(\$\"Processing payment: {cardToken}, Amount: {amount}\");
        
        // ❌ BUG: No input validation
        var payment = new Payment 
        { 
            UserId = userId, 
            Amount = amount, 
            Token = cardToken 
        };
        
        await _repo.SaveAsync(payment);
        return new PaymentResult { Success = true };
    }
}
---

Compliance: PCI-DSS Level 1
Target: Azure SQL Database + ASP.NET Core 8
Objective: Security audit before production deployment

Focus:
  1. SQL injection risks
  2. Credential/sensitive data handling
  3. Input validation
  4. Logging security
  5. PCI-DSS compliance
"
```

### Output

```
╔════════════════════════════════════════════════════════════════╗
║          ANUBIS CODE REVIEW — SECURITY AUDIT REPORT            ║
╚════════════════════════════════════════════════════════════════╝

📊 SUMMARY
├─ Project: E-commerce Payment System
├─ Files: 3 (PaymentService.cs, PaymentRepository.cs, Payment.cs)
├─ Lines: 250
├─ Review: Security Focus
└─ Status: ⚠️ CRITICAL ISSUES FOUND

🔴 CRITICAL FINDINGS

[1/4] SQL Injection Vulnerability
├─ Severity: CRITICAL
├─ File: src/Data/PaymentRepository.cs:8
├─ Category: Security (CWE-89, OWASP A03:2021)
├─ Issue: 
│  FromSqlInterpolated() with string interpolation is vulnerable
│  to SQL injection when paymentId comes from untrusted source
│
├─ Current Code:
│  var payment = _context.Payments
│      .FromSqlInterpolated($"SELECT * FROM Payments WHERE Id = {paymentId}")
│
├─ Remediation:
│  Use parameterized EF Core LINQ instead:
│  var payment = await _context.Payments
│      .Where(p => p.Id == paymentId)
│      .FirstOrDefaultAsync();
│
└─ Impact: Complete database compromise possible

[2/4] Sensitive Data Logging (PCI-DSS Violation)
├─ Severity: CRITICAL
├─ File: src/Services/PaymentService.cs:24
├─ Category: Security (PCI-DSS 3.4, OWASP A09:2021)
├─ Issue:
│  Card token logged in plain text, violates PCI-DSS
│  Auditors can see sensitive data in logs
│
├─ Current Code:
│  _logger.LogInformation($"Processing payment: {cardToken}, Amount: {amount}");
│
├─ Remediation:
│  Log payment ID, not token; use structured logging:
│  _logger.LogInformation(
│      "Processing payment {PaymentId} for amount {Amount}",
│      payment.Id, amount);
│
└─ Impact: PCI-DSS audit failure, potential compliance violation

🟠 HIGH PRIORITY FINDINGS

[3/4] Missing Input Validation
├─ Severity: HIGH
├─ File: src/Services/PaymentService.cs:26
├─ Category: Security (OWASP A04:2021)
├─ Issue:
│  No validation on amount, userId, or cardToken
│  Negative amounts, missing user checks, invalid tokens accepted
│
├─ Recommendation:
│  Implement FluentValidation:
│  
│  public class ProcessPaymentValidator : AbstractValidator<ProcessPaymentRequest>
│  {
│      public ProcessPaymentValidator()
│      {
│          RuleFor(x => x.Amount)
│              .GreaterThan(0).WithMessage("Amount must be positive")
│              .LessThanOrEqualTo(999999)
│              .WithMessage("Amount exceeds limit");
│              
│          RuleFor(x => x.CardToken)
│              .NotEmpty()
│              .Matches(@"^[a-zA-Z0-9]{20,}$")
│              .WithMessage("Invalid token format");
│      }
│  }
│
└─ Effort: Medium | Impact: Prevents invalid states

[4/4] No Transaction Handling
├─ Severity: HIGH
├─ File: src/Services/PaymentService.cs:32
├─ Category: Data Integrity
├─ Issue:
│  Payment processing not wrapped in transaction
│  If logging fails, payment state inconsistent
│
├─ Recommendation:
│  using (var transaction = await _context.Database.BeginTransactionAsync())
│  {
│      try
│      {
│          await _repo.SaveAsync(payment);
│          await transaction.CommitAsync();
│      }
│      catch
│      {
│          await transaction.RollbackAsync();
│          throw;
│      }
│  }
│
└─ Effort: Low | Impact: Prevents data corruption

📋 SEVERITY DISTRIBUTION
├─ 🔴 Critical: 2
├─ 🟠 High: 2
├─ 🟡 Medium: 0
└─ 🔵 Low: 0

✅ REFACTORING ROADMAP

Priority 1 (Do First):
✓ Remove sensitive data from logs
✓ Replace FromSqlInterpolated with parameterized LINQ
✓ Add transaction wrapping

Priority 2 (Before Production):
✓ Implement input validation with FluentValidation
✓ Add try/catch with specific exception types
✓ Document payment processing flow

Priority 3 (Future Enhancement):
✓ Add Circuit Breaker for payment gateway
✓ Implement idempotency key for retry safety
✓ Add audit logging (separate from application logs)

💡 ARCHITECTURAL OBSERVATIONS

Strengths:
✓ Repository pattern isolates data access (good separation)
✓ Service layer abstracts payment logic correctly
✓ Async/await pattern in place

Concerns:
⚠️  No validation layer between API and Service
⚠️  No error handling for external payment gateway calls
⚠️  Connection string management not visible (should use Key Vault)

🔄 HANDOFF RECOMMENDATIONS

1. **Anubis-devops** (Optional)
   - Review CI/CD pipeline for secret exposure in logs
   - Validate deployment approval gates
   - Check artifact signing
   - **When**: After code fixes, before production deployment

2. **Anubis-Runtime** (Optional)
   - Profile payment processing for high-volume scenarios
   - Check for N+1 queries in payment history retrieval
   - Analyze transaction deadlock risks
   - **When**: After code is stable, if processing >1M payments/month

⏱️  ESTIMATED REMEDIATION TIME
├─ Code fixes: 2-3 hours
├─ Testing: 4-6 hours
└─ Total: 1-2 days for experienced developer

📝 FINAL RECOMMENDATION
BLOCK PRODUCTION DEPLOYMENT until Critical findings are resolved.
Expected completion: 1-2 days.

---
Generated by Anubis .NET Agent | Report Time: 2024-01-15T10:30:00Z
```

---

## Example 2: Architecture Review of Microservices Layer

### Input

```bash
copilot task Anubis --prompt "
Architecture Review:

Project: E-commerce Microservices Platform
Target: Validation of Clean Architecture + DDD implementation

Files:
  - src/Domain/Entities/Order.cs (120 lines)
  - src/Application/Commands/CreateOrderCommand.cs (85 lines)
  - src/Application/Services/OrderService.cs (200 lines)
  - src/Infrastructure/Persistence/OrderRepository.cs (95 lines)
  - src/API/Controllers/OrdersController.cs (60 lines)

Architecture Blueprint:
├─ API Layer: Controllers only
├─ Application Layer: Commands, Queries, Services
├─ Domain Layer: Entities, ValueObjects, Specifications
└─ Infrastructure: Repository, DbContext, Migrations

Review Focus:
1. Layer separation and dependency direction
2. Entity/ValueObject correct modeling
3. Command/Query pattern implementation
4. Repository abstraction validity
5. Cyclic dependency detection

Code Snippet (Architecture concern):

// ❌ Potential Issue: OrderService accessing Infrastructure directly?
namespace Eshop.Application.Services;

public class OrderService
{
    private readonly IOrderRepository _repo;  // Good: interface-based
    private readonly DbContext _dbContext;     // ❌ Bad: infrastructure leak
    
    public async Task CreateAsync(Order order)
    {
        // Mixing repository + direct DbContext
        _dbContext.Orders.Add(order);
        await _dbContext.SaveChangesAsync();
    }
}

Expected Pattern:
- Commands should route through CommandHandler
- Domain logic in Entity/AggregateRoot
- Repository should be only data access abstraction
"
```

### Output (Abbreviated)

```
╔════════════════════════════════════════════════════════════════╗
║        ANUBIS ARCHITECTURE REVIEW — MICROSERVICES LAYER        ║
╚════════════════════════════════════════════════════════════════╝

📊 SUMMARY
├─ Project: E-commerce Microservices
├─ Files: 5 (Domain, Application, Infrastructure, API)
├─ Lines: 560
├─ Pattern: Clean Architecture + DDD
└─ Status: ✅ GOOD with minor layering issues

🟠 ARCHITECTURE FINDINGS

[1] DbContext Leaking into Application Layer
├─ Severity: HIGH
├─ File: src/Application/Services/OrderService.cs:18
├─ Issue: Direct DbContext reference violates Application layer isolation
├─ Impact: Application layer becomes tightly coupled to EF Core
├─ Fix: Remove DbContext, use only IOrderRepository interface
│
│  BEFORE:
│  public class OrderService {
│      private readonly DbContext _dbContext;
│      _dbContext.Orders.Add(order);
│  }
│
│  AFTER:
│  public class OrderService {
│      private readonly IOrderRepository _repo;
│      await _repo.AddAsync(order);
│  }

✅ STRENGTHS

[1] Repository Pattern Correctly Implemented
├─ File: src/Infrastructure/Persistence/OrderRepository.cs
├─ ✓ Implements IOrderRepository interface
├─ ✓ Encapsulates DbContext properly
├─ ✓ Supports testability through mocking

[2] Domain Entity Design
├─ File: src/Domain/Entities/Order.cs
├─ ✓ Contains business logic (CalculateTotal, ValidateItems)
├─ ✓ ValueObject pattern for OrderItem
├─ ✓ Aggregate boundary clear (Order is root)

[3] Command Handler Pattern
├─ File: src/Application/Commands/CreateOrderCommand.cs
├─ ✓ Command object separate from handler
├─ ✓ Single Responsibility
├─ ✓ Testable in isolation

⚠️ RECOMMENDATIONS

Priority 1: Fix Application/Infrastructure Leakage
└─ Extract DbContext from OrderService

Priority 2: Add Specification Pattern
└─ Move complex queries to Domain.Specifications

Priority 3: Consider CQRS for Scale
└─ Separate read models from write aggregate

📈 METRICS
├─ Cyclic Dependencies: 0 ✓
├─ Layer Violations: 1
├─ Testability Score: 8/10
└─ DDD Compliance: 9/10

---
Next: Run Anubis-Arch for full governance validation and SBOM generation.
```

---

## Example 3: Handoff to Anubis-Runtime

### Scenario

After Anubis identifies potential performance issues, delegate to Anubis-Runtime:

```bash
# Initial review found N+1 query concerns
copilot task Anubis --prompt "Review OrderRepository for query patterns"

# Output identifies N+1 potential:
# [Medium] Possible N+1 in GetOrdersWithItemsAsync()
# Recommendation: See Anubis-Runtime for profiling

# Handoff to specialized agent:
copilot task Anubis-Runtime --prompt "
Performance Profiling Request:

Based on Anubis code review, we suspect N+1 queries in order processing.

Project: E-commerce Orders Microservice
Current Metrics:
  - Average order retrieval: 450ms (should be <100ms)
  - Peak: 2s+ during promotions
  - Traffic: 500 orders/minute avg, 5000/minute peak
  - Database: Azure SQL, Standard pricing tier

Trace files: attached (OpenTelemetry JSON format)

Areas to Profile:
1. GetOrdersWithItemsAsync() - suspected N+1
2. Order.CalculateTotal() - called in loop?
3. Transaction deadlock risks during concurrent updates

Expected outcome:
- Identify exact query count for sample order
- Quantify latency reduction if fixed
- Recommend indexing strategy
"
```

### Handoff Result

Anubis-Runtime responds with specific metrics:

```
Performance Analysis Complete:

🔴 CONFIRMED: N+1 Query Pattern

Baseline: 500 orders/minute
└─ Per order: 1 parent query + 5 item queries = 6 total
   └─ Latency: 450ms (60ms per query)

After Fix (EF Core SelectMany):
└─ Per order: 1 combined query
   └─ Latency: 75ms (87.5% reduction!)

Expected Impact:
├─ Throughput: 500 → 3,500 orders/minute (7x improvement)
├─ Cost: 30% reduction in database CPU
└─ User Experience: Checkout loading 3.75s → 0.5s

Recommended Query Fix:
var orders = await _context.Orders
    .Include(o => o.Items)
    .Where(o => o.UserId == userId)
    .ToListAsync();
```

---

## Example 4: Combining Multiple Concerns

### Input

```bash
copilot task Anubis --prompt "
Comprehensive Code Audit:

Project: Payment Processing Service
Scope: Security + Architecture + Performance Concerns
Compliance: PCI-DSS, SOC 2

Files:
  - src/Services/PaymentProcessor.cs (300 lines)
  - src/Data/PaymentRepository.cs (200 lines)
  - src/Models/Payment.cs (80 lines)
  - appsettings.json (connection string visible)
  - src/API/PaymentController.cs (120 lines)

Known Issues:
  - Occasional timeout (>5s) on 100+ concurrent requests
  - Recent security audit flagged potential SQL patterns
  - Team switching from .NET Framework to .NET 8

Required Output:
  - Security findings with remediation
  - Architecture assessment vs. Clean Architecture
  - Performance hotspots identified
  - .NET 8 modernization opportunities
"
```

This triggers Anubis to produce a comprehensive report addressing all areas, with recommendations for optional handoffs to Anubis-Runtime (performance) or Anubis-devops (deployment security).

---

## Summary

Each example shows how Anubis:
1. **Analyzes code deeply** with concrete findings
2. **Provides actionable recommendations** with code snippets
3. **Recognizes specialization boundaries** and suggests handoffs
4. **Reports with clear severity** to prioritize work
5. **Estimates effort** for remediation planning
