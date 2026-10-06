# Mocking and Fakes

The default in this skill is **no mocking library, no interface invented only for tests, no driver mock**. The only "mocking" you do is a small hand-rolled fake of an existing port.

## The rule

Mock only **boundaries**. A boundary is something that:

- Talks to a real database, broker, or external service
- Performs real I/O the test can't afford (network calls, file system)
- Tracks time non-deterministically
- Generates random IDs

Inside the package under test, you don't mock anything.

## Good candidates for fakes

| Boundary | Fake type |
|----------|-----------|
| Repository port | In-memory map keyed by aggregate ID |
| ACL facade | Struct that returns canned `(<id>, err)` pairs |
| Time | `fixedClock` returning a constant `time.Time` |
| ID generator | Counter or pre-baked sequence |
| Email sender / notifier | Recorder that captures calls |
| External HTTP service | `httptest.NewServer` returning canned responses (rarely needed) |

## Bad candidates (don't fake these)

| What | Why |
|------|-----|
| Value objects | They are part of the production code. The test uses the real type. |
| Aggregates / entities | Same — real types carry the invariants. |
| Simple functions in the same package | They run in milliseconds. Test the public surface, not internals. |
| The driver (`pgx`, `database/sql`, GORM) | The integration test exercises the real driver. A mock is a lie. |
| Every dependency of every class | You'll end up with a parallel "test architecture" that has to be kept in sync with the real one. |

## Fakes, not mocks

A **fake** is a working implementation of the port, simpler than the real one. It has state, it has behavior, and it can be exercised through the same interface.

A **mock** is a framework-generated stub that records calls and returns canned answers. It usually requires:

- Generating the mock from an interface
- Configuring expectations ("when X is called with Y, return Z")
- Asserting on call counts and arguments

Mocks add three problems:

1. **Refactor hostility.** Renaming a method or adding a parameter forces a mock regeneration across the test suite.
2. **Implementation coupling.** The test starts asserting on call counts and argument values, which is testing implementation, not behavior.
3. **Indirection.** The reader has to follow the mock back to the interface to know what's actually being tested.

Fakes don't have these problems. The test sees the real port, the fake implements it, the assertion is on the resulting state of the system.

## Example: fake vs mock

**Mock (avoid):**

```go
ctrl := gomock.NewController(t)
defer ctrl.Finish()
repo := mocks.NewMockOrderRepository(ctrl)
repo.EXPECT().FindByID(gomock.Any(), valueobjects.OrderID{Value: 1}).
    Return(&aggregates.Order{...}, nil)
repo.EXPECT().Save(gomock.Any(), gomock.Any()).Return(nil)

svc := application.NewOrderService(repo, fixedClock{...})
err := svc.ConfirmOrder(context.Background(), valueobjects.OrderID{Value: 1})
// ...
```

**Fake (preferred):**

```go
repo := newFakeOrderRepository()
seedOrder(t, repo, valueobjects.OrderID{Value: 1}, aggregates.StatusPending)

svc := application.NewOrderService(repo, fixedClock{...})
err := svc.ConfirmOrder(context.Background(), valueobjects.OrderID{Value: 1})

got, _ := repo.FindByID(context.Background(), valueobjects.OrderID{Value: 1})
if got.Status() != aggregates.StatusConfirmed {
    t.Fatalf("status = %q, want confirmed", got.Status())
}
```

The fake version reads top-to-bottom without jumping to a mock library. The reader sees what was arranged, what was acted on, and what was asserted — in that order.

## Don't invent an interface for the fake

The Go community overuses the `Interface` keyword. If the production code has a struct, write a fake of the struct, not a new interface.

```go
// Production code: a concrete type, no interface.
type SQLOrderRepository struct { db *pgxpool.Pool }
func (r *SQLOrderRepository) Save(ctx context.Context, o *aggregates.Order) error { ... }
func (r *SQLOrderRepository) FindByID(ctx context.Context, id valueobjects.OrderID) (*aggregates.Order, error) { ... }

// In the application test, embed the concrete type and override only what you need.
type fakeOrderRepository struct {
    *persistence.SQLOrderRepository // panic on unknown calls
    orders map[valueobjects.OrderID]*aggregates.Order
    saves  int
}
```

Or, more commonly, just write the fake from scratch with the same method set. Embedding is useful when the production type has many methods and the test only needs to override a few.

## Interfaces for testing

The right time to introduce an interface is when production code needs to depend on an abstraction — for example, the application service depending on a repository **port** so the adapter can be swapped at deploy time. That's the DDD port/adapter split, not a test pattern.

The wrong time is "I want to mock this in tests." If a concrete type has a single implementation and no real abstraction is required, don't introduce an interface for the test. Use a fake of the concrete type.

## When a real abstraction is required

Some boundaries are real and need an interface even in production:

- `Clock` (production uses `realClock`, tests use `fixedClock`)
- `IDGenerator` (production uses UUID/random, tests use a counter)
- `UnitOfWork` (production uses pgx-backed, tests use in-memory)

These interfaces live in the production code, in the same package as the consumer. They are not test-only.

## Mocking libraries to avoid

- `github.com/golang/mock` (gomock) — generates mocks, expects DSL
- `github.com/stretchr/testify/mock` — manual mock scaffolding
- `github.com/vektra/mockery` — codegen for gomock
- `github.com/pashagolub/pgxmock` — mocks `pgx/v4` (deprecated)
- `github.com/pashagolub/pgxmock/v2` — mocks `pgx/v5`
- `github.com/DATA-DOG/go-sqlmock` — mocks `database/sql`
- GORM mock mode — tests the mock, not GORM

All of these test a parallel universe. The integration test is the only honest test of a database adapter.

## Checklist

- [ ] No `gomock`, `testify/mock`, `mockery`, `pgxmock`, `sqlmock`, or GORM mock
- [ ] Fakes are hand-rolled in the test package
- [ ] Fakes implement an existing port from the production code
- [ ] No interface was created solely for the test
- [ ] Tests assert on the resulting state, not on call counts
- [ ] Time, IDs, and randomness are abstracted only when production code needs the abstraction
