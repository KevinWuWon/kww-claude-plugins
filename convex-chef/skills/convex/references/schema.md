# Convex Schema Design Reference

Comprehensive guide to designing Convex schemas with proper indexes.

## Basic Schema

```ts
// convex/schema.ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    name: v.string(),
    email: v.string(),
  }),

  messages: defineTable({
    authorId: v.id("users"),
    content: v.string(),
  }),
});
```

## System Fields

Every document automatically has:

| Field | Type | Description |
|-------|------|-------------|
| `_id` | `Id<"tableName">` | Unique document identifier |
| `_creationTime` | `number` | Unix timestamp (ms) when created |

These are managed by Convex and cannot be set manually.

## Index Design

### Basic Index

```ts
messages: defineTable({
  channelId: v.id("channels"),
  content: v.string(),
}).index("by_channel", ["channelId"])
```

### Multi-Field Index

```ts
messages: defineTable({
  channelId: v.id("channels"),
  authorId: v.id("users"),
  content: v.string(),
}).index("by_channel_and_author", ["channelId", "authorId"])
```

### Index Naming Rules

1. **Include all fields in name**: `by_field1_and_field2` for `["field1", "field2"]`
2. **Use `by_` prefix**: Convention for clarity

### Critical Index Rules

1. **Never add `_creationTime` to indexes** - It's automatically appended
   ```ts
   // WRONG
   .index("by_channel_and_time", ["channelId", "_creationTime"])

   // CORRECT
   .index("by_channel", ["channelId"])  // _creationTime appended automatically
   ```

2. **Query fields in order** - Must match index field order
   ```ts
   // Index: ["channelId", "authorId"]

   // CORRECT - fields in order
   .withIndex("by_channel_and_author", (q) =>
     q.eq("channelId", channelId).eq("authorId", authorId)
   )

   // WRONG - skipping channelId
   .withIndex("by_channel_and_author", (q) =>
     q.eq("authorId", authorId)
   )
   ```

3. **Create separate indexes for different query patterns**
   ```ts
   // Need to query by channel OR by author
   .index("by_channel", ["channelId"])
   .index("by_author", ["authorId"])
   ```

### Built-in Indexes

These exist automatically, never define them:

| Index Name | Fields | Usage |
|------------|--------|-------|
| `by_id` | `["_id"]` | `ctx.db.get(id)` |
| `by_creation_time` | `["_creationTime"]` | Default ordering |

```ts
// Using built-in by_creation_time
const recent = await ctx.db
  .query("messages")
  .withIndex("by_creation_time")
  .order("desc")
  .take(10);
```

## Search Indexes

For full-text search:

```ts
messages: defineTable({
  body: v.string(),
  channel: v.string(),
}).searchIndex("search_body", {
  searchField: "body",
  filterFields: ["channel"],
})
```

### Using Search

```ts
const results = await ctx.db
  .query("messages")
  .withSearchIndex("search_body", (q) =>
    q.search("body", "hello world").eq("channel", "#general")
  )
  .take(10);
```

## TypeScript Integration

### Id Types

```ts
import { Id } from "./_generated/dataModel";

// Strict typing for IDs
type UserId = Id<"users">;
type MessageId = Id<"messages">;

function getUser(userId: Id<"users">) {
  // Type-safe
}
```

### Doc Types

```ts
import { Doc } from "./_generated/dataModel";

// Full document type including system fields
type User = Doc<"users">;
// Equivalent to: { _id: Id<"users">, _creationTime: number, name: string, email: string }
```

### Record Types with Ids

```ts
// Map from user ID to username
const idToName: Record<Id<"users">, string> = {};

// With validator
v.record(v.id("users"), v.string())
```

## Schema with Auth Tables

When using @convex-dev/auth:

```ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";
import { authTables } from "@convex-dev/auth/server";

const applicationTables = {
  messages: defineTable({
    authorId: v.id("users"),
    content: v.string(),
  }).index("by_author", ["authorId"]),
};

export default defineSchema({
  ...authTables,
  ...applicationTables,
});
```

The `authTables` includes:

```ts
users: defineTable({
  name: v.optional(v.string()),
  image: v.optional(v.string()),
  email: v.optional(v.string()),
  emailVerificationTime: v.optional(v.number()),
  phone: v.optional(v.string()),
  phoneVerificationTime: v.optional(v.number()),
  isAnonymous: v.optional(v.boolean()),
})
  .index("email", ["email"])
  .index("phone", ["phone"])
```

## Best Practices

### Do

- Define indexes for all query patterns
- Use descriptive index names with `by_` prefix
- Include all queried fields in index name
- Use `v.id("tableName")` for foreign keys
- Use `v.optional()` for nullable fields

### Don't

- Add `_creationTime` to indexes (automatic)
- Define `by_id` or `by_creation_time` indexes (built-in)
- Use `.filter()` for queries (use indexes)
- Skip index fields when querying
- Store URLs for files (store storage IDs instead)

## Common Patterns

### Soft Delete

```ts
items: defineTable({
  name: v.string(),
  deletedAt: v.optional(v.number()),
}).index("by_active", ["deletedAt"])

// Query active items
.withIndex("by_active", (q) => q.eq("deletedAt", undefined))
```

### Status Enum

```ts
tasks: defineTable({
  title: v.string(),
  status: v.union(
    v.literal("pending"),
    v.literal("active"),
    v.literal("completed")
  ),
}).index("by_status", ["status"])
```

### Many-to-Many

```ts
// Junction table
userChannels: defineTable({
  userId: v.id("users"),
  channelId: v.id("channels"),
})
  .index("by_user", ["userId"])
  .index("by_channel", ["channelId"])
  .index("by_user_and_channel", ["userId", "channelId"])
```
