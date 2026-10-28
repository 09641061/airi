# Presentation Components and Forms

Location: `[context-name]/presentation/components/`

Presentational components (*Dumb Components*) and form components are responsible exclusively for UI rendering and capturing user interactions.

- **Naming Convention:** Files end with `.component.ts`. Exported classes end with `Component`.
- **Signal Inputs & Outputs:** Use modern signal-based APIs:
  - `input<T>()` / `input.required<T>()` for incoming data.
  - `output<T>()` for emitting user intent and events.
  - Prohibit legacy `@Input()` and `@Output()` decorators in new code.
- **Purely Presentational:** Components do not inject application stores, gateways, or `Router`. They receive state via inputs and notify actions via outputs.
- **Decoupled Forms:**
  - Form components encapsulate form groups, controls, and validation UX.
  - On submit, validate the form and emit an explicit domain Command via `output()`.
  - Do not trigger HTTP calls or navigation directly inside the form component.
- **No Class Inheritance Anti-patterns:** Do not create `BaseForm` classes with inherited validation helpers. Use composable validation utilities or custom form components.
- **Zoneless Ready:** Never mutate objects in place; ensure all state updates flow through signals or immutable assignments.

```typescript
// Example: [context-name]/presentation/components/course-form/course-form.component.ts
import { Component, input, output, inject, OnInit } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { CreateCourseCommand } from '../../../domain/model/commands/create-course.command';
import { parseCategoryId } from '../../../domain/model/valueobjects/category-id.value-object';

@Component({
  selector: 'app-course-form',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './course-form.component.html',
  styleUrl: './course-form.component.css'
})
export class CourseFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);

  // Inputs & Outputs
  readonly initialData = input<{ title?: string; description?: string; categoryId?: number } | null>(null);
  readonly isSubmitting = input<boolean>(false);
  readonly submitCommand = output<CreateCourseCommand>();

  readonly form = this.fb.group({
    title: ['', [Validators.required, Validators.minLength(3)]],
    description: ['', [Validators.required]],
    categoryId: [null as number | null, [Validators.required]]
  });

  ngOnInit(): void {
    const data = this.initialData();
    if (data) {
      this.form.patchValue(data);
    }
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const val = this.form.getRawValue();
    this.submitCommand.emit({
      title: val.title!,
      description: val.description!,
      categoryId: parseCategoryId(val.categoryId!)
    });
  }
}
```

### Checklist
- [ ] Located in `[context-name]/presentation/components/`
- [ ] Uses `input()` and `output()` exclusively
- [ ] No direct gateway, store, or router injection in dumb components
- [ ] Forms emit explicit command payloads on submit
- [ ] No `BaseForm` OOP inheritance
- [ ] Compatible with zoneless change detection
