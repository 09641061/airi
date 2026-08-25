# Surviving Mutant Analysis & Equivalent Mutants

## Surviving Mutant Analysis

Every meaningful surviving mutant should be reviewed.

For each survivor:

1. Identify the code modified by the mutation.
2. Determine the behavioral difference introduced.
3. Determine whether that behavior is relevant.
4. Identify which test should detect the change.
5. Review the existing assertion.
6. Add or improve the test when necessary.
7. Execute the normal test suite.
8. Execute mutation testing again.
9. Verify that the relevant mutant is killed.

Common causes of surviving mutants include:

* Missing test scenarios
* Weak assertions
* Missing boundary tests
* Missing failure-path tests
* Only happy-path testing
* Incomplete conditional testing
* Missing state verification
* Missing interaction verification
* Missing exception assertions
* Untested return values
* Dead code
* Equivalent mutations

Tests should not be written specifically to satisfy the mutation engine. They must continue to describe valid expected application behavior.

## Equivalent Mutants

An equivalent mutant modifies source code without changing observable behavior.

Equivalent mutants should be:

* Reviewed before classification
* Documented when relevant
* Excluded from mutation score calculations when possible
* Ignored when no meaningful test can distinguish the mutation

Do not create artificial tests or modify correct production code solely to kill an equivalent mutant.
