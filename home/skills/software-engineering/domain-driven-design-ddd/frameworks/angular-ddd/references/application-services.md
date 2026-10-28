# Application Services & Signal Stores

Location: `[context-name]/application/`

Application services (or Signal Stores) orchestrate business use cases, coordinate infrastructure gateways, and manage reactive client state for presentation consumers.

- **Modular by Aggregate/Feature:** Create focused stores per aggregate (e.g., `courses.store.ts`, `categories.store.ts`) rather than monolithic kitchen-sink stores.
- **Signals-First State:** Expose UI state as readonly signals (`asReadonly()`, `computed()`). Keep private writable signals (`coursesSignal`) internal.
- **Concrete Services:** Define concrete `@Injectable({ providedIn: 'root' })` classes using `inject()`. Do not create ghost interfaces or `*Impl` suffixes unless real runtime polymorphism is required.
- **Predictable Async Operations:** Command methods must return a `Promise<T>` or `Observable<T>` so that calling pages can await completion before triggering side effects (e.g., navigation).
- **Explicit States:** Manage `loading` and `error` states deterministically. Never mutate state objects directly; use immutable signal updates.

```typescript
// Example: [context-name]/application/courses.store.ts
import { Injectable, inject, signal, computed } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { CoursesGateway } from '../infrastructure/gateways/courses.gateway';
import { CourseResource } from '../infrastructure/contracts/course.contract';
import { CreateCourseCommand } from '../domain/model/commands/create-course.command';

@Injectable({ providedIn: 'root' })
export class CoursesStore {
  private readonly gateway = inject(CoursesGateway);

  // Private state signals
  private readonly coursesSignal = signal<CourseResource[]>([]);
  private readonly loadingSignal = signal<boolean>(false);
  private readonly errorSignal = signal<string | null>(null);

  // Public readonly views
  readonly courses = this.coursesSignal.asReadonly();
  readonly isLoading = this.loadingSignal.asReadonly();
  readonly error = this.errorSignal.asReadonly();
  readonly totalCourses = computed(() => this.courses().length);

  async loadAll(): Promise<void> {
    this.loadingSignal.set(true);
    this.errorSignal.set(null);
    try {
      const data = await firstValueFrom(this.gateway.getAll());
      this.coursesSignal.set(data);
    } catch (err: any) {
      this.errorSignal.set(err.message || 'Failed to load courses');
    } finally {
      this.loadingSignal.set(false);
    }
  }

  async addCourse(command: CreateCourseCommand): Promise<CourseResource> {
    this.loadingSignal.set(true);
    this.errorSignal.set(null);
    try {
      const created = await firstValueFrom(this.gateway.create(command));
      this.coursesSignal.update(list => [...list, created]);
      return created;
    } catch (err: any) {
      this.errorSignal.set(err.message || 'Failed to create course');
      throw err;
    } finally {
      this.loadingSignal.set(false);
    }
  }

  async removeCourse(id: number): Promise<void> {
    this.loadingSignal.set(true);
    try {
      await firstValueFrom(this.gateway.delete(id));
      this.coursesSignal.update(list => list.filter(c => c.id !== id));
    } catch (err: any) {
      this.errorSignal.set(err.message || 'Failed to delete course');
      throw err;
    } finally {
      this.loadingSignal.set(false);
    }
  }
}
```

### Checklist
- [ ] Stored in `[context-name]/application/`
- [ ] Focused per aggregate or cohesive feature
- [ ] State exposed via readonly signals (`asReadonly()`, `computed()`)
- [ ] No `*Impl` naming; concrete `@Injectable` classes
- [ ] Async methods return a Promise or Observable to allow caller awaiting
- [ ] Immutable state updates (`signal.update()`)
- [ ] `loading` and `error` states tracked explicitly
