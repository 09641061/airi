# Worked Example: Weak Assertions vs. Mutation-Proof Tests

Generic, language-agnostic pseudocode showing how mutation testing uncovers weak test assertions that 100% line coverage does not catch.

## Source Function Under Test (Original Code)

```text
FUNCTION IS_ELIGIBLE_FOR_DISCOUNT(age, total_purchases):
  IF age >= 65 OR total_purchases > 500.00 THEN:
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION
```

## Weak Test Suite (Achieves 100% Line Coverage, but Low Mutation Score)

```text
TEST_SUITE "Weak Discount Eligibility Suite":

  TEST "Senior customer is eligible":
    RESULT = IS_ELIGIBLE_FOR_DISCOUNT(70, 100.00)
    ASSERT RESULT IS_NOT_NULL  // Weak assertion! Does not check if TRUE!
```

## Mutation Engine Execution (Introduces Mutants)

```text
MUTANT 1 (Relational Mutation): Change `age >= 65` to `age > 65`
  - Execution: IS_ELIGIBLE_FOR_DISCOUNT(70, 100.00) -> Returns TRUE
  - Weak Test Result: PASSED (Mutant SURVIVED! Vulnerability missed)

MUTANT 2 (Conditional Mutation): Change `OR` to `AND`
  - Execution: IS_ELIGIBLE_FOR_DISCOUNT(70, 100.00) -> Returns FALSE
  - Weak Test Result: PASSED (Mutant SURVIVED! Weak assertion allowed bug)
```

Both mutants survive because the assertion only checks "not null," never the actual expected value — a textbook case of high coverage hiding a weak test suite (see [test-quality.md](test-quality.md)).

## Refactored Strong Test Suite (Kills All Mutants)

```text
TEST_SUITE "Refactored Strong Discount Eligibility Suite":

  TEST "Senior customer age exactly 65 is eligible (Kills Mutant 1 - BVA Boundary)":
    ASSERT IS_ELIGIBLE_FOR_DISCOUNT(65, 100.00) == TRUE

  TEST "High spender with age < 65 is eligible (Kills Mutant 2 - OR Condition)":
    ASSERT IS_ELIGIBLE_FOR_DISCOUNT(40, 500.01) == TRUE

  TEST "Non-senior with low purchases is ineligible":
    ASSERT IS_ELIGIBLE_FOR_DISCOUNT(40, 100.00) == FALSE
```

Checklist when refactoring a weak suite like this:

- [ ] Weak assertions replaced with explicit value assertions
- [ ] Boundary conditions tested to kill relational operator mutants
- [ ] Mutation score recalculated post-refactoring to verify it clears the project threshold (e.g. >80%)
