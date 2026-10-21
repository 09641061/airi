# REST Resources and Controllers

## 9. REST Resources (DTOs)

**Location:** `[context-name]/interfaces/rest/resources/`

REST Resources define **what the API receives and returns**.

- **Naming:** `[Action][Entity]Request` and `[Entity]Response`, or the team's `Resource` convention.
- **Use Go structs** with `json` tags.
- **Gin validation:** `binding` tags belong here, never in domain types.
- **OpenAPI:** document request fields, responses, validation errors, and status codes.

Generic DTO pattern:

```go
type CreateEntityRequest struct {
    Field string `json:"field" binding:"required"`
}

type EntityResponse struct {
    ID int64 `json:"id"`
}
```

- [ ] Request/Response/Resource naming consistent.
- [ ] DTOs contain transport data, not domain behavior.
- [ ] Required fields validated.
- [ ] OpenAPI describes success and error responses.
- [ ] DTOs are not reused as persistence models.

---

## 10. REST Controllers

**Location:** `[context-name]/interfaces/rest/controllers/`

Controllers handle **HTTP only** and delegate work to application services.

- **Naming:** `[Entity]Controller` (or `Handler`, consistently).
- **Gin routes:** register endpoints with `gin.RouterGroup`.
- **Validation:** use `ShouldBindJSON`, `ShouldBindQuery`, etc.
- **Mapping:** Request → Command/Query → application service → Response.
- **Errors:** convert application errors to appropriate HTTP status codes.
- **OpenAPI:** document operations, request/response types, and errors.

Generic controller flow:

```go
func (h *EntityController) Create(c *gin.Context) {
    var req CreateEntityRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
        return
    }

    // Convert req to a Command and call the use case with c.Request.Context().
    // Map the result and typed errors to the documented HTTP responses.
}
```

- [ ] Controller/Handler naming consistent.
- [ ] Routes registered using Gin (no Spring annotations).
- [ ] Input validated at HTTP boundary.
- [ ] Request transformed into Command/Query.
- [ ] Application result transformed into Response.
- [ ] Correct HTTP status codes and OpenAPI documentation.
- [ ] No business logic in controllers.

---
