# Presentation Pages (Smart Routed Orchestrators)

Location: `[context-name]/presentation/pages/`

Pages are routed container components (*Smart Components*) that coordinate application state, route parameters, and presentation events.

- **Naming Convention:** Files end with `.page.ts` (e.g., `course-list.page.ts`, `course-detail.page.ts`). Exported component classes end with `Page` (e.g., `CourseListPage`).
- **Standalone & Lazy Loaded:** Standalone by default. Connected directly in routes using `loadComponent: () => import('./pages/...').then(m => m.XPage)`.
- **Route Input Binding:** Use Angular's `input()` with `withComponentInputBinding()` for route params and query params instead of subscribing to `ActivatedRoute.params` in the constructor.
- **State Orchestration:** Inject application stores/services with `inject()`. Bind store signals directly to template control flow blocks (`@if`, `@for`).
- **Awaited Navigation:** Never execute `router.navigate()` optimistically before an asynchronous mutation resolves. Await the store/service operation and handle errors before navigating.
- **No Direct HTTP:** Pages never inject `HttpClient` or gateways directly; all operations go through `application/`.

```typescript
// Example: [context-name]/presentation/pages/course-list/course-list.page.ts
import { Component, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { CoursesStore } from '../../../application/courses.store';
import { CourseCardComponent } from '../../components/course-card/course-card.component';

@Component({
  selector: 'app-course-list-page',
  standalone: true,
  imports: [CourseCardComponent],
  templateUrl: './course-list.page.html',
  styleUrl: './course-list.page.css'
})
export class CourseListPage implements OnInit {
  protected readonly store = inject(CoursesStore);
  private readonly router = inject(Router);

  ngOnInit(): void {
    this.store.loadAll();
  }

  onCreateNew(): void {
    this.router.navigate(['/courses/new']);
  }

  async onDeleteCourse(id: number): Promise<void> {
    try {
      await this.store.removeCourse(id);
    } catch {
      // Error message is already tracked in store.error()
    }
  }
}
```

### Checklist
- [ ] File named `*.page.ts` and class named `*Page`
- [ ] Located in `[context-name]/presentation/pages/`
- [ ] Routed via `loadComponent`
- [ ] Injects application services/stores, never gateways or `HttpClient`
- [ ] Uses signals for reactive UI state
- [ ] Awaits async operations before navigating
- [ ] Uses modern control flow (`@if`, `@for`, `@switch`) in templates
