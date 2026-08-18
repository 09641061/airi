# REST Layer (Resources + Controllers)

## REST Resources (DTOs)

Location: `[context-name]/interfaces/rest/resources/`

Resources define API contracts and must stay separate from domain internals.

- **Naming Convention**: Files end with `Request`/`Response` or `Resource` based on team standard
- **DTO Pattern**: Pure transport classes/records
- **API Focused**: Designed for external communication
- **Validation**: Add bean validation annotations
- **Documentation**: Add OpenAPI annotations

Checklist:
- [ ] Naming is consistent (`*Request`, `*Response`, or `*Resource`)
- [ ] Records used when appropriate
- [ ] Validation annotations applied
- [ ] OpenAPI documentation included
- [ ] No domain behavior in DTOs

## REST Controllers

Location: `[context-name]/interfaces/rest/controllers/`

Controllers process HTTP concerns and delegate business work.

- **Naming Convention**: Files end with `Controller`
- **REST Annotations**: Use Spring REST annotations
- **OpenAPI Documentation**: Add tags, operations, responses
- **Response Codes**: Correct status semantics
- **Transformation**: Convert request DTOs to commands/queries and domain results to response DTOs

Checklist:
- [ ] File names end with `Controller`
- [ ] `@RestController` annotation
- [ ] `@RequestMapping` for base path
- [ ] OpenAPI annotations (`@Tag`, `@Operation`, `@ApiResponses`)
- [ ] Proper HTTP status codes
- [ ] Input validation with `@Valid`
- [ ] Request-to-command/query transformation
- [ ] Domain-to-response transformation
