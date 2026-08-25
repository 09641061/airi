# Test Suite Preparation & Mutation Scope

## Test Suite Preparation

Before executing mutation testing, verify the existing test suite.

Requirements:

* All relevant unit tests pass.
* All relevant integration tests pass.
* Tests are deterministic.
* Flaky tests are corrected or excluded from mutation execution.
* Relevant tests are not disabled or ignored.
* Test execution does not depend on execution order.
* Required test dependencies are stable.
* Execution timeouts are configured.
* The project can execute its tests automatically without manual intervention.

Mutation testing must not be used to analyze a test suite that is already failing.

## Mutation Scope

Mutation testing should prioritize code containing meaningful behavior.

Recommended targets include:

* Business rules
* Domain logic
* Calculations
* Validation rules
* Conditional logic
* State transitions
* Policies
* Application use cases
* Authorization decisions
* Transformations
* Critical decision logic

Lower-priority or excluded targets may include:

* Generated code
* Third-party code
* Simple getters and setters
* Data structures without behavior
* Configuration code
* Logging-only code
* Serialization boilerplate
* Database migrations
* Generated clients or adapters

Mutation scope should begin with critical behavior and expand progressively.
