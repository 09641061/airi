# Assertion Quality, Boundary & Conditional Testing

## Assertion Quality

Mutation testing should identify weak assertions and encourage explicit verification of expected behavior.

Weak assertions include checks that only confirm that an operation completed or returned some value.

Examples:

```text
result is not null
response exists
collection size is greater than or equal to zero
operation does not throw
```

Prefer assertions that verify the actual expected outcome:

```text
result equals expected value
state equals expected state
exception equals expected exception
collection contains expected elements
operation receives expected arguments
expected side effect occurred
```

Tests must verify behavior rather than simply verify that code executed.

## Boundary Testing

Relational mutations frequently reveal missing boundary tests.

For a rule such as:

```text
value >= minimum
```

tests should consider:

```text
minimum - 1
minimum
minimum + 1
```

When a maximum exists, consider:

```text
maximum - 1
maximum
maximum + 1
```

Only meaningful values within the application's domain should be tested.

Boundary tests should be especially prioritized for:

* Minimum and maximum values
* Age limits
* Prices
* Quantities
* Length limits
* Pagination
* Date ranges
* Time ranges
* Thresholds
* Business limits

## Conditional Testing

Conditions containing multiple expressions should be tested independently.

For an `OR` condition, relevant scenarios normally include:

* First condition true and second false
* First condition false and second true
* Both conditions false
* Both conditions true when behavior differs or is relevant

For an `AND` condition, tests should verify that failure of either required condition produces the expected result.

Do not generate combinations mechanically.

Only test combinations capable of changing meaningful application behavior.
