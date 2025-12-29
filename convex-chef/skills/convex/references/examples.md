# Convex Examples

Complete real-world examples demonstrating Convex patterns.

## Example 1: Real-Time Chat with AI

A chat application with multiple channels and AI-powered responses.

### Schema

```ts
// convex/schema.ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  channels: defineTable({
    name: v.string(),
  }),

  users: defineTable({
    name: v.string(),
  }),

  messages: defineTable({
    channelId: v.id("channels"),
    authorId: v.optional(v.id("users")), // null for AI messages
    content: v.string(),
  }).index("by_channel", ["channelId"]),
});
```

### Backend Functions

```ts
// convex/index.ts
import {
  query,
  mutation,
  internalQuery,
  internalMutation,
  internalAction,
} from "./_generated/server";
import { v } from "convex/values";
import OpenAI from "openai";
import { internal } from "./_generated/api";

// Create a user
export const createUser = mutation({
  args: { name: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db.insert("users", { name: args.name });
  },
});

// Create a channel
export const createChannel = mutation({
  args: { name: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db.insert("channels", { name: args.name });
  },
});

// List recent messages
export const listMessages = query({
  args: { channelId: v.id("channels") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("messages")
      .withIndex("by_channel", (q) => q.eq("channelId", args.channelId))
      .order("desc")
      .take(10);
  },
});

// Send a message and trigger AI response
export const sendMessage = mutation({
  args: {
    channelId: v.id("channels"),
    authorId: v.id("users"),
    content: v.string(),
  },
  handler: async (ctx, args) => {
    const channel = await ctx.db.get(args.channelId);
    if (!channel) throw new Error("Channel not found");

    const user = await ctx.db.get(args.authorId);
    if (!user) throw new Error("User not found");

    await ctx.db.insert("messages", {
      channelId: args.channelId,
      authorId: args.authorId,
      content: args.content,
    });

    // Schedule AI response
    await ctx.scheduler.runAfter(0, internal.index.generateResponse, {
      channelId: args.channelId,
    });
  },
});

// Internal: Load context for AI
export const loadContext = internalQuery({
  args: { channelId: v.id("channels") },
  handler: async (ctx, args) => {
    const messages = await ctx.db
      .query("messages")
      .withIndex("by_channel", (q) => q.eq("channelId", args.channelId))
      .order("desc")
      .take(10);

    const result = [];
    for (const message of messages) {
      if (message.authorId) {
        const user = await ctx.db.get(message.authorId);
        result.push({
          role: "user" as const,
          content: `${user?.name}: ${message.content}`,
        });
      } else {
        result.push({
          role: "assistant" as const,
          content: message.content
        });
      }
    }
    return result.reverse();
  },
});

// Internal: Generate AI response
const openai = new OpenAI();

export const generateResponse = internalAction({
  args: { channelId: v.id("channels") },
  handler: async (ctx, args) => {
    const context = await ctx.runQuery(internal.index.loadContext, {
      channelId: args.channelId,
    });

    const response = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: context,
    });

    const content = response.choices[0].message.content;
    if (!content) throw new Error("No content in response");

    await ctx.runMutation(internal.index.writeAgentResponse, {
      channelId: args.channelId,
      content,
    });
  },
});

// Internal: Save AI response
export const writeAgentResponse = internalMutation({
  args: {
    channelId: v.id("channels"),
    content: v.string(),
  },
  handler: async (ctx, args) => {
    await ctx.db.insert("messages", {
      channelId: args.channelId,
      content: args.content,
      // authorId omitted = AI message
    });
  },
});
```

### Frontend

```tsx
// src/App.tsx
import { useState } from "react";
import { useQuery, useMutation } from "convex/react";
import { api } from "../convex/_generated/api";

export default function App() {
  const [channelId, setChannelId] = useState<string | null>(null);
  const [userId, setUserId] = useState<string | null>(null);
  const [newMessage, setNewMessage] = useState("");

  const messages = useQuery(
    api.index.listMessages,
    channelId ? { channelId } : "skip"
  ) ?? [];

  const sendMessage = useMutation(api.index.sendMessage);

  const handleSend = async () => {
    if (!channelId || !userId || !newMessage) return;

    await sendMessage({
      channelId,
      authorId: userId,
      content: newMessage,
    });
    setNewMessage("");
  };

  return (
    <div>
      {messages.map((m) => (
        <div key={m._id}>
          {m.authorId ? "User" : "AI"}: {m.content}
        </div>
      ))}
      <input
        value={newMessage}
        onChange={(e) => setNewMessage(e.target.value)}
        onKeyPress={(e) => e.key === "Enter" && handleSend()}
      />
      <button onClick={handleSend}>Send</button>
    </div>
  );
}
```

## Example 2: File Uploads with Messages

A messaging system supporting both text and image messages.

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

// List messages with image URLs
export const list = query({
  args: {},
  handler: async (ctx) => {
    const messages = await ctx.db.query("messages").collect();

    return Promise.all(
      messages.map(async (message) => ({
        ...message,
        ...(message.format === "image"
          ? { url: await ctx.storage.getUrl(message.body as any) }
          : {}),
      })),
    );
  },
});

// Generate upload URL
export const generateUploadUrl = mutation({
  args: {},
  handler: async (ctx) => {
    return await ctx.storage.generateUploadUrl();
  },
});

// Send image message
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

// Send text message
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
// src/App.tsx
import { FormEvent, useRef, useState } from "react";
import { useMutation, useQuery } from "convex/react";
import { api } from "../convex/_generated/api";

