# Mutation Operators

Mutation operators simulate common programming defects.

## Relational Operator Mutation

Change relational expressions such as:

```text
>  to >=
>= to >
<  to <=
<= to <
== to !=
!= to ==
```

These mutations are useful for identifying missing boundary-value tests.

## Conditional Operator Mutation

Modify logical conditions such as:

```text
AND to OR
OR to AND
condition to NOT condition
```

These mutations identify incomplete testing of decision logic.

## Arithmetic Operator Mutation

Modify arithmetic expressions such as:

```text
+ to -
- to +
* to /
/ to *
```

These mutations are useful for calculations, prices, balances, limits, scores, and other numerical behavior.

## Return Value Mutation

Modify returned values, for example:

```text
true to false
false to true
object to null
number to zero
collection to empty collection
```

These mutations are especially useful for detecting weak assertions.

## Statement or Call Removal

Remove a meaningful operation or method call.

This mutation is useful when tests are expected to verify:

* State changes
* Side effects
* Persistence operations
* Events
* External interactions
* Important method invocations

Mutation operators should only be enabled when they represent meaningful defects for the code being tested.
