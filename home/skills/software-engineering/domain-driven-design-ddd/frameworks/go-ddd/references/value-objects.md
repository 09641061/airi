# Value Objects

## 1. Value Objects Implementation

**Location:** `[context-name]/domain/model/valueobjects/`

Value Objects represent domain values and enforce their own rules.

- **Use structs or defined types**, not Java records.
- **Validate with constructors** such as `New[ValueObject](...) (ValueObject, error)`.
- **Keep values immutable by design**: private fields, no setters, defensive copies for slices/maps.
- **Do not add database tags** or persistence logic to Value Objects.
- **Use typed constants** for fixed domain values when appropriate.

- [ ] Value Objects use structs or defined types.
- [ ] Constructor validates required values and domain rules.
- [ ] Internal state cannot be changed unexpectedly.
- [ ] No Gin, Koanf, SQL, or persistence imports.
- [ ] Typed constants used where appropriate.

**IMPORTANT:** If a shared kernel provides audit types, reuse it **only when it makes domain sense**. Go does not need a Java-style base aggregate class.

---
