# Convex Functions Reference

Comprehensive guide to Convex function types, registration, and calling patterns.

## Function Types

### Public Functions

Exposed to the public internet, callable from clients:

```ts
import { query, mutation, action } from "./_generated/server";
```

### Internal Functions

Private, only callable by other Convex functions:

```ts
import { internalQuery, internalMutation, internalAction } from "./_generated/server";
```

## Function Registration

### Query (Read-only)

```ts
import { query } from "./_generated/server";
import { v } from "convex/values";

export const listMessages = query({
  args: { channelId: v.id("channels") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("messages")
      .withIndex("by_channel", (q) => q.eq("channelId", args.channelId))
      .collect();
  },
});
```

### Mutation (Read/Write)

```ts
import { mutation } from "./_generated/server";
import { v } from "convex/values";

export const sendMessage = mutation({
  args: {
    channelId: v.id("channels"),
    content: v.string(),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("messages", {
      channelId: args.channelId,
      content: args.content,
    });
  },
});
```

### Action (External APIs)

```ts
import { action } from "./_generated/server";
import { v } from "convex/values";

export const generateResponse = action({
  args: { prompt: v.string() },
  handler: async (ctx, args) => {
    // NO ctx.db available in actions!
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o",
        messages: [{ role: "user", content: args.prompt }],
      }),
    });
    return await response.json();
  },
});
```

### Internal Functions

```ts
import { internalQuery, internalMutation, internalAction } from "./_generated/server";
import { v } from "convex/values";

export const loadContext = internalQuery({
  args: { channelId: v.id("channels") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("messages")
      .withIndex("by_channel", (q) => q.eq("channelId", args.channelId))
      .take(10);
  },
});
```

## Function References

### api Object (Public Functions)

```ts
import { api } from "./_generated/api";

// Reference format: api.<filename>.<functionName>
api.messages.list        // convex/messages.ts -> list
api.users.get            // convex/users.ts -> get
api.channels.access.list // convex/channels/access.ts -> list
```

### internal Object (Internal Functions)

```ts
import { internal } from "./_generated/api";

// Reference format: internal.<filename>.<functionName>
internal.ai.generate     // convex/ai.ts -> generate (internalAction)
internal.tasks.cleanup   // convex/tasks.ts -> cleanup (internalMutation)
```

## Calling Functions

### From Queries

```ts
// Can only call other queries
const result = await ctx.runQuery(api.users.get, { userId });
```

### From Mutations

```ts
// Can call queries and mutations
const user = await ctx.runQuery(api.users.get, { userId });
await ctx.runMutation(api.logs.create, { action: "update" });
```

### From Actions

```ts
// Can call queries, mutations, and other actions
const context = await ctx.runQuery(internal.ai.loadContext, { channelId });
await ctx.runMutation(internal.messages.save, { content });
await ctx.runAction(internal.ai.process, { data }); // Only for cross-runtime
```

### Type Annotations for Same-File Calls

When calling functions in the same file, add type annotations:

```ts
export const f = query({
  args: { name: v.string() },
  handler: async (ctx, args) => {
    return "Hello " + args.name;
  },
});

export const g = query({
  args: {},
  handler: async (ctx, args) => {
    // Type annotation required for same-file calls
    const result: string = await ctx.runQuery(api.example.f, { name: "Bob" });
    return result;
  },
});
```

## HTTP Endpoints

```ts
// convex/http.ts or convex/router.ts
import { httpRouter } from "convex/server";
import { httpAction } from "./_generated/server";

const http = httpRouter();

http.route({
  path: "/api/webhook",
  method: "POST",
  handler: httpAction(async (ctx, req) => {
    const body = await req.json();
    // Process webhook...
    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }),
});

export default http;
```

## Best Practices

### When to Use Each Type

| Use Case | Function Type |
|----------|---------------|
| Reading data for UI | `query` |
| Modifying data | `mutation` |
| External API calls | `action` |
| Background processing | `internalAction` |
| Private data access | `internalQuery` / `internalMutation` |

### Action Best Practices

1. **Never use ctx.db in actions** - Actions don't have database access
2. **Add "use node"** at file top when using Node.js built-ins
3. **Keep queries/mutations separate** - Files with "use node" should only have actions
4. **Minimize action-to-query calls** - Each call is a separate transaction

### Function Organization

- Use file-based routing: `convex/messages.ts` → `api.messages.*`
- Group related functions in the same file
- Use directories for complex features: `convex/users/` → `api.users.*`
- Keep internal functions close to where they're called
