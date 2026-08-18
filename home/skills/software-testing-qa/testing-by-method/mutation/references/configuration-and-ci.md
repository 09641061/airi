# Mutation Configuration, CI & Quality Gate

## Mutation Configuration

Mutation testing configuration should define:

* Production code targets
* Test targets
* Mutation operators
* Excluded files or modules
* Generated-code exclusions
* Execution timeout
* Mutation score threshold
* Report output
* Parallel execution policy
* Incremental execution policy

Every exclusion must have a valid technical reason.

Broad exclusions intended only to improve the mutation score should not be permitted.

## Continuous Integration Requirements

Mutation testing should be integrated into automated quality control once an appropriate baseline has been established.

The pipeline should normally execute:

1. Build validation
2. Unit tests
3. Integration tests
4. Mutation testing
5. Mutation quality evaluation

For large projects, mutation testing may use different scopes depending on execution context:

* Changed code during regular development
* Critical modules during pull requests
* Broader analysis on the main branch
* Complete mutation analysis periodically

A mutation quality gate may prevent integration when the mutation score falls below the defined project threshold.

## Mutation Quality Gate

Projects should establish mutation quality criteria.

Quality gates should prioritize:

* Critical business rules
* Domain invariants
* Financial calculations
* Authorization decisions
* Validation rules
* State transitions
* Security-sensitive decisions
* Critical application workflows

The quality gate should detect meaningful regressions in test effectiveness.

Confirmed equivalent mutants should not cause the quality gate to fail.
