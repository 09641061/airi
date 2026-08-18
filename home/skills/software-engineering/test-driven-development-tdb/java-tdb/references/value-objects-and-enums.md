# Value Object & Enum Unit Tests

## Value Objects. Location: `[context-name]/domain/model/valueobjects/`

Value objects must be tested because they protect domain invariants. Every validation inside the record constructor must have unit tests.

- **Valid Creation:** Test that a valid value object can be created
- **Null Validation:** Test that null values are rejected when not allowed
- **Blank Validation:** Test that blank strings are rejected
- **Format Validation:** Test formats such as email, UUID, phone, code, or slug
- **Boundary Validation:** Test minimum and maximum allowed values
- **Business Rule Validation:** Test domain-specific rules inside the constructor

Checklist:
- [ ] Valid value object creation is tested
- [ ] Null values are tested
- [ ] Blank values are tested
- [ ] Invalid format is tested
- [ ] Boundary values are tested
- [ ] Business rule violations are tested
- [ ] Exception type and message are verified

## Enums. Location: `[context-name]/domain/model/valueobjects/` or `[context-name]/domain/model/enums/`

Enums must be tested when they contain behavior, conversion methods, labels, codes, or domain rules.

- **Allowed Values:** Verify expected enum values exist
- **Code Mapping:** Test conversion from code/string to enum
- **Invalid Mapping:** Test invalid values are rejected
- **Business Behavior:** Test methods inside the enum
- **No Tests for Empty Enums:** Do not test enums that only declare constants and have no behavior

Checklist:
- [ ] Enum values with behavior are tested
- [ ] String/code conversion is tested
- [ ] Invalid conversion is tested
- [ ] Business methods are tested
- [ ] Pure constant-only enums are not over-tested
