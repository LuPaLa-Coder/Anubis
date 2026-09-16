# Test — Anubis-Runtime / memory & GC

## Input

```csharp
public class NotificationHub
{
    public NotificationHub(IEventBus bus)
    {
        bus.MessageReceived += OnMessage;   // never unsubscribed
    }
    private void OnMessage(object sender, MessageEventArgs e) { /* ... */ }
}
```

```text
Heap snapshot diff over 7-day production window:
  Day 1: gen2 heap 120MB, 4,000 NotificationHub instances alive
  Day 7: gen2 heap 980MB, 31,000 NotificationHub instances alive
  (instances should be scoped per-connection and collected on disconnect)
```

## Expected Findings

| ID | Title |
| --- | --- |
| `RT-MEM-001` | Memory leak: event handler never unsubscribed |

## Expected Severity

- `RT-MEM-001` — `CRITICAL` (monotonic gen2 growth confirmed over 7 days).

## Expected Confidence

- `RT-MEM-001` — `HIGH` (heap snapshot diff directly attributes growth to
  `NotificationHub` instance count).

## Expected Handoff

`none` — subscribe/unsubscribe pairing or a weak-event pattern is a
self-contained fix.

## Expected Non-Findings

- Must **not** report `RT-MEM-002` (unbounded static cache): there is no
  cache here, the leak is a missing unsubscribe, a distinct root cause.
