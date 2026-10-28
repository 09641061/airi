# Domain Model

Keep business meaning and invariants in the domain. Model only the concepts, rules, and consistency boundaries that the bounded context actually owns. Domain code stays independent of Gin, HTTP, configuration, persistence technologies, and other contexts' private models. Keep the model in cohesive packages: one package per aggregate or subdomain, not one package per file type.

## Value Objects

Value Objects represent cohesive domain concepts by value and preserve their invariants.

- **Named type over wrapper struct:** for a single primitive, declare a named type (`type CourseID string`) instead of a struct with a `Value` field.
- **Constructor validates:** create the value through a constructor that returns an error; an invalid value must not be constructible.
- **Struct with unexported fields** when the value carries several attributes; expose behavior through methods.
- **Immutability:** prefer operations that return a new value; defensively copy mutable members such as slices and maps.
- **Zero value:** decide and document whether the zero value is valid; if it is not, make every construction path go through the constructor.
- **Equality, normalization, and representation** follow business semantics.
- Never add database-specific tags or framework dependencies for persistence convenience.

```go
// internal/[context-name]/domain/course_id.go
package courses

import "errors"

var ErrInvalidCourseID = errors.New("course id must not be empty")

type CourseID string

func NewCourseID(raw string) (CourseID, error) {
	if raw == "" {
		return "", ErrInvalidCourseID
	}
	return CourseID(raw), nil
}
```

**Checklist**

- [ ] Value Object represents one cohesive domain concept.
- [ ] All construction paths preserve invariants, including zero-value/decoding considerations.
- [ ] No accidental mutable state escapes through slices, maps, or pointers.
- [ ] Equality and normalization follow business semantics.
- [ ] No SQL/ORM/document/HTTP coupling in the domain.

## Entities, states, and aggregates

- Give entities identity and lifecycle behavior only when the domain requires them; keep behavior with the object that owns the rule.
- Validate the initial state in a constructor (`NewX(...) (*X, error)`).
- Express behavior through domain-named methods with pointer receivers (`Confirm`, `Cancel`, `AddItem`), never through exported setters.
- Represent allowed states explicitly (a named string type with constants) and reject invalid transitions from the domain method, not only at the transport layer.
- Choose aggregate boundaries around invariants that must hold consistently. The root owns its invariants and every change to its members; a rejected operation leaves the aggregate unchanged.
- Reference other aggregates by identifier, not by object pointer.
- Do not derive aggregates from tables and do not create scaffolding just to fill a layered tree.
- Do not introduce an abstract base aggregate, an injected event publisher, or a factory hierarchy — Go has no inheritance and these add ceremony without behavior.

```go
// internal/[context-name]/domain/enrollment.go
package enrollments

import "errors"

var (
	ErrAlreadyConfirmed = errors.New("enrollment is already confirmed")
	ErrNotPending       = errors.New("only pending enrollments can be confirmed")
)

type Status string

const (
	StatusPending   Status = "PENDING"
	StatusConfirmed Status = "CONFIRMED"
)

type Enrollment struct {
	id     EnrollmentID
	status Status
	events []EnrollmentConfirmed
}

func NewEnrollment(id EnrollmentID) *Enrollment {
	return &Enrollment{id: id, status: StatusPending}
}

func (e *Enrollment) Confirm() error {
	switch e.status {
	case StatusConfirmed:
		return ErrAlreadyConfirmed
	case StatusPending:
		e.status = StatusConfirmed
		e.events = append(e.events, EnrollmentConfirmed{EnrollmentID: e.id})
		return nil
	default:
		return ErrNotPending
	}
}
```

**Checklist**

- [ ] Every entity and aggregate has a validating constructor.
- [ ] Behavior is exposed through domain-named methods, not setters.
- [ ] Invalid transitions return a business error and leave the object unchanged.
- [ ] Aggregate roots own their invariants; other aggregates are referenced by identifier.
- [ ] Successful transitions record events; rejected ones record none.
- [ ] No abstract base aggregate, injected event publisher, or factory hierarchy exists without a concrete need.

## Domain Events

Domain Events describe significant business facts that have already occurred.

- Name them as past-tense facts.
- Include only the information needed to describe the fact; identifiers are usually preferable to large object graphs.
- Make payloads immutable or safely copied. Obtain occurrence time from a controlled source for deterministic tests.
- Record success events only after the corresponding transition succeeds. A rejected transition must not report a successful fact.
- A Domain Event is a fact inside one context. It is not automatically an integration event; cross-context communication happens through explicitly published contracts.

**Outbox — use only when delivery must be durable.** When a cross-context fact must survive process failure, write it to an outbox table in the same transaction as the state change and publish it through a retrying relay. The relay provides at-least-once delivery, so consumers must be idempotent. An outbox is not required for every event, and it only makes sense when the selected storage engine supports the required semantics.

**Checklist**

- [ ] Event name is a past-tense business fact.
- [ ] Payload is immutable or safely copied.
- [ ] Timestamp and event identity are included when required.
- [ ] Domain Events and Integration Events are not conflated.
- [ ] Outbox only when delivery must be durable and the storage engine supports it.

## Domain Services

A Domain Service expresses a business policy or calculation that does not naturally belong to one entity or value object. It is not an application Command Service or Query Service.

- Put state and behavior in an Aggregate when that aggregate owns the invariant.
- Introduce a domain service only for a cross-object policy or calculation with no natural entity home.
- Prefer stateless services and real domain types in their APIs.
- Add a dependency interface only when the policy genuinely requires an external capability; keep its adapter outside the domain.
- Unit-test rules with real domain objects.

**Checklist**

- [ ] Service contains domain policy, not HTTP or database orchestration.
- [ ] Aggregate-owned invariants remain in aggregates.
- [ ] Domain dependencies remain domain-level contracts.
- [ ] Rules are unit-tested with real domain objects.
