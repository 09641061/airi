# Command & Query Unit Tests

## Commands. Location: `[context-name]/domain/model/commands/`

Commands represent intentions to change state. Unit tests must verify that commands accept valid input and reject invalid input.

- **Valid Command:** Test command creation with valid data
- **Required Fields:** Test null or missing required fields
- **Invalid IDs:** Test zero, negative, or malformed identifiers
- **Invalid Text:** Test blank names, descriptions, titles, or codes
- **Invalid Numbers:** Test negative prices, quantities, limits, or thresholds
- **Invalid Dates:** Test past dates, invalid ranges, or inconsistent time windows
- **Immutability:** Commands should remain immutable by design

Checklist:
- [ ] Valid command creation is tested
- [ ] Required fields are tested
- [ ] Invalid identifiers are tested
- [ ] Invalid strings are tested
- [ ] Invalid numbers are tested
- [ ] Invalid dates or ranges are tested
- [ ] Command validation exceptions are verified

## Queries. Location: `[context-name]/domain/model/queries/`

Queries represent read requests. Unit tests must verify that query criteria are valid and safe before being handled.

- **Valid Query:** Test query creation with valid criteria
- **Invalid IDs:** Test null, zero, negative, or malformed IDs
- **Optional Parameters:** Test optional filters when allowed
- **Pagination:** Test page number, page size, and limits when applicable
- **Search Criteria:** Test invalid blank search terms if not allowed
- **Read-Only Intent:** Queries should not include state-changing data

Checklist:
- [ ] Valid query creation is tested
- [ ] Invalid identifiers are tested
- [ ] Optional parameters are handled correctly
- [ ] Pagination rules are tested
- [ ] Search criteria validation is tested
- [ ] Query does not represent a state-changing action
