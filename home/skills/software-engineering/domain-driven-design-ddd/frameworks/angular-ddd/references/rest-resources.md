# REST Resources (Frontend Contracts)

Location: `[context-name]/interfaces/rest/resources/`

Resources define request/response contracts used by frontend boundaries.

- **Naming Convention:** Files end with `Resource` (e.g., `.resource.ts`).
- **No DTO Classes:** Use immutable `type`/`interface` only.
- **API Focused:** Designed for transport and contract boundaries.
- **Validation:** Compatible with reactive forms and UI constraints.
- **Swagger/OpenAPI:** Fields and types aligned with documented backend contract.

- [ ] File names end with `Resource`
- [ ] `type`/`interface` used for immutability
- [ ] Validation constraints represented
- [ ] Swagger/OpenAPI alignment verified
- [ ] Descriptive and clear field names
