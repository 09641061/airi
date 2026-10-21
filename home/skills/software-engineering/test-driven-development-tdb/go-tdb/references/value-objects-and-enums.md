# Value Objects & Enums — Test Actual Rules

**Production location:** `[context-name]/domain/model/valueobjects/`

**Test location:** alongside the production Go package, in `*_test.go`.

## What is worth testing

- Constructor accepts values valid under a documented business rule.
- Constructor rejects each independently invalid input using a **specific domain error** (`errors.Is` or typed errors); distinguish blank, malformed, out-of-range, forbidden, and conflicting values when the contract distinguishes them.
- Boundary analysis: `min-1`, `min`, `min+1`, `max-1`, `max`, `max+1` **only where that boundary is meaningful**; do not manufacture arbitrary data.
- Semantic equality: two independent instances representing the same concept behave as equal under the domain's equality contract.
- Canonicalization only if required: normalization must not silently destroy distinct meaningful values.
- Immutability: after constructing a VO from a slice/map/pointer, mutating the original input must not change the VO; mutating a returned slice/map must not change the VO.
- Invalid zero value: if a zero-value struct is invalid, production APIs must prevent treating it as valid, or clearly define the zero value as valid. Test through the public API.
- Typed enum/constants: invalid status/type must be rejected at the boundary that interprets it; avoid tests that merely confirm constants equal themselves.
- Numeric precision, overflow, rounding, or timezone behavior **when the domain actually needs them**; prefer exact representations for money/units and assert precise outputs.

## Strong test template

This is **generic pseudocode with Go syntax**. Replace domain names and constants with actual documented rules; do not add production APIs just to make a sample compile.

```go
func TestValueObject_New_RejectsValueBelowMinimum(t *testing.T) {
    // Arrange: choose the documented boundary (not a random number).
    invalid := domain.MinimumAllowedValue - 1

    // Act.
    _, err := domain.NewValueObject(invalid)

    // Assert: the rejection is a domain contract, not just any error.
    require.ErrorIs(t, err, domain.ErrBelowMinimum)
}
```

### Table-driven tests for one rule

```go
func TestValueObject_New_EnforcesInclusiveBounds(t *testing.T) {
    cases := []struct {
        name    string
        value   int
        wantErr error
    }{
        {"below minimum", minValue - 1, domain.ErrBelowMinimum},
        {"exactly minimum", minValue, nil},
        {"exactly maximum", maxValue, nil},
        {"above maximum", maxValue + 1, domain.ErrAboveMaximum},
    }

    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            value, err := domain.NewValueObject(tc.value)
            if tc.wantErr != nil {
                require.ErrorIs(t, err, tc.wantErr)
                return
            }
            require.NoError(t, err)
            require.Equal(t, tc.value, value.Value())
        })
    }
}
```

`minValue` and `maxValue` above are domain-specific test values; the sample is **not standalone source code**. In the actual suite, use a real rule and do not expose internal fields only to facilitate assertions.

## Immutable value contract template

1. Create a VO with a mutable input collection.
2. Mutate the caller-owned input.
3. Observe that `vo.Values()` still returns the original logical value.
4. Mutate the returned collection.
5. Observe that a second `vo.Values()` call is unchanged.

**Go nuance:** `struct` value semantics alone do **not** protect referenced slices, maps, or pointers.

## Reject these tests

- `require.NotNil(t, value)` when the value's essential domain meaning was never asserted.
- Testing `const StatusActive == "active"` without a serialization or public contract requirement.
- Repeating the constructor implementation inside the test to calculate expected results.
- Mocking the Value Object or testing a fake Value Object.
- Testing an unexported field with reflection just to raise coverage.

## Checklist

- [ ] Every documented validation rule has valid and invalid witnesses.
- [ ] Boundary behavior is covered at exact thresholds.
- [ ] Distinct error categories are verified when contractually relevant.
- [ ] Immutability is proven for reference-bearing values.
- [ ] Tests assert meaningful values, not only `err == nil`.
- [ ] No mocks, filesystem, HTTP, or DB.
