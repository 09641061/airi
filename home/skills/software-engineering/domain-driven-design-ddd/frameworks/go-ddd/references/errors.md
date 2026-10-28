# Error Model

Go models failure as a value that travels up the call stack. Business meaning survives only if the error is modeled deliberately.

- **Sentinel errors** for a closed set of business outcomes: `var ErrEnrollmentClosed = errors.New("enrollment is closed")`. They live in the package that owns the concept.
- **Typed errors** when the caller needs structured data from the failure (`type ValidationError struct{ Field string; Reason string }` with an `Error() string` method).
- **Wrapping** adds context while preserving the cause: `fmt.Errorf("enroll student %s: %w", studentID, err)`.
- **Matching** uses `errors.Is(err, ErrEnrollmentClosed)` and `errors.As(err, &validationErr)` — never string comparison and never `err == someError` on a wrapped value.
- **Absence** is a nil value plus an explicit sentinel (`ErrCourseNotFound`), never a zero value, an empty string, or a negative number.
- **Translation** happens once, at the HTTP boundary, where `errors.Is` decides the status code; internal messages never reach the client.

```go
// internal/[context-name]/domain/course.go
package courses

import "errors"

var ErrCourseNotFound = errors.New("course not found")

// The adapter wraps the driver error and keeps the cause reachable.
func (r *PostgresCourseRepository) FindByID(ctx context.Context, id domain.CourseID) (*domain.Course, error) {
	row, err := r.db.QueryRowContext(ctx, findCourseSQL, string(id)).Scan(...)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("find course %s: %w", id, domain.ErrCourseNotFound)
	}
	if err != nil {
		return nil, fmt.Errorf("find course %s: %w", id, err)
	}
	return domain.NewCourse(...)
}
```

## Checklist

- [ ] Business failures are sentinel or typed errors, not formatted strings compared by text.
- [ ] Wrapped errors keep the cause reachable through `errors.Is`/`errors.As`.
- [ ] Absence and business rejection are distinguishable.
- [ ] Adapters translate storage-driver errors into the port's contract.
- [ ] HTTP status selection happens at the transport boundary, and internal details are not leaked.
