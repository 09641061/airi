# Common Pitfalls, Implementation Order, Checklist & Minimum Standard

## Common Pitfalls

Avoid the following practices:

1. Running mutation testing while normal tests are failing.
2. Treating code coverage as proof of test effectiveness.
3. Attempting to kill every mutant without analysis.
4. Creating meaningless tests for equivalent mutants.
5. Mutating generated or third-party code unnecessarily.
6. Enabling mutation operators without evaluating their usefulness.
7. Using weak assertions that only verify execution.
8. Mutating the entire codebase during initial adoption.
9. Excluding meaningful mutants to artificially increase the score.
10. Testing implementation details instead of observable behavior.
11. Using mutation testing as a replacement for conventional testing.
12. Changing correct production behavior only to satisfy mutation testing.

## Mutation Testing Implementation Order

Recommended implementation order:

1. Verify the existing test suite.
2. Identify critical application logic.
3. Configure mutation targets.
4. Configure relevant mutation operators.
5. Establish execution limits.
6. Execute an initial mutation baseline.
7. Review surviving mutants.
8. Improve weak or missing tests.
9. Execute mutation testing again.
10. Establish an acceptable mutation score baseline.
11. Integrate mutation testing into automated quality control.
12. Expand mutation scope progressively.

## Final Mutation Testing Checklist

### Baseline

* [ ] All relevant tests pass.
* [ ] Tests are deterministic.
* [ ] Flaky tests are resolved.
* [ ] Relevant tests are not ignored.
* [ ] Execution timeout is configured.

### Scope

* [ ] Critical production logic is selected.
* [ ] Generated code is excluded.
* [ ] Third-party code is excluded.
* [ ] Boilerplate is excluded when appropriate.

### Mutation Operators

* [ ] Relational mutations are enabled when relevant.
* [ ] Conditional mutations are enabled when relevant.
* [ ] Arithmetic mutations are enabled when relevant.
* [ ] Return-value mutations are enabled when relevant.
* [ ] Statement-removal mutations are enabled when relevant.

### Analysis

* [ ] Killed mutants are identified.
* [ ] Surviving mutants are reviewed.
* [ ] No-coverage mutants are reviewed.
* [ ] Equivalent mutants are identified.
* [ ] Timeout mutants are reviewed.

### Test Quality

* [ ] Assertions verify explicit expected behavior.
* [ ] Boundary conditions are tested.
* [ ] Conditional scenarios are tested.
* [ ] Failure paths are tested.
* [ ] State transitions are tested.
* [ ] Relevant exceptions are verified.
* [ ] Tests remain deterministic and independent.

### Metrics

* [ ] Mutation Score is calculated.
* [ ] A mutation baseline is established.
* [ ] Critical modules meet the expected quality level.
* [ ] Exclusions do not artificially increase the score.

### Continuous Integration

* [ ] Mutation testing can execute automatically.
* [ ] Mutation reports are generated.
* [ ] Mutation regressions are detected.
* [ ] Critical score reductions can block integration.

## Recommended Minimum Standard

Every project using Mutation Testing should minimally implement:

1. A stable conventional test suite.
2. Clearly defined mutation targets.
3. Meaningful mutation operators.
4. Explicit analysis of surviving mutants.
5. Boundary testing for relevant conditions.
6. Strong behavioral assertions.
7. Identification of equivalent mutants.
8. Mutation Score calculation.
9. An established project mutation baseline.
10. Automated detection of mutation-score regressions.

The objective of Mutation Testing is not to achieve a perfect score.

The objective is to verify that the test suite can detect meaningful defects that alter expected software behavior.
