# Performance/Timeout Rules, Test-Level Usage & Code Coverage

## Performance and Timeout Rules

Mutation testing can execute tests repeatedly and may significantly increase test execution time.

The mutation configuration should:

* Define execution timeouts.
* Detect mutations that cause infinite execution.
* Limit initial mutation runs to relevant modules.
* Execute only relevant tests when possible.
* Reuse previous results when supported.
* Use parallel execution only when tests are isolated.
* Avoid unnecessary external infrastructure.
* Prefer fast tests for frequent mutation runs.

Large projects may separate mutation analysis into targeted and complete executions.

## Unit and Integration Test Usage

Mutation testing should prioritize fast and isolated tests.

Recommended priority:

1. Unit tests
2. Focused integration tests
3. Broader integration tests
4. End-to-end tests only when necessary

Unit tests should normally provide most mutation feedback.

Integration tests should participate when behavior cannot be meaningfully validated in isolation.

Slow end-to-end suites should not normally be the primary mechanism for detecting mutants.

## Mutation Testing and Code Coverage

Code Coverage measures whether production code was executed during testing.

Mutation Testing measures whether tests can detect incorrect behavioral changes in that code.

High code coverage does not guarantee strong tests.

A project may have:

```text
High Code Coverage
Low Mutation Score
```

This indicates that tests execute the production code but do not adequately verify its behavior.

Use code coverage to identify untested code.

Use mutation testing to identify insufficiently tested behavior.

Both metrics should be interpreted together.
