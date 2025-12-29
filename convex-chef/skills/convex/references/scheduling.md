# Convex Scheduling Reference

Guide to cron jobs and scheduled functions in Convex.

## Scheduler (One-Time Jobs)

Schedule a function to run after a delay:

```ts
import { mutation } from "./_generated/server";
import { internal } from "./_generated/api";
import { v } from "convex/values";

export const sendMessage = mutation({
  args: { content: v.string() },
  handler: async (ctx, args) => {
    await ctx.db.insert("messages", { content: args.content });

    // Schedule AI response immediately (0ms delay)
    await ctx.scheduler.runAfter(0, internal.ai.generateResponse, {
      messageContent: args.content,
    });

    // Schedule cleanup in 1 hour
    await ctx.scheduler.runAfter(
      60 * 60 * 1000, // 1 hour in ms
      internal.cleanup.oldMessages,
      {}
    );
  },
});
```

### Scheduler Methods

```ts
// Run after delay (milliseconds)
await ctx.scheduler.runAfter(delay, functionReference, args);

// Run at specific time (Unix timestamp in ms)
await ctx.scheduler.runAt(timestamp, functionReference, args);

// Cancel a scheduled job
await ctx.scheduler.cancel(scheduledJobId);
```

### Important Rules

1. **Use FunctionReference** - Never pass the function directly
2. **Import api/internal** - Always import from `_generated/api`
3. **Auth doesn't propagate** - `getAuthUserId()` returns null in scheduled jobs
4. **Limit frequency** - Don't schedule more than once every 10 seconds

## Cron Jobs (Recurring)

Define recurring jobs in `convex/crons.ts`:

```ts
// convex/crons.ts
import { cronJobs } from "convex/server";
import { internal } from "./_generated/api";

const crons = cronJobs();

// Run every 2 hours
crons.interval(
  "cleanup old messages",
  { hours: 2 },
  internal.cleanup.oldMessages,
  {}
);

// Run at specific times (cron syntax)
crons.cron(
  "daily report",
  "0 9 * * *",  // 9 AM every day
  internal.reports.generateDaily,
  {}
);

export default crons;
```

### Interval Syntax

```ts
crons.interval(name, interval, functionReference, args);

// Interval options
{ seconds: 30 }
{ minutes: 5 }
{ hours: 2 }
{ days: 1 }
```

### Cron Syntax

```ts
crons.cron(name, cronExpression, functionReference, args);

// Cron expression: minute hour day-of-month month day-of-week
"0 * * * *"     // Every hour at minute 0
"0 9 * * *"     // Daily at 9 AM
"0 0 * * 0"     // Weekly on Sunday at midnight
"0 0 1 * *"     // Monthly on the 1st at midnight
"*/5 * * * *"   // Every 5 minutes
```

### Deprecated Methods

Do NOT use these helper methods:

```ts
// WRONG - deprecated
crons.hourly(name, fn, args);
crons.daily(name, fn, args);
crons.weekly(name, fn, args);

// CORRECT - use interval or cron
crons.interval(name, { hours: 1 }, fn, args);
crons.cron(name, "0 0 * * *", fn, args);
```

## Complete Example

```ts
// convex/crons.ts
import { cronJobs } from "convex/server";
import { internal } from "./_generated/api";
import { internalMutation } from "./_generated/server";

// Define the cleanup function in the same file
export const cleanup = internalMutation({
  args: {},
  handler: async (ctx) => {
    const oneHourAgo = Date.now() - 60 * 60 * 1000;

    const oldMessages = await ctx.db
      .query("messages")
      .withIndex("by_creation_time")
      .filter((q) => q.lt(q.field("_creationTime"), oneHourAgo))
      .collect();

    for (const message of oldMessages) {
      await ctx.db.delete(message._id);
    }

    console.log(`Deleted ${oldMessages.length} old messages`);
  },
});

const crons = cronJobs();

// Even though cleanup is defined in this file,
// MUST use internal reference
crons.interval(
  "cleanup old messages",
  { hours: 1 },
  internal.crons.cleanup,
  {}
);

export default crons;
```

## Auth in Scheduled Jobs

**Critical**: Authentication does NOT propagate to scheduled functions.

```ts
// WRONG - auth is always null in scheduled jobs
export const scheduledTask = internalMutation({
  args: {},
  handler: async (ctx) => {
    const userId = await getAuthUserId(ctx);
    // userId is ALWAYS null here!
  },
});
```

### Solution: Pass Data Explicitly

```ts
// In the original mutation, pass required data
export const createTask = mutation({
  args: { title: v.string() },
  handler: async (ctx, args) => {
    const userId = await getAuthUserId(ctx);
    if (!userId) throw new Error("Not authenticated");

    const taskId = await ctx.db.insert("tasks", {
      title: args.title,
      authorId: userId,
    });

    // Pass userId to scheduled job
    await ctx.scheduler.runAfter(0, internal.tasks.process, {
      taskId,
      userId,  // Pass explicitly!
    });
  },
});

// In the scheduled job, use passed data
export const process = internalMutation({
  args: {
    taskId: v.id("tasks"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    // Use args.userId instead of getAuthUserId
    const user = await ctx.db.get(args.userId);
    // Process task...
  },
});
```

## Best Practices

### Scheduler

1. **Use internal functions** - Scheduled jobs should use `internalMutation` or `internalAction`
2. **Pass all needed data** - Auth doesn't propagate, pass user IDs explicitly
3. **Limit frequency** - Don't schedule more than once every 10 seconds
4. **Handle errors** - Scheduled jobs that fail are retried automatically

### Crons

1. **Define in crons.ts** - Keep all cron jobs in one file
2. **Use internal references** - Always import `internal` from `_generated/api`
3. **Monitor execution** - Check Convex dashboard for cron job status
4. **Keep jobs fast** - Cron handlers have the same limits as other functions

## Viewing Scheduled Jobs

Use the Convex dashboard to:
- See pending scheduled jobs
- View cron job history
- Cancel pending jobs
- Monitor job failures
