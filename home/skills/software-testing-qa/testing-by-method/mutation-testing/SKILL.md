---
name: mutation-testing
description: Apply mutation testing to evaluate and improve the effectiveness of an existing unit/integration test suite — not to write new production code. Use whenever asked to run mutation testing, choose mutation operators, classify mutants, analyze surviving/equivalent mutants, calculate a mutation score, or set up a mutation quality gate in CI. Language-agnostic; complements code coverage, does not replace it.
---

# Mutation Testing

Mutation Testing does not replace conventional testing. Its purpose is to verify whether existing tests are capable of detecting behavioral defects intentionally introduced into production code.

## Core principles

* Existing unit and integration tests must pass before mutation testing begins.
* Mutations must target meaningful application behavior.
* Tests must verify expected outcomes through explicit assertions.
* Surviving mutants must be analyzed before adding or modifying tests.
* Equivalent mutants must not result in artificial or meaningless tests.
* Generated code, third-party code, and irrelevant boilerplate should normally be excluded.
* Mutation results must complement code coverage rather than replace it.
* Mutation testing must remain deterministic and repeatable.
* **Always use an established, standard mutation tool and its documented operators/taxonomy for the project's stack — never invent ad hoc mutation logic.** Check [references/tools-and-standards.md](references/tools-and-standards.md) before configuring anything.

## Workflow

Follow this order — each step builds on the previous one. Load the matching reference file only when you reach that step; don't front-load all of them.

Before step 1, check [references/tools-and-standards.md](references/tools-and-standards.md) and pick the standard mutation framework for the project's language (Stryker, PITest, Mutmut, cargo-mutants) — its documented operators and reporting already implement the taxonomy described below, so don't reimplement it.

| # | Step | Reference |
|---|------|-----------|
| 1 | Verify the test suite & pick mutation scope | [references/preparation-and-scope.md](references/preparation-and-scope.md) |
| 2 | Select mutation operators (relational, conditional, arithmetic, return-value, statement-removal) | [references/mutation-operators.md](references/mutation-operators.md) |
| 3 | Execute mutations, classify mutants, compute the mutation score | [references/execution-and-classification.md](references/execution-and-classification.md) |
| 4 | Strengthen assertions, boundary & conditional coverage | [references/test-quality.md](references/test-quality.md) |
| 5 | Analyze surviving mutants; identify equivalent mutants | [references/surviving-and-equivalent-mutants.md](references/surviving-and-equivalent-mutants.md) |
| 6 | Tune performance/timeouts; decide which test level runs mutations; relate to code coverage | [references/performance-and-test-levels.md](references/performance-and-test-levels.md) |
| 7 | Configure the mutation tool, wire it into CI, define the quality gate | [references/configuration-and-ci.md](references/configuration-and-ci.md) |

Before shipping, check [references/pitfalls-checklist-and-rollout.md](references/pitfalls-checklist-and-rollout.md) for common pitfalls, the recommended rollout order, the final checklist, and the minimum standard every project should implement.

If a worked example clarifies the concept (e.g. explaining why 100% line coverage can still hide a weak test suite), walk through [references/worked-example.md](references/worked-example.md).
