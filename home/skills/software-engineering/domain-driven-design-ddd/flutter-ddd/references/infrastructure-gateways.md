# Infrastructure Gateways

Location: `[context-name]/infrastructure/api/gateways/`

Gateways encapsulate real HTTP communication with backend APIs.

- **Interface + Implementation:** Define gateway contract and HTTP implementation.
- **Naming Convention:** Contracts end with `Gateway`; implementations can end with `HttpGateway`.
- **Flutter Integration:** Implementations use `Dio`, exposed as a `@riverpod` provider (codegen), not a manually registered singleton.
- **Swagger/OpenAPI Driven:** Endpoints and payloads follow backend spec.
- **Aggregate Focus:** One gateway per aggregate/use-case boundary.

-  Gateway contracts exist and are isolated
-  Implementations use Dio and real endpoints
-  Uses Riverpod codegen for dependency injection
-  Includes query methods needed by use cases
-  Follows naming conventions
-  One gateway per aggregate boundary
