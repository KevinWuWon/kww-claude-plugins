---
name: convex
description: This skill should be used when the user is working with Convex backend code, writing files in the convex/ directory, creating queries/mutations/actions, defining Convex schemas, or asks about Convex patterns and best practices. Also use when user mentions "Convex functions", "Convex validators", "Convex schema", or needs guidance on Convex API design.
---

# Convex Guidelines

Guidelines and best practices for writing Convex backend code.

## Function Guidelines

### New Function Syntax

Always use the new function syntax for Convex functions:

```typescript
import { query } from "./_generated/server";
import { v } from "convex/values";

export const f = query({
  args: {},
  returns: v.null(),
  handler: async (ctx, args) => {
    // Function body
  },
});
```

### HTTP Endpoint Syntax

Define HTTP endpoints in `convex/http.ts` with the `httpAction` decorator:

```typescript
import { httpRouter } from "convex/server";
import { httpAction } from "./_generated/server";

const http = httpRouter();

http.route({
  path: "/echo",
  method: "POST",
  handler: httpAction(async (ctx, req) => {
    const body = await req.bytes();
    return new Response(body, { status: 200 });
  }),
});
```

HTTP endpoints are registered at the exact path specified in the `path` field. For example, `/api/someRoute` registers at `/api/someRoute`.

### Validators

Array validator example:

```typescript
import { mutation } from "./_generated/server";
import { v } from "convex/values";

export default mutation({
  args: {
    simpleArray: v.array(v.union(v.string(), v.number())),
  },
  handler: async (ctx, args) => {
    //...
  },
});
```

Discriminated union schema example:

```typescript
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  results: defineTable(
    v.union(
      v.object({
        kind: v.literal("error"),
        errorMessage: v.string(),
      }),
      v.object({
        kind: v.literal("success"),
        value: v.number(),
      }),
    ),
  )
});
```

Always use `v.null()` when returning null:

```typescript
import { query } from "./_generated/server";
import { v } from "convex/values";

export const exampleQuery = query({
  args: {},
  returns: v.null(),
  handler: async (ctx, args) => {
    console.log("This query returns a null value");
    return null;
  },
});
```

### Convex Types and Validators

| Convex Type | TS/JS type   | Example Usage          | Validator                    | Notes |
|-------------|--------------|------------------------|------------------------------|-------|
| Id          | string       | `doc._id`              | `v.id(tableName)`            | |
| Null        | null         | `null`                 | `v.null()`                   | JavaScript's `undefined` is not valid. Functions returning `undefined` return `null` from client. |
| Int64       | bigint       | `3n`                   | `v.int64()`                  | Supports BigInts between -2^63 and 2^63-1. |
| Float64     | number       | `3.1`                  | `v.number()`                 | All IEEE-754 double-precision floats. Inf and NaN JSON serialized as strings. |
| Boolean     | boolean      | `true`                 | `v.boolean()`                | |
| String      | string       | `"abc"`                | `v.string()`                 | UTF-8, must be valid Unicode. Max 1MB when UTF-8 encoded. |
| Bytes       | ArrayBuffer  | `new ArrayBuffer(8)`   | `v.bytes()`                  | Max 1MB. |
| Array       | Array        | `[1, 3.2, "abc"]`      | `v.array(values)`            | Max 8192 values. |
| Object      | Object       | `{a: "abc"}`           | `v.object({property: value})`| Plain objects only. Max 1024 entries. Fields must be nonempty, not start with "$" or "_". |
| Record      | Record       | `{"a": "1", "b": "2"}` | `v.record(keys, values)`     | Keys must be ASCII, nonempty, not start with "$" or "_". |

### Function Registration

- Use `internalQuery`, `internalMutation`, `internalAction` for internal (private) functions. Import from `./_generated/server`.
- Use `query`, `mutation`, `action` for public functions exposed to the Internet. Do NOT use these for sensitive internal functions.
- Cannot register functions through `api` or `internal` objects.
- Always include argument and return validators for all functions. Use `returns: v.null()` if function doesn't return anything.
- Functions without explicit return implicitly return `null`.

### Function Calling

- Use `ctx.runQuery` to call a query from query, mutation, or action.
- Use `ctx.runMutation` to call a mutation from mutation or action.
- Use `ctx.runAction` to call an action from action.
- Only call action from another action when crossing runtimes (V8 to Node). Otherwise, extract shared code into a helper function.
- Minimize calls from actions to queries/mutations. Each is a transaction; splitting introduces race conditions.
- These calls take a `FunctionReference`. Do NOT pass the function directly.
- When calling functions in the same file, add type annotation on return value for TypeScript circularity:

```typescript
export const f = query({
  args: { name: v.string() },
  returns: v.string(),
  handler: async (ctx, args) => {
    return "Hello " + args.name;
  },
});

export const g = query({
  args: {},
  returns: v.null(),
  handler: async (ctx, args) => {
    const result: string = await ctx.runQuery(api.example.f, { name: "Bob" });
    return null;
  },
});
```

### Function References

- Function references are pointers to registered Convex functions.
- Use `api` from `convex/_generated/api.ts` for public functions (`query`, `mutation`, `action`).
- Use `internal` from `convex/_generated/api.ts` for internal functions (`internalQuery`, `internalMutation`, `internalAction`).
- File-based routing: public function `f` in `convex/example.ts` → `api.example.f`
- Private function `g` in `convex/example.ts` → `internal.example.g`
- Nested directories: `h` in `convex/messages/access.ts` → `api.messages.access.h`

### API Design

- Convex uses file-based routing. Organize files thoughtfully within `convex/`.
- Use `query`, `mutation`, `action` for public functions.
- Use `internalQuery`, `internalMutation`, `internalAction` for private functions.

