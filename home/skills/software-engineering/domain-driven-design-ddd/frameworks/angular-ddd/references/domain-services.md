# Domain Services

Location: `[context-name]/domain/services/`

Domain services encapsulate domain logic, business calculations, or multi-entity validations that do not naturally belong to a single Entity or Value Object.

- **Pure Business Logic:** Free of Angular framework references (`@Injectable`, `HttpClient`, signals, etc.) and HTTP/persistence concerns.
- **Pure Functions or Stateless Classes:** Can be implemented as pure functions or stateless domain classes.
- **Not for Use Case Orchestration:** Command and query orchestration belongs to **Application Services / Stores**, not domain services.
- **No Ghost Interfaces:** Do not create dummy TypeScript interfaces for services unless there is actual runtime polymorphism.

```typescript
// Example: [context-name]/domain/services/course-pricing.calculator.ts
import { Course } from '../model/course.entity';

export const calculateDiscountedPrice = (course: Course, discountPercentage: number): number => {
  if (discountPercentage < 0 || discountPercentage > 100) {
    throw new Error('Discount percentage must be between 0 and 100');
  }
  return course.price * (1 - discountPercentage / 100);
};
```

### Checklist
- [ ] Logic belongs to the domain, not application or UI orchestration
- [ ] No framework or HTTP dependencies (`@Injectable`, `HttpClient`, router)
- [ ] Functions are pure or classes are stateless
- [ ] Input and output types belong strictly to the domain model
