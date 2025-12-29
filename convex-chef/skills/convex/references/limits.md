# Convex Limits Reference

Performance limits for Convex functions and database operations.

## Function Limits

### Execution Time

| Function Type | Max Duration |
|---------------|--------------|
| Query | 1 second |
| Mutation | 1 second |
| Action | 10 minutes |
| HTTP Action | 10 minutes |

### Argument & Return Size

| Limit | Value |
|-------|-------|
| Function arguments | 8 MiB |
| Function return value | 8 MiB |
| HTTP request body | Unlimited |
| HTTP response (streaming) | 20 MiB |

## Database Limits

### Read Limits (Queries & Mutations)

| Limit | Value |
|-------|-------|
| Data read | 8 MiB |
| Documents read | 16,384 |

### Write Limits (Mutations)

| Limit | Value |
|-------|-------|
| Data written | 8 MiB |
| Documents written | 8,192 |

### Document Limits

| Limit | Value |
|-------|-------|
| Document size | 1 MiB |
| String size | 1 MiB (UTF-8 encoded) |
| Bytes size | 1 MiB |

## Data Structure Limits

| Structure | Max Size |
|-----------|----------|
| Array elements | 8,192 |
| Object entries | 1,024 |
| Nesting depth | 16 levels |

### Object Field Requirements

- Field names must be **ASCII characters**
- Field names must be **nonempty**
- Field names must **not start with** `$` or `_`

**Important**: Remap non-ASCII characters (like emoji) to ASCII before storing in object keys.

## Practical Implications

### When You'll Hit Limits

**Too many documents read**:
```ts
// WRONG - could read 100k+ documents
const allUsers = await ctx.db.query("users").collect();

// BETTER - paginate or limit
const recentUsers = await ctx.db
  .query("users")
  .order("desc")
  .take(100);
```

**Document too large**:
```ts
// WRONG - storing large data in document
await ctx.db.insert("files", {
  content: veryLargeString, // > 1 MiB
});

// BETTER - use file storage
const storageId = await ctx.storage.store(blob);
await ctx.db.insert("files", {
  storageId,
});
```

**Array too large**:
```ts
// WRONG - array with > 8192 elements
await ctx.db.insert("data", {
  items: hugeArray, // > 8192 items
});

// BETTER - split across documents or use file storage
```

### Stock Ticker Anti-Pattern

From the Chef guidelines:

> If you are building a stock ticker app, you can't store a database record for each stock ticker's price at a point in time. Instead, download the data as JSON, save it to file storage, and have the app download the JSON file into the browser and render it client-side.

```ts
// WRONG - millions of records
for (const price of historicalPrices) {
  await ctx.db.insert("prices", price);
}

// BETTER - store as JSON file
const json = JSON.stringify(historicalPrices);
const blob = new Blob([json], { type: "application/json" });
const storageId = await ctx.storage.store(blob);
await ctx.db.insert("datasets", {
  name: "historical_prices",
  storageId,
});
```

## Error Handling

When limits are exceeded, functions fail with errors like:

```
Error: Document is too large (max 1 MiB)
Error: Query read too many documents (max 16384)
Error: Function ran for too long (max 1 second)
Error: Array has too many elements (max 8192)
```

### Strategies

1. **Paginate queries** - Use `.take(n)` or `.paginate()`
2. **Use indexes** - Avoid full table scans
3. **Split large data** - Use file storage or multiple documents
4. **Move to actions** - Long operations can be actions (10 min limit)
5. **Batch writes** - Split large writes across multiple mutations

## Quick Reference Table

| Category | Limit | Value |
|----------|-------|-------|
| Query/Mutation execution | Time | 1 second |
| Action execution | Time | 10 minutes |
| Function arguments | Size | 8 MiB |
| Function return | Size | 8 MiB |
| Document | Size | 1 MiB |
| Read per function | Data | 8 MiB |
| Read per function | Documents | 16,384 |
| Write per function | Data | 8 MiB |
| Write per function | Documents | 8,192 |
| Array | Elements | 8,192 |
| Object | Entries | 1,024 |
| Nesting | Depth | 16 |
