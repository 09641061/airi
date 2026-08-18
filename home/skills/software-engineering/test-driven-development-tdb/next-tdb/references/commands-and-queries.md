# Command and Query Tests

Commands represent state-changing intentions, while queries represent read requests.

Test commands for:

- Valid creation
- Required fields
- Invalid identifiers, strings, numbers, and dates
- Business rule validation
- Immutability where applicable

Test queries for:

- Valid criteria
- Optional filters
- Pagination limits
- Invalid identifiers or search terms
- Empty and non-empty results
- Read-only behavior