export default function App() {
  const messages = useQuery(api.messages.list) ?? [];
  const [name] = useState(() => "User " + Math.floor(Math.random() * 10000));

  // Text messages
  const [newMessageText, setNewMessageText] = useState("");
  const sendMessage = useMutation(api.messages.sendMessage);

  async function handleSendMessage(event: FormEvent) {
    event.preventDefault();
    if (!newMessageText) return;
    await sendMessage({ body: newMessageText, author: name });
    setNewMessageText("");
  }

  // Image uploads
  const generateUploadUrl = useMutation(api.messages.generateUploadUrl);
  const sendImage = useMutation(api.messages.sendImage);
  const imageInput = useRef<HTMLInputElement>(null);
  const [selectedImage, setSelectedImage] = useState<File | null>(null);

  async function handleSendImage(event: FormEvent) {
    event.preventDefault();
    if (!selectedImage) return;

    // 1. Get upload URL
    const postUrl = await generateUploadUrl();

    // 2. Upload file
    const result = await fetch(postUrl, {
      method: "POST",
      headers: { "Content-Type": selectedImage.type },
      body: selectedImage,
    });
    const { storageId } = await result.json();

    // 3. Save to database
    await sendImage({ storageId, author: name });

    setSelectedImage(null);
    imageInput.current!.value = "";
  }

  return (
    <main>
      <h1>Chat with Images</h1>
      <p>Logged in as: {name}</p>

      <ul>
        {messages.map((message) => (
          <li key={message._id}>
            <strong>{message.author}:</strong>{" "}
            {message.format === "image" ? (
              <img src={message.url} height="200" />
            ) : (
              <span>{message.body}</span>
            )}
          </li>
        ))}
      </ul>

      <form onSubmit={handleSendMessage}>
        <input
          value={newMessageText}
          onChange={(e) => setNewMessageText(e.target.value)}
          placeholder="Type a message..."
        />
        <button type="submit" disabled={!newMessageText}>
          Send
        </button>
      </form>

      <form onSubmit={handleSendImage}>
        <input
          type="file"
          accept="image/*"
          ref={imageInput}
          onChange={(e) => setSelectedImage(e.target.files![0])}
        />
        <button type="submit" disabled={!selectedImage}>
          Upload Image
        </button>
      </form>
    </main>
  );
}
```

## Example 3: Authenticated Todo App

A todo app with user authentication.

### Schema

```ts
// convex/schema.ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";
import { authTables } from "@convex-dev/auth/server";

const applicationTables = {
  todos: defineTable({
    userId: v.id("users"),
    text: v.string(),
    completed: v.boolean(),
  }).index("by_user", ["userId"]),
};

export default defineSchema({
  ...authTables,
  ...applicationTables,
});
```

### Backend

```ts
// convex/todos.ts
import { query, mutation } from "./_generated/server";
import { getAuthUserId } from "@convex-dev/auth/server";
import { v } from "convex/values";

// Get logged-in user or throw
async function requireAuth(ctx: any) {
  const userId = await getAuthUserId(ctx);
  if (!userId) throw new Error("Not authenticated");
  return userId;
}

// List user's todos
export const list = query({
  args: {},
  handler: async (ctx) => {
    const userId = await requireAuth(ctx);

    return await ctx.db
      .query("todos")
      .withIndex("by_user", (q) => q.eq("userId", userId))
      .collect();
  },
});

// Create todo
export const create = mutation({
  args: { text: v.string() },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    return await ctx.db.insert("todos", {
      userId,
      text: args.text,
      completed: false,
    });
  },
});

// Toggle todo completion
export const toggle = mutation({
  args: { id: v.id("todos") },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    const todo = await ctx.db.get(args.id);
    if (!todo) throw new Error("Todo not found");
    if (todo.userId !== userId) throw new Error("Not authorized");

    await ctx.db.patch(args.id, { completed: !todo.completed });
  },
});

// Delete todo
export const remove = mutation({
  args: { id: v.id("todos") },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    const todo = await ctx.db.get(args.id);
    if (!todo) throw new Error("Todo not found");
    if (todo.userId !== userId) throw new Error("Not authorized");

    await ctx.db.delete(args.id);
  },
});
```

### Frontend

```tsx
// src/App.tsx
import { useState } from "react";
import { useQuery, useMutation } from "convex/react";
import { useConvexAuth } from "convex/react";
import { api } from "../convex/_generated/api";

export default function App() {
  const { isAuthenticated, isLoading } = useConvexAuth();

  if (isLoading) return <div>Loading...</div>;
  if (!isAuthenticated) return <SignIn />;
  return <TodoList />;
}

function TodoList() {
  const todos = useQuery(api.todos.list) ?? [];
  const createTodo = useMutation(api.todos.create);
  const toggleTodo = useMutation(api.todos.toggle);
  const removeTodo = useMutation(api.todos.remove);

  const [newTodo, setNewTodo] = useState("");

  const handleCreate = async () => {
    if (!newTodo.trim()) return;
    await createTodo({ text: newTodo });
    setNewTodo("");
  };

  return (
    <div>
      <h1>My Todos</h1>

      <div>
        <input
          value={newTodo}
          onChange={(e) => setNewTodo(e.target.value)}
          onKeyPress={(e) => e.key === "Enter" && handleCreate()}
          placeholder="Add a todo..."
        />
        <button onClick={handleCreate}>Add</button>
      </div>

      <ul>
        {todos.map((todo) => (
          <li key={todo._id}>
            <input
              type="checkbox"
              checked={todo.completed}
              onChange={() => toggleTodo({ id: todo._id })}
            />
            <span style={{
              textDecoration: todo.completed ? "line-through" : "none"
            }}>
              {todo.text}
            </span>
            <button onClick={() => removeTodo({ id: todo._id })}>
              Delete
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
```
