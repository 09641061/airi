# Mutation Execution, Classification & Score

## Mutation Execution

Mutation testing should follow this sequence:

1. Verify that the normal test suite passes.
2. Select production code to mutate.
3. Select appropriate mutation operators.
4. Generate a mutation.
5. Execute the relevant tests.
6. Record the result.
7. Restore the original implementation.
8. Continue with the remaining mutations.
9. Generate the final mutation report.

Mutation tooling must not leave production code permanently modified.

## Mutant Classification

Generated mutants should be classified using the following categories.

| Status          | Definition                                                        | Expected Action                                         |
| --------------- | ------------------------------------------------------------------ | -------------------------------------------------------- |
| **Killed**      | At least one test failed because of the mutation.                 | No action required unless test quality requires review. |
| **Survived**    | All tests passed despite the mutation.                            | Investigate test effectiveness.                          |
| **No Coverage** | No relevant test executed the mutated code.                       | Review missing test coverage.                            |
| **Timed Out**   | The mutation caused excessive execution or an infinite operation. | Review and classify according to project policy.        |
| **Equivalent**  | The mutation produces no observable behavioral difference.        | Document or exclude from evaluation.                     |
| **Error**       | The mutation could not be executed correctly.                     | Review configuration or tooling.                         |

A surviving mutant does not necessarily represent a production defect.

It indicates that the existing test suite cannot distinguish the original behavior from the mutated behavior.

## Mutation Score

Mutation Score measures the proportion of meaningful mutants detected by the test suite.

The general calculation is:

```text
Mutation Score =
Killed Mutants / (Total Mutants - Equivalent Mutants) * 100
```

The project should establish an appropriate minimum mutation score according to the importance and maturity of the software.

A mutation score of approximately **80% or higher** may be used as an initial target for critical application logic, but the threshold should be adapted to the project.

Mutation score must not be artificially increased by excluding meaningful code or valid surviving mutants.
