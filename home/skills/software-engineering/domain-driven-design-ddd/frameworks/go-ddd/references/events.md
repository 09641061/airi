# Domain Events

Location: `internal/<context>/domain/model/events/`

Domain events represent important domain facts. They are facts, not commands — name them in past tense.

- **Structs, immutable after construction.**
- **Past tense names** — `OrderConfirmed`, not `ConfirmOrder`. The verb in past tense is the event; the noun is the subject.
- **Essential data only.** Prefer IDs over full aggregates. Sending the full aggregate turns a domain event into a coupling trap.
- **No transport types in the event struct.** No `pgx`, no JSON tags as persistence, no NATS, no Kafka headers. Integration concerns live in `infrastructure/messaging/`.

## Example

```go
// File: internal/order/domain/model/events/order_confirmed.go
package events

import (
    "time"

    "github.com/acme/platform/order/domain/model/valueobjects"
)

type OrderConfirmed struct {
    OrderID    valueobjects.OrderID
    CustomerID valueobjects.CustomerID
    OccurredAt time.Time
}

func NewOrderConfirmed(
    orderID valueobjects.OrderID,
    customerID valueobjects.CustomerID,
    occurredAt time.Time,
) OrderConfirmed {
    return OrderConfirmed{
        OrderID:    orderID,
        CustomerID: customerID,
        OccurredAt: occurredAt,
    }
}
```

## Raising events from the aggregate

Two patterns; pick one and stay consistent.

**1. Return the events from the method** (pure):

```go
func (o *Order) Confirm(now time.Time) (events.OrderConfirmed, error) {
    if o.status != StatusPending {
        return events.OrderConfirmed{}, domain.ErrCannotConfirmOrder
    }
    o.status = StatusConfirmed
    return events.NewOrderConfirmed(o.id, o.customerID, now), nil
}
```

**2. Publish through a domain `EventRecorder` injected into the aggregate** (lets you record events during `Reconstitute`):

```go
type EventRecorder interface {
    Record(event events.DomainEvent)
}

func (o *Order) Confirm(now time.Time, recorder EventRecorder) error {
    if o.status != StatusPending {
        return domain.ErrCannotConfirmOrder
    }
    o.status = StatusConfirmed
    recorder.Record(events.NewOrderConfirmed(o.id, o.customerID, now))
    return nil
}
```

Both are valid. Pattern 1 is simpler; pattern 2 is friendlier to the outbox pattern below.

## Publishing — application and infrastructure

Publishing belongs to infrastructure. The application service records the event, and an infrastructure-side publisher (or outbox relay) sends it.

```go
// Application: just record and return.
events, err := order.Confirm(clock.Now())
if err != nil {
    return err
}
for _, e := range events {
    publisher.Record(ctx, e)  // publisher is an application-layer port
}
return repo.Save(ctx, order)
```

## Outbox / integration events

When an event must cross bounded-context boundaries reliably, add the outbox pattern: persist the integration event in the same transaction as the domain change, then publish asynchronously from an outbox relay. This guarantees at-least-once delivery without dual-write inconsistency.

```
application commits:
  UPDATE orders SET status = 'confirmed' WHERE id = $1;
  INSERT INTO outbox (event_type, payload, occurred_at) VALUES ($1, $2, $3);

outbox relay (separate process):
  SELECT * FROM outbox WHERE published_at IS NULL ORDER BY id LIMIT 100;
  publish to NATS / Kafka;
  UPDATE outbox SET published_at = now() WHERE id = $1;
```

Don't skip the outbox and write to NATS directly from the request handler — the network call can fail after the DB commit, losing the event.

## Checklist

- [ ] Event name in past tense (`OrderConfirmed`, not `ConfirmOrder`)
- [ ] Only essential data (prefer IDs)
- [ ] No transport or driver import in the event file
- [ ] Constructor injects `occurredAt` (don't call `time.Now()` inside the event)
- [ ] Events are immutable after construction
- [ ] Cross-context delivery uses the outbox pattern, not direct publish from the request path
