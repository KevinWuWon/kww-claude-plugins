# Convex Validators Reference

Complete reference for Convex value validators used in function arguments and schemas.

## Validator Table

| Convex Type | TypeScript Type | Example Usage | Validator | Notes |
|-------------|-----------------|---------------|-----------|-------|
| Id | string | `doc._id` | `v.id(tableName)` | Document identifier |
| Null | null | `null` | `v.null()` | Use instead of `undefined` |
| Int64 | bigint | `3n` | `v.int64()` | -2^63 to 2^63-1 |
| Float64 | number | `3.1` | `v.number()` | IEEE-754 double |
| Boolean | boolean | `true` | `v.boolean()` | |
| String | string | `"abc"` | `v.string()` | UTF-8, <1MB |
| Bytes | ArrayBuffer | `new ArrayBuffer(8)` | `v.bytes()` | <1MB |
| Array | Array | `[1, 3.2, "abc"]` | `v.array(values)` | Max 8192 elements |
| Object | Object | `{a: "abc"}` | `v.object({property: value})` | Max 1024 entries |
| Record | Record | `{"a": "1"}` | `v.record(keys, values)` | Dynamic keys |

## Important Notes

- `v.bigint()` is **deprecated** - use `v.int64()` instead
- `v.map()` and `v.set()` are **not supported** - use `v.record()` for maps
- `undefined` is not a valid Convex value - use `null` instead
- Object field names must not start with `$` or `_`
- Object field names must be ASCII characters

## Common Patterns

### Optional Fields

```ts
v.optional(v.string())  // string | undefined
```

### Union Types

```ts
v.union(v.string(), v.number())  // string | number
```

### Literal Values

```ts
v.literal("active")  // exactly "active"
v.literal(42)        // exactly 42
```

### Discriminated Unions

```ts
v.union(
  v.object({
    kind: v.literal("error"),
    errorMessage: v.string(),
  }),
  v.object({
    kind: v.literal("success"),
    value: v.number(),
  }),
)
```

### Array Validators

```ts
v.array(v.string())                        // string[]
v.array(v.union(v.string(), v.number()))   // (string | number)[]
v.array(v.id("users"))                     // Id<"users">[]
```

### Object Validators

```ts
v.object({
  name: v.string(),
  age: v.number(),
  email: v.optional(v.string()),
})
```

### Record Validators

```ts
v.record(v.string(), v.number())           // Record<string, number>
v.record(v.id("users"), v.string())        // Record<Id<"users">, string>
```

## Type Safety with TypeScript

### Using Id Types

```ts
import { Id } from "./_generated/dataModel";

// Strict typing for document IDs
function getUser(userId: Id<"users">) {
  // ...
}

// Record with Id keys
const idToUsername: Record<Id<"users">, string> = {};
```

### Using Doc Types

```ts
import { Doc } from "./_generated/dataModel";

function processUser(user: Doc<"users">) {
  console.log(user._id, user.name);
}
```

## Best Practices

1. **Always use validators** - Include argument validators for all functions
2. **Use strict ID types** - Prefer `v.id("tableName")` over `v.string()` for IDs
3. **Use `as const`** - For string literals in discriminated unions
4. **Validate at boundaries** - Validate all external input

## Deprecated

- `v.bigint()` - Use `v.int64()` instead
- `v.any()` - Avoid using, prefer explicit types
