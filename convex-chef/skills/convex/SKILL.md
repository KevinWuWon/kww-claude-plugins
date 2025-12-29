---
name: Convex Development
description: This skill should be used when the user asks to "write Convex code", "create a Convex function", "design a Convex schema", "add a query", "add a mutation", "add an action", "create a cron job", "implement file storage", or is working with files in the convex/ directory. Provides comprehensive Convex backend development guidelines and best practices.
---

# Convex Backend Development Guidelines

Convex is a reactive database with real-time updates. These guidelines ensure correct, performant Convex applications.

## Core Principles

1. **Convex is realtime by default** - Never manually refresh subscriptions
2. **Always use validators** - Include argument validators for all functions
3. **Never use .filter()** - Use indexes with `.withIndex()` instead
4. **Actions don't have ctx.db** - Actions cannot access the database directly
5. **Use typed IDs** - Use `Id<'tableName'>` instead of generic strings

## Function Syntax

Always use the new function syntax for Convex functions:

```ts
import { query } from "./_generated/server";
import { v } from "convex/values";

export const myQuery = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.userId);
  },
});
```

### Function Types

| Type | Import | Database Access | Duration | Use For |
|------|--------|-----------------|----------|---------|
| `query` | `./_generated/server` | Read-only | 1 sec | Reading data |
| `mutation` | `./_generated/server` | Read/Write | 1 sec | Modifying data |
| `action` | `./_generated/server` | **None** | 10 min | External APIs |
| `internalQuery` | `./_generated/server` | Read-only | 1 sec | Private queries |
| `internalMutation` | `./_generated/server` | Read/Write | 1 sec | Private mutations |
| `internalAction` | `./_generated/server` | **None** | 10 min | Private actions |

- Use `query`, `mutation`, `action` for **public API** (exposed to internet)
- Use `internalQuery`, `internalMutation`, `internalAction` for **private functions** (only callable by other Convex functions)

## Function References

Use the `api` and `internal` objects for function references:

```ts
import { api } from "./_generated/api";      // Public functions
import { internal } from "./_generated/api"; // Internal functions

// Call from mutation or action
await ctx.runQuery(api.users.get, { userId });
await ctx.runMutation(api.messages.send, { content });
await ctx.runAction(internal.ai.generate, { prompt });
```

**Critical**: Always use `FunctionReference`, never pass functions directly.

## Schema Design

Define schemas in `convex/schema.ts`:

```ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  messages: defineTable({
    channelId: v.id("channels"),
    authorId: v.id("users"),
    content: v.string(),
  })
    .index("by_channel", ["channelId"])
    .index("by_channel_and_author", ["channelId", "authorId"]),
});
```

### Index Rules

1. **Name indexes after fields**: `by_field1_and_field2` for `["field1", "field2"]`
2. **Query in order**: Fields must be queried in the same order they're defined
3. **Never add `_creationTime` to indexes** - It's automatically appended
4. **System indexes exist**: `by_id` and `by_creation_time` are automatic
5. **Default ordering**: Documents return in ascending `_creationTime` order

## Querying Data

```ts
// Use withIndex, NEVER filter
const messages = await ctx.db
  .query("messages")
  .withIndex("by_channel", (q) => q.eq("channelId", channelId))
  .order("desc")
  .take(10);

// Get single document
const user = await ctx.db.get(userId);

// Get unique match
const channel = await ctx.db
  .query("channels")
  .withIndex("by_name", (q) => q.eq("name", "general"))
  .unique();
```

**Never use `.filter()`** - Always define an index and use `.withIndex()`.

## Mutations

```ts
// Insert
const id = await ctx.db.insert("messages", { content, authorId });

// Patch (shallow merge)
await ctx.db.patch(messageId, { content: "updated" });

// Replace (full document)
await ctx.db.replace(messageId, { content, authorId, edited: true });

// Delete
await ctx.db.delete(messageId);
```

## Actions and External APIs

Actions cannot access `ctx.db`. Use them for external API calls:

```ts
import { action } from "./_generated/server";
import { v } from "convex/values";

export const callOpenAI = action({
  args: { prompt: v.string() },
  handler: async (ctx, args) => {
    // NO ctx.db here!
    const response = await fetch("https://api.openai.com/...");
    return await response.json();
  },
});
```

Add `"use node";` at top of files using Node.js built-in modules. Files with `"use node"` should **only contain actions**, not queries or mutations.

## Scheduling

### Scheduler (one-time)

```ts
// From mutation or action
await ctx.scheduler.runAfter(0, internal.ai.generate, { channelId });
await ctx.scheduler.runAfter(60000, api.cleanup.run, {}); // 1 minute delay
```

### Crons (recurring)

```ts
// convex/crons.ts
import { cronJobs } from "convex/server";
import { internal } from "./_generated/api";

const crons = cronJobs();
crons.interval("cleanup", { hours: 1 }, internal.tasks.cleanup, {});
export default crons;
```

**Important**: Auth does NOT propagate to scheduled jobs - `getAuthUserId()` returns `null`.

## Authentication with @convex-dev/auth

```ts
import { getAuthUserId } from "@convex-dev/auth/server";

export const currentUser = query({
  args: {},
  handler: async (ctx) => {
    const userId = await getAuthUserId(ctx);
    if (!userId) return null;
    return await ctx.db.get(userId);
  },
});
```

See `references/auth.md` for complete auth patterns including the loggedInUser query pattern.

## React Client Patterns

```tsx
import { useQuery, useMutation } from "convex/react";
import { api } from "../convex/_generated/api";

function App() {
  const messages = useQuery(api.messages.list) ?? [];
  const sendMessage = useMutation(api.messages.send);

  // Conditional queries with "skip"
  const user = useQuery(
    api.users.get,
    userId ? { userId } : "skip"
  );
}
```

**Never call hooks conditionally**:
```ts
// WRONG
const data = condition ? useQuery(api.data.get, { id }) : null;

// CORRECT
const data = useQuery(api.data.get, condition ? { id } : "skip");
```

## Additional Resources

### Reference Files

For detailed patterns and specifications, consult:

- **`references/validators.md`** - Complete validator reference table
- **`references/functions.md`** - Function registration, calling, and reference patterns
- **`references/schema.md`** - Schema design, indexes, and TypeScript patterns
- **`references/auth.md`** - @convex-dev/auth patterns (getAuthUserId, loggedInUser)
- **`references/file-storage.md`** - File storage patterns with complete examples
- **`references/scheduling.md`** - Crons and scheduler patterns in detail
- **`references/limits.md`** - Performance limits reference
- **`references/examples.md`** - Complete real-world examples (chat app, file uploads)
