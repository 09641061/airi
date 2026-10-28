# Application Services and Use-Case Handlers

Location: `[context-name]/application/`

Application services coordinate use cases: they validate use-case preconditions, load aggregates through ports, invoke domain behavior, persist changes, and coordinate outbound capabilities.

- **Contracts:** a use-case interface belongs to application when it serves as an inbound port, a public module API, or a real replaceable boundary. With a single internal implementation and no meaningful port, a concrete class is enough: do not force the interface + `Impl` pair.
- **Responsibilities:** use-case coordination, preconditions (missing record, authorization, idempotency, retries), consistent translation of known failures, and returning a result, an id, or a read model.
- **A conditional in an application service is not automatically a domain leak.** A rule that must always hold for an aggregate belongs to that aggregate; existence checks, authorization, and workflow coordination are valid application concerns.
- **Do not expose raw framework exceptions to the client.** Do not catch broad exceptions and copy `e.getMessage()` into the HTTP response.

```java
// File: [context-name]/application/usecases/EnrollmentService.java
package com.acme.center.platform.[context].application.usecases;

@Service
public class EnrollmentService {
    private final EnrollmentRepository enrollmentRepository;
    private final ApplicationEventPublisher eventPublisher;

    public EnrollmentService(EnrollmentRepository enrollmentRepository,
                             ApplicationEventPublisher eventPublisher) {
        this.enrollmentRepository = enrollmentRepository;
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public Long confirm(ConfirmEnrollmentCommand command) {
        var id = new EnrollmentId(command.enrollmentId());
        var enrollment = enrollmentRepository.findById(id)
                .orElseThrow(() -> new EnrollmentNotFoundException(id.value()));
        enrollment.confirm();
        var saved = enrollmentRepository.save(enrollment);
        saved.domainEvents().forEach(eventPublisher::publishEvent);
        saved.clearDomainEvents();
        return saved.id().value();
    }
}
```

## Transactions

A transaction on the use-case boundary is a pragmatic default for commands that need atomic persistence. Use `@Transactional(readOnly = true)` for queries when it adds value. Keep transactions inside a bounded context, and do not wrap remote calls or another context's work in the same transaction.

Default: one transaction modifies one aggregate root. A local multi-aggregate transaction can be justified by a documented immediate-consistency invariant in a modular monolith; it is not an unexamined default.

## Checklist

- [ ] One use case per service (or one service per aggregate, without mixing contexts)
- [ ] Domain/port dependencies injected through the constructor
- [ ] `@Transactional` on the write use-case boundary
- [ ] No reimplementation of aggregate invariants
- [ ] No broad exception catching and no exposure of internal messages
- [ ] No redundant `Impl`/`Interface` pair when there is no real boundary
