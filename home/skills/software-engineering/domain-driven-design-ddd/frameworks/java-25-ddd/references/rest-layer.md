# REST Inbound Adapter

Location: `[context-name]/interfaces/rest/`

The REST layer is an HTTP boundary. In this repository convention it lives in `[context-name]/interfaces/rest/`; `adapters/inbound/rest/` is an equivalent name if adopted consistently.

```text
interfaces/rest/
  controllers/CoursesController.java
  resources/CreateCourseResource.java
  resources/CourseResource.java
  transform/CourseResourceAssembler.java
```

## Resources

Request and response resources are transport contracts, not domain objects. Use records when suitable, apply Bean Validation to incoming HTTP data, and document the real response/status contract with OpenAPI. HTTP validation does not replace the domain invariants.

```java
public record CreateCourseResource(
        @NotBlank String name,
        @NotNull @Positive Long categoryId,
        @Size(max = 500) String description) {
}
```

## Controllers

Controllers handle routing, HTTP-specific input, invocation of an application use case, and translation to the established HTTP response. They must not depend on JPA repositories or implement business rules.

```java
@RestController
@RequestMapping("/api/v1/courses")
public class CoursesController {
    private final CourseUseCases courseUseCases;

    public CoursesController(CourseUseCases courseUseCases) {
        this.courseUseCases = courseUseCases;
    }

    @PostMapping
    public ResponseEntity<CourseResource> create(@Valid @RequestBody CreateCourseResource resource) {
        var result = courseUseCases.create(new CreateCourseCommand(
                resource.name(), resource.categoryId(), resource.description()));
        return ResponseEntity.created(URI.create("/api/v1/courses/" + result.id()))
                .body(CourseResourceAssembler.toResource(result));
    }
}
```

Map the transport request to an application command and the application result to the response resource.

## Error translation

HTTP status selection and error-resource construction live at the REST boundary. Return stable, client-safe messages for unexpected failures, and keep SQL, persistence, and stack traces in server-side logs. Never expose secrets or framework details.

## Checklist

- [ ] The controller depends on application use cases, not on infrastructure repositories
- [ ] Validation is actually enforced at runtime (`@Valid` plus constraints), not only described in OpenAPI
- [ ] Domain invariants are independently enforced by the domain model
- [ ] Response payloads and statuses match the established HTTP contract
- [ ] Unexpected error responses do not disclose framework or database details
- [ ] REST tests cover validation, authorization, status, and serialization behavior
