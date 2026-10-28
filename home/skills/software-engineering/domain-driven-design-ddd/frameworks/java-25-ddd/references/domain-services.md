# Domain Services

Location: `[context-name]/domain/services/`

A domain service contains a pure business policy or calculation that does not naturally belong to one entity or value object.

- **Framework-free:** no Spring, JPA, repositories, HTTP, transactions, or messaging.
- **Concrete stateless class by default.** Define an interface only when the model needs a genuine policy contract or a substitutable implementation.
- **Business-language name:** `EnrollmentPolicy`, `EligibilitySpecification`, `PricingCalculator`.
- **Not `*CommandService` / `*QueryService`:** those belong to application.

## Checklist

- [ ] The rule genuinely does not belong to one entity or value object
- [ ] Methods express a policy in the ubiquitous language
- [ ] The type contains no framework, persistence, or I/O dependency
- [ ] An interface exists only when it provides a meaningful contract
- [ ] Use-case coordination remains in an application service
