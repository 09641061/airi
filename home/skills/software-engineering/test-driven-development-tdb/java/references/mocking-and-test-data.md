# Mocking Rules & Test Data Strategy

## Mocking Rules

Mocks should only be used for dependencies outside the unit under test.

- **Mock Repositories:** When testing application services
- **Mock ACL Services:** When testing command services that depend on external contexts
- **Mock Facades:** When testing ACL services
- **Mock Event Publishers:** When testing event publication flow
- **Do Not Mock Value Objects:** Use real value objects
- **Do Not Mock Aggregates:** Use real aggregates unless impossible
- **Do Not Mock the Class Under Test:** Only mock its dependencies

Checklist:
- [ ] Only dependencies are mocked
- [ ] Value objects are real
- [ ] Aggregates are real
- [ ] Commands and queries are real
- [ ] Repository is mocked in service tests
- [ ] External services are mocked
- [ ] Class under test is not mocked

## Test Data Creation Strategy

Test data must be clear, reusable, and easy to understand.

- **Use Simple Valid Data:** Prefer obvious values like valid IDs, names, and prices
- **Avoid Random Data:** Random values make failures harder to reproduce
- **Use Test Builders When Needed:** Use builders or factory methods for complex aggregates
- **Keep Test Data Local:** Keep data inside the test unless reused many times
- **Descriptive Names:** Use variables that explain their role in the scenario
- **No Production Fixtures:** Do not depend on production seed data

Checklist:
- [ ] Test data is simple
- [ ] Test data is deterministic
- [ ] Complex objects use test builders if needed
- [ ] Data is readable
- [ ] No random values are used
- [ ] No production seed data is required
