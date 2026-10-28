# Infrastructure Gateways

Location: `[context-name]/infrastructure/gateways/`

Gateways encapsulate HTTP communication with external backend APIs. They are the communication boundaries between the Angular application and the remote system.

- **Gateways, Not Repositories:** In frontend architecture, the remote backend is an external system, not an internal database. The Gateway pattern accurately models this boundary. Repositories (simulating in-memory collections of aggregates with `save()`/`delete()`) are an antipattern for frontend HTTP clients.
- **Direct Injectable Services:** Gateways are concrete `@Injectable({ providedIn: 'root' })` services. Do not create separate interface + `HttpGatewayImpl` classes unless multi-backend polymorphism is strictly required.
- **Angular Integration:** Injected via `inject(HttpClient)` rather than constructor parameters.
- **Contract Driven:** Request and response payloads use typed contracts from `infrastructure/contracts/` aligned with Swagger/OpenAPI.
- **Observables & Signals:** Gateways return `Observable<T>` for operations that require pipeline transformation or cancellation, or use `httpResource()` for declarative read resources.
- **No In-Memory State:** Gateways are stateless; they do not hold or manage UI state.

```typescript
// Example: [context-name]/infrastructure/gateways/courses.gateway.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { CourseResource, CreateCourseRequest } from '../contracts/course.contract';
import { environment } from '../../../../environments/environment';

@Injectable({ providedIn: 'root' })
export class CoursesGateway {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiBaseUrl}/courses`;

  getAll(): Observable<CourseResource[]> {
    return this.http.get<CourseResource[]>(this.baseUrl);
  }

  getById(id: number): Observable<CourseResource> {
    return this.http.get<CourseResource>(`${this.baseUrl}/${id}`);
  }

  create(payload: CreateCourseRequest): Observable<CourseResource> {
    return this.http.post<CourseResource>(this.baseUrl, payload);
  }

  update(id: number, payload: Partial<CreateCourseRequest>): Observable<CourseResource> {
    return this.http.put<CourseResource>(`${this.baseUrl}/${id}`, payload);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
```

### Checklist
- [ ] Named with `Gateway` suffix (e.g., `CoursesGateway`)
- [ ] No repository abstractions; uses real endpoints and HTTP methods
- [ ] Uses `@Injectable({ providedIn: 'root' })` and `inject()`
- [ ] Consumes OpenAPI contracts from `infrastructure/contracts/`
- [ ] Stateless: does not store collections or UI state internally
