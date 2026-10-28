# REST Resources and Gin Controllers

Gin is the HTTP adapter. Keep public HTTP shapes and transport concerns at the transport boundary, separate from domain models and application contracts. The inbound boundary is `transport/http/`, not `interfaces/`: Go calls it *transport*, and a directory named after a layer type groups code by kind rather than by feature.

## REST resources (DTOs)

Location: `[context-name]/transport/http/resources/`

- Define request/response structs with `json` and, where appropriate, Gin binding tags in this boundary layer.
- Keep transport/input validation distinct from domain invariants. Binding validation cannot replace domain checks.
- Map explicitly between HTTP resources, application contracts, and results. Avoid reflection-based generic mappers unless a concrete need justifies one.
- Describe required/optional fields and success/error schemas in OpenAPI 3.1; keep public contracts stable as the domain evolves.

**Checklist**

- [ ] HTTP DTOs remain in the REST boundary.
- [ ] No HTTP tags pollute domain types.
- [ ] Public API contracts remain stable despite domain refactoring.
- [ ] OpenAPI describes validation and error responses accurately.

## Controllers

Location: `[context-name]/transport/http/handlers/`

- Import Gin only in HTTP controllers (and applicable HTTP middleware/bootstrap).
- Bind and validate a request, create a Command or Query, invoke an application use case with `c.Request.Context()`, then map the result explicitly.
- Keep handlers small: no domain invariants, persistence access, or cross-context orchestration.
- Translate typed/application errors to the documented HTTP status and response with `errors.Is`/`errors.As`, without leaking sensitive internal details.
- Register routes at startup and document relevant success, validation, authorization, conflict, absence, and server-error responses in OpenAPI.

```go
func (h *Handler) CreateCourse(c *gin.Context) {
    var req resources.CreateCourseRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        writeError(c, http.StatusBadRequest, err)
        return
    }
    result, err := h.useCases.Create(c.Request.Context(), application.CreateCourseCommand{
        Name: req.Name,
    })
    if err != nil {
        writeError(c, http.StatusInternalServerError, err)
        return
    }
    c.JSON(http.StatusCreated, resources.CourseResource{ID: result.ID, Name: result.Name})
}
```

## HTTP tests and review

Use Gin with `net/http/httptest` to verify request parsing, validation, status/error translation, and cancellation propagation. Cover applicable success, invalid input, absence, conflict, and server-error paths. Do not require a real network server for controller contract tests.

**Checklist**

- [ ] Gin imports are restricted to the HTTP boundary.
- [ ] Controller delegates application work.
- [ ] Request and response mapping is explicit.
- [ ] HTTP errors and status codes follow published contracts.
- [ ] `httptest` covers success, validation, absence, conflict, and server error paths where applicable.
