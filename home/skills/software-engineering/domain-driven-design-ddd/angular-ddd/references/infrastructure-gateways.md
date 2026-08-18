# Infrastructure Gateways

Location: `[context-name]/infrastructure/api/gateways/`

Gateways encapsulate real HTTP communication with backend APIs.

- **Interface + Implementation:** Define gateway contract and HTTP implementation.
- **Naming Convention:** Contracts end with `Gateway`; implementations can end with `HttpGateway`.
- **Angular Integration:** Implementations use `@Injectable` and `HttpClient`, injected via `inject(HttpClient)` rather than constructor parameters.
- **Swagger/OpenAPI Driven:** Endpoints and payloads follow backend spec.
- **Aggregate Focus:** One gateway per aggregate/use-case boundary.
- **Signals at the Edge:** Gateways may expose read methods via `httpResource()`/`resource()` for simple GET-driven reads when a raw `Observable` isn't needed downstream; keep `Observable` returns for anything chained/combined with RxJS operators.

- [ ] Gateway contracts exist and are isolated
- [ ] Implementations use `HttpClient` and real endpoints
- [ ] Uses `@Injectable` with `inject()` for dependencies
- [ ] Includes query methods needed by use cases
- [ ] Follows naming conventions
- [ ] One gateway per aggregate boundary
