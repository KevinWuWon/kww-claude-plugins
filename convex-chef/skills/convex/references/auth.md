# Convex Authentication Reference

Patterns for using @convex-dev/auth in Convex applications.

## Getting the Authenticated User

### In Convex Functions

```ts
import { query, mutation } from "./_generated/server";
import { getAuthUserId } from "@convex-dev/auth/server";

export const currentUser = query({
  args: {},
  handler: async (ctx) => {
    const userId = await getAuthUserId(ctx);
    if (!userId) {
      return null;
    }
    return await ctx.db.get(userId);
  },
});
```

### The loggedInUser Pattern

Create a reusable query in `convex/auth.ts`:

```ts
// convex/auth.ts
import { query } from "./_generated/server";
import { getAuthUserId } from "@convex-dev/auth/server";

export const loggedInUser = query({
  args: {},
  handler: async (ctx) => {
    const userId = await getAuthUserId(ctx);
    if (!userId) {
      return null;
    }
    const user = await ctx.db.get(userId);
    if (!user) {
      return null;
    }
    return user;
  },
});
```

Use it in React:

```tsx
import { useQuery } from "convex/react";
import { api } from "../convex/_generated/api";

function App() {
  const user = useQuery(api.auth.loggedInUser);

  if (user === undefined) {
    return <Loading />;
  }

  if (user === null) {
    return <SignIn />;
  }

  return <Dashboard user={user} />;
}
```

## Protecting Functions

### Require Authentication

```ts
import { query, mutation } from "./_generated/server";
import { getAuthUserId } from "@convex-dev/auth/server";
import { v } from "convex/values";

async function requireAuth(ctx: any) {
  const userId = await getAuthUserId(ctx);
  if (!userId) {
    throw new Error("Not authenticated");
  }
  const user = await ctx.db.get(userId);
  if (!user) {
    throw new Error("User not found");
  }
  return user;
}

export const createPost = mutation({
  args: { content: v.string() },
  handler: async (ctx, args) => {
    const user = await requireAuth(ctx);

    return await ctx.db.insert("posts", {
      authorId: user._id,
      content: args.content,
    });
  },
});
```

### Optional Authentication

```ts
export const listPosts = query({
  args: {},
  handler: async (ctx) => {
    const userId = await getAuthUserId(ctx);
    const posts = await ctx.db.query("posts").collect();

    return posts.map(post => ({
      ...post,
      isOwner: userId === post.authorId,
    }));
  },
});
```

## Auth and Scheduling

**Critical**: Auth does NOT propagate to scheduled functions.

```ts
// This will NOT work in scheduled jobs
export const scheduledTask = internalMutation({
  args: {},
  handler: async (ctx) => {
    // ALWAYS returns null in scheduled context!
    const userId = await getAuthUserId(ctx);
    // userId is null here
  },
});
```

### Solution: Pass User ID Explicitly

```ts
export const sendMessage = mutation({
  args: { content: v.string() },
  handler: async (ctx, args) => {
    const userId = await getAuthUserId(ctx);
    if (!userId) throw new Error("Not authenticated");

    await ctx.db.insert("messages", {
      authorId: userId,
      content: args.content,
    });

    // Pass userId explicitly to scheduled job
    await ctx.scheduler.runAfter(0, internal.ai.respond, {
      userId,  // Pass it explicitly!
    });
  },
});

export const respond = internalMutation({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    // Use args.userId instead of getAuthUserId
    const user = await ctx.db.get(args.userId);
  },
});
```

## Users Table Schema

The `authTables` from @convex-dev/auth includes:

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

## React Hooks

### useConvexAuth

```tsx
import { useConvexAuth } from "convex/react";

function AuthStatus() {
  const { isLoading, isAuthenticated } = useConvexAuth();

  if (isLoading) return <Loading />;
  if (!isAuthenticated) return <SignIn />;
  return <Dashboard />;
}
```

### Conditional Queries with "skip"

```tsx
function UserProfile({ userId }: { userId?: string }) {
  // Use "skip" for conditional queries
  const user = useQuery(
    api.users.get,
    userId ? { userId } : "skip"
  );

  // Never do this - hooks must not be conditional
  // WRONG: const user = userId ? useQuery(...) : null;
}
```

## Best Practices

1. **Create a helper** - Use `requireAuth` or `getLoggedInUser` helper functions
2. **Handle null gracefully** - Always check if `getAuthUserId` returns null
3. **Don't rely on auth in scheduled jobs** - Pass user IDs explicitly
4. **Use "skip" for conditional queries** - Never call hooks conditionally
5. **Separate public/private functions** - Use internal functions for privileged operations
