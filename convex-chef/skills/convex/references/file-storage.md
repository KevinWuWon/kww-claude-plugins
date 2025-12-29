# Convex File Storage Reference

Complete guide to file storage in Convex applications.

## Overview

Convex provides built-in file storage for large files like images, videos, and PDFs. Files are stored separately from documents and referenced by storage IDs.

## Core Concepts

1. **Storage IDs** - Reference to a stored file (`Id<"_storage">`)
2. **Signed URLs** - Temporary URLs for accessing files
3. **_storage table** - System table containing file metadata

## Uploading Files

### Step 1: Generate Upload URL

```ts
// convex/files.ts
import { mutation } from "./_generated/server";

export const generateUploadUrl = mutation({
  args: {},
  handler: async (ctx) => {
    return await ctx.storage.generateUploadUrl();
  },
});
```

### Step 2: Upload from Client

```tsx
const generateUploadUrl = useMutation(api.files.generateUploadUrl);

async function uploadFile(file: File) {
  // Get the upload URL
  const uploadUrl = await generateUploadUrl();

  // Upload the file
  const result = await fetch(uploadUrl, {
    method: "POST",
    headers: { "Content-Type": file.type },
    body: file,
  });

  const { storageId } = await result.json();
  return storageId;
}
```

### Step 3: Save Storage ID

```ts
// convex/files.ts
export const saveFile = mutation({
  args: {
    storageId: v.id("_storage"),
    name: v.string(),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("files", {
      storageId: args.storageId,
      name: args.name,
    });
  },
});
```

## Retrieving Files

### Get Signed URL

```ts
export const getFileUrl = query({
  args: { storageId: v.id("_storage") },
  handler: async (ctx, args) => {
    return await ctx.storage.getUrl(args.storageId);
  },
});
```

### Get File Metadata

Query the `_storage` system table:

```ts
import { query } from "./_generated/server";
import { v } from "convex/values";
import { Id } from "./_generated/dataModel";

type FileMetadata = {
  _id: Id<"_storage">;
  _creationTime: number;
  contentType?: string;
  sha256: string;
  size: number;
};

export const getFileMetadata = query({
  args: { storageId: v.id("_storage") },
  handler: async (ctx, args) => {
    const metadata: FileMetadata | null = await ctx.db.system.get(args.storageId);
    return metadata;
  },
});
```

## Complete Image Upload Example

### Schema

```ts
// convex/schema.ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  messages: defineTable({
    body: v.union(v.string(), v.id("_storage")),
    author: v.string(),
    format: v.union(v.literal("text"), v.literal("image")),
  }),
});
```

### Backend

```ts
// convex/messages.ts
import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

export const list = query({
  args: {},
  handler: async (ctx) => {
    const messages = await ctx.db.query("messages").collect();
    return Promise.all(
      messages.map(async (message) => ({
        ...message,
        // Get URL for image messages
        ...(message.format === "image"
          ? { url: await ctx.storage.getUrl(message.body as any) }
          : {}),
      })),
    );
  },
});

export const generateUploadUrl = mutation({
  args: {},
  handler: async (ctx) => {
    return await ctx.storage.generateUploadUrl();
  },
});

export const sendImage = mutation({
  args: {
    storageId: v.id("_storage"),
    author: v.string()
  },
  handler: async (ctx, args) => {
    await ctx.db.insert("messages", {
      body: args.storageId,
      author: args.author,
      format: "image",
    });
  },
});

export const sendMessage = mutation({
  args: {
    body: v.string(),
    author: v.string()
  },
  handler: async (ctx, args) => {
    await ctx.db.insert("messages", {
      body: args.body,
      author: args.author,
      format: "text"
    });
  },
});
```

### Frontend

```tsx
import { FormEvent, useRef, useState } from "react";
import { useMutation, useQuery } from "convex/react";
import { api } from "../convex/_generated/api";

export default function Chat() {
  const messages = useQuery(api.messages.list) ?? [];
  const generateUploadUrl = useMutation(api.messages.generateUploadUrl);
  const sendImage = useMutation(api.messages.sendImage);

  const [selectedImage, setSelectedImage] = useState<File | null>(null);
  const imageInput = useRef<HTMLInputElement>(null);
  const [name] = useState("User " + Math.floor(Math.random() * 10000));

  async function handleSendImage(event: FormEvent) {
    event.preventDefault();
    if (!selectedImage) return;

    // Step 1: Get upload URL
    const postUrl = await generateUploadUrl();

    // Step 2: Upload file
    const result = await fetch(postUrl, {
      method: "POST",
      headers: { "Content-Type": selectedImage.type },
      body: selectedImage,
    });
    const { storageId } = await result.json();

    // Step 3: Save to database
    await sendImage({ storageId, author: name });

    setSelectedImage(null);
    imageInput.current!.value = "";
  }

  return (
    <div>
      {messages.map((message) => (
        <div key={message._id}>
          <span>{message.author}: </span>
          {message.format === "image" ? (
            <img src={message.url} height="300px" />
          ) : (
            <span>{message.body}</span>
          )}
        </div>
      ))}

      <form onSubmit={handleSendImage}>
        <input
          type="file"
          accept="image/*"
          ref={imageInput}
          onChange={(e) => setSelectedImage(e.target.files![0])}
        />
        <button type="submit" disabled={!selectedImage}>
          Send Image
        </button>
      </form>
    </div>
  );
}
```

## Best Practices

### Do

- **Store storage IDs, not URLs** - URLs expire, storage IDs are permanent
- **Fetch URLs on demand** - Use `ctx.storage.getUrl()` in queries
- **Convert to Blob** - Storage uses Blob objects
- **Check for null** - `getUrl()` returns null if file doesn't exist

### Don't

- **Don't store URLs in database** - They're temporary and will expire
- **Don't use deprecated methods** - Avoid `ctx.storage.getMetadata`
- **Don't assume URLs persist** - Always fetch fresh URLs

## File Operations from Actions

Actions can store and retrieve files too:

```ts
export const downloadAndStore = action({
  args: { url: v.string() },
  handler: async (ctx, args) => {
    // Download file
    const response = await fetch(args.url);
    const blob = await response.blob();

    // Store in Convex
    const storageId = await ctx.storage.store(blob);

    // Save reference via mutation
    await ctx.runMutation(internal.files.save, { storageId });

    return storageId;
  },
});
```

## Deleting Files

```ts
export const deleteFile = mutation({
  args: { storageId: v.id("_storage") },
  handler: async (ctx, args) => {
    await ctx.storage.delete(args.storageId);
  },
});
```