### Pagination

Define paginated queries:

```typescript
import { v } from "convex/values";
import { query } from "./_generated/server";
import { paginationOptsValidator } from "convex/server";

export const listWithExtraArg = query({
  args: { paginationOpts: paginationOptsValidator, author: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("messages")
      .filter((q) => q.eq(q.field("author"), args.author))
      .order("desc")
      .paginate(args.paginationOpts);
  },
});
```

`paginationOpts` properties:
- `numItems`: max documents to return (`v.number()`)
- `cursor`: cursor for next page (`v.union(v.string(), v.null())`)

`.paginate()` returns:
- `page`: array of fetched documents
- `isDone`: boolean for last page
- `continueCursor`: cursor for next page

## Validator Guidelines

- `v.bigint()` is deprecated. Use `v.int64()` for signed 64-bit integers.
- Use `v.record()` for record types. `v.map()` and `v.set()` are not supported.

## Schema Guidelines

- Always define schema in `convex/schema.ts`.
- Import schema functions from `convex/server`.
- System fields are automatic: `_creationTime` (`v.number()`) and `_id` (`v.id(tableName)`).
- Include all index fields in index name: `["field1", "field2"]` → `"by_field1_and_field2"`.
- Index fields must be queried in definition order. Create separate indexes for different query orders.

## TypeScript Guidelines

- Use `Id` from `./_generated/dataModel` for table ID types: `Id<'users'>`.
- Match `Record` types to validators: `v.record(v.id('users'), v.string())` → `Record<Id<'users'>, string>`.

```typescript
import { query } from "./_generated/server";
import { Doc, Id } from "./_generated/dataModel";

export const exampleQuery = query({
  args: { userIds: v.array(v.id("users")) },
  returns: v.record(v.id("users"), v.string()),
  handler: async (ctx, args) => {
    const idToUsername: Record<Id<"users">, string> = {};
    for (const userId of args.userIds) {
      const user = await ctx.db.get(userId);
      if (user) {
        idToUsername[user._id] = user.username;
      }
    }
    return idToUsername;
  },
});
```

- Be strict with ID types: use `Id<'users'>` not `string`.
- Use `as const` for string literals in discriminated unions.
- Define arrays as `const array: Array<T> = [...];`
- Define records as `const record: Record<KeyType, ValueType> = {...};`
- Add `@types/node` to `package.json` when using Node.js built-in modules.

## Full Text Search Guidelines

Query example for "10 messages in channel '#general' matching 'hello hi' in body":

```typescript
const messages = await ctx.db
  .query("messages")
  .withSearchIndex("search_body", (q) =>
    q.search("body", "hello hi").eq("channel", "#general"),
  )
  .take(10);
```

## Query Guidelines

- Do NOT use `filter` in queries. Define an index and use `withIndex` instead.
- Convex queries do NOT support `.delete()`. Use `.collect()`, iterate, call `ctx.db.delete(row._id)` on each.
- Use `.unique()` for single document. Throws if multiple match.
- For async iteration, use `for await (const row of query)` instead of `.collect()` or `.take(n)`.

### Ordering

- Default order: ascending `_creationTime`.
- Use `.order('asc')` or `.order('desc')` to specify order.
- Index queries order by index columns, avoiding slow table scans.

## Mutation Guidelines

- Use `ctx.db.replace` to fully replace a document. Throws if document doesn't exist.
- Use `ctx.db.patch` for shallow merge updates. Throws if document doesn't exist.

## Action Guidelines

- Add `"use node";` at top of files with actions using Node.js built-in modules.
- Never use `ctx.db` in actions. Actions don't have database access.

```typescript
import { action } from "./_generated/server";

export const exampleAction = action({
  args: {},
  returns: v.null(),
  handler: async (ctx, args) => {
    console.log("This action does not return anything");
    return null;
  },
});
```

## Scheduling Guidelines

### Cron Guidelines

- Only use `crons.interval` or `crons.cron` methods. Do NOT use `crons.hourly`, `crons.daily`, `crons.weekly` helpers.
- Pass `FunctionReference` to cron methods, not the function directly.
- Define crons by declaring `crons` object, calling methods, exporting as default:

```typescript
import { cronJobs } from "convex/server";
import { internal } from "./_generated/api";
import { internalAction } from "./_generated/server";

const empty = internalAction({
  args: {},
  returns: v.null(),
  handler: async (ctx, args) => {
    console.log("empty");
  },
});

const crons = cronJobs();

// Run every two hours
crons.interval("delete inactive users", { hours: 2 }, internal.crons.empty, {});

export default crons;
```

- Functions can be registered in `crons.ts` like any other file.
- Always import `internal` from `_generated/api`, even for functions in the same file.

## File Storage Guidelines

- Convex includes file storage for large files (images, videos, PDFs).
- `ctx.storage.getUrl()` returns signed URL for a file, or `null` if not found.
- Do NOT use deprecated `ctx.storage.getMetadata`. Query `_storage` system table instead:

```typescript
import { query } from "./_generated/server";
import { Id } from "./_generated/dataModel";

type FileMetadata = {
  _id: Id<"_storage">;
  _creationTime: number;
  contentType?: string;
  sha256: string;
  size: number;
}

export const exampleQuery = query({
  args: { fileId: v.id("_storage") },
  returns: v.null(),
  handler: async (ctx, args) => {
    const metadata: FileMetadata | null = await ctx.db.system.get(args.fileId);
    console.log(metadata);
    return null;
  },
});
```

- Convex storage uses `Blob` objects. Convert all items to/from `Blob` when using storage.

## Examples

For a complete example implementation, see `examples/chat-app.md` which demonstrates a real-time chat application with AI responses.
