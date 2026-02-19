---
name: modern-web-stack
description: This skill should be used when the user asks to "scaffold a web app", "create a new project", "set up a TanStack Start app", "start a new web application", or "build a fullstack app". Scaffolds a production-ready web app using TanStack Start with Convex backend, shadcn/ui, oxlint, oxfmt, tsgo, React Compiler, Vitest, and Playwright.
user-invocable: true
---

# Modern Web Stack

Build production-ready web applications using TanStack Start with Convex backend and comprehensive dev tooling.

## Stack Overview

| Category | Technology |
|----------|------------|
| Framework | TanStack Start (React, file-based routing) |
| Backend | Convex (optional) |
| Auth | Convex Auth (optional, requires Convex) |
| Workflows | Convex Workflows (optional, requires Convex) |
| UI Components | shadcn/ui |
| Styling | Tailwind CSS |
| Package Manager | Bun |
| Linting | oxlint + @nkzw/oxlint-config |
| Formatting | oxfmt |
| Type Checking | tsgo (@typescript/native-preview) |
| React Optimization | React Compiler |
| Unit Tests | Vitest |
| E2E Tests | Playwright (optional) |
| Code Quality | jscpd (duplication), react-doctor (code health) |
| Date/Time | temporal-polyfill |

## Initial Questions

Before starting setup, ask the user:

1. **Project name** - What should the project be called?

2. **Convex backend** - Does the app need to persist data?
   - **Yes** → Use Convex (database, file storage, real-time sync)
   - **No** → Skip Convex (TanStack Start still handles server-side API calls)

3. **Convex Auth** (only if using Convex) - Does the app need user authentication?
   - **Yes** → Set up Convex Auth with OAuth providers (Google, GitHub, etc.)
   - **No** → Skip auth setup

4. **Convex Workflows** (only if using Convex) - Does the app need durable background jobs?
   - **Yes** → Set up Convex Workflows for multi-step pipelines with retries
   - **No** → Skip workflow setup (can add later)

5. **AI integration** - Will the app use AI APIs (Gemini, OpenAI, Claude)?

6. **E2E testing** - Include Playwright for end-to-end browser tests?
   - **Yes** → Full testing setup (Vitest + Playwright)
   - **No** → Unit tests only (Vitest)

## Project Setup Steps

Follow these steps in order. Each step should pass typecheck before proceeding.

### Step 1: Initialize TanStack Start Project

**With Convex (data persistence needed):**

```bash
bunx @tanstack/cli create <project-name> --add-ons convex,shadcn
```

**Without Convex (no data persistence):**

```bash
bunx @tanstack/cli create <project-name> --add-ons shadcn
```

**Important Notes:**
- The CLI creates a subdirectory with the project name. If you're already in the target directory, you may need to move files up: `mv <project-name>/* <project-name>/.[!.]* . && rmdir <project-name>`
- Use `bunx @tanstack/cli create` (NOT `create-tanstack-app` which creates TanStack Router SPA, not TanStack Start SSR)

Verify:
- `bun dev` starts the dev server (and Convex if enabled)
- Basic route renders at localhost:3000
- `bun run typecheck` passes (add script if missing: `"typecheck": "tsgo --noEmit"`)

**Install tsgo** (native TypeScript compiler, ~10x faster than tsc):

```bash
bun add -D @typescript/native-preview
```

### Step 2: Configure oxfmt + oxlint

Install oxfmt (formatter) and oxlint (linter) with the @nkzw/oxlint-config shared config:

```bash
bun add -D oxfmt oxlint @nkzw/oxlint-config
```

**Configure oxfmt** — create `.oxfmtrc.jsonc`:

```jsonc
{
  "$schema": "https://oxc.rs/schemas/oxfmt/0.x.x.json",
  "semi": true,
  "singleQuote": false,
  "tabWidth": 2,
  "trailingComma": "all",
  "experimentalSortImports": {},
  "experimentalTailwindcss": {}
}
```

**Configure oxlint** — create `oxlint.config.ts`:

```typescript
import nkzw from "@nkzw/oxlint-config";
import { defineConfig } from "oxlint";

export default defineConfig({
  extends: [nkzw],
});
```

ESLint plugins can also be used via the `jsPlugins` field (see https://oxc.rs/docs/guide/usage/linter/js-plugins.html):

```typescript
import nkzw from "@nkzw/oxlint-config";
import { defineConfig } from "oxlint";

export default defineConfig({
  extends: [nkzw],
  jsPlugins: ["eslint-plugin-playwright"],
  rules: {
    "playwright/no-focused-test": "error",
  },
});
```

Add scripts to `package.json`:

```json
{
  "scripts": {
    "lint": "oxlint",
    "format": "oxfmt --write .",
    "format:check": "oxfmt --check ."
  }
}
```

Remove any pre-existing ESLint/Prettier/Biome configs.

Verify: `bun lint` and `bun format` work, typecheck passes.

### Step 3: Enable React Compiler

Install the React Compiler babel plugin:

```bash
bun add -D babel-plugin-react-compiler
```

TanStack Start uses Vinxi (Vite-based) with `@vitejs/plugin-react`. Add the React Compiler plugin to `app.config.ts`:

```typescript
import { defineConfig } from "@tanstack/react-start/config";

export default defineConfig({
  react: {
    babel: {
      plugins: ["babel-plugin-react-compiler"],
    },
  },
});
```

**Important:** The React Compiler babel plugin must run first in the babel pipeline. Verify optimization in React DevTools — optimized components show a "Memo" badge.

Verify: `bun dev` starts without errors, typecheck passes.

### Step 4: Configure Code Quality Tools

Install jscpd (copy-paste detection) and react-doctor (React code health):

```bash
bun add -D jscpd react-doctor
```

Create `jscpd.json`:

```json
{
  "threshold": 0,
  "reporters": ["console"],
  "ignore": ["**/node_modules/**", "**/_generated/**"],
  "absolute": true
}
```

Install temporal-polyfill for date/time handling:

```bash
bun add temporal-polyfill
```

This provides the TC39 Temporal API polyfill — use `Temporal.PlainDate`, `Temporal.ZonedDateTime`, `Temporal.Duration`, etc. instead of date-fns/dayjs/moment.

Add scripts:

```json
{
  "scripts": {
    "check:duplicates": "jscpd app convex",
    "check:health": "react-doctor"
  }
}
```

Verify: Both commands run successfully, typecheck passes.

### Step 5: Set Up Testing Framework

Install Vitest for unit tests (may already be included by template):

```bash
bun add -D vitest @vitest/ui @testing-library/react @testing-library/dom jsdom
```

**Create `vitest.config.ts`** (required for jsdom environment):

```typescript
import { fileURLToPath, URL } from "node:url";
import viteReact from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [viteReact()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: [],
  },
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./app", import.meta.url)),
    },
  },
});
```

Add scripts:

```json
{
  "scripts": {
    "test": "vitest run"
  }
}
```

**Important:** Use `bun run test` (not `bun test`) to run the npm script. `bun test` invokes Bun's native test runner instead.

**If E2E testing requested**, also install Playwright:

```bash
bun add -D @playwright/test
bunx playwright install chromium
```

Create `playwright.config.ts` and add script:

```json
{
  "scripts": {
    "test:e2e": "playwright test"
  }
}
```

Verify: `bun run test` passes, typecheck passes.

### Step 6: Set Up Convex Auth (if requested)

Skip if user answered "No" to Convex Auth question.

Install and configure Convex Auth:

```bash
npx convex component add @convex-dev/auth
```

Configure auth provider (e.g., Google OAuth) in `convex/auth.ts`.

Document required environment variables in `.env.example`.

Verify: Auth flow works, typecheck passes.

### Step 7: Set Up Convex Workflows (if requested)

Skip if user answered "No" to Convex Workflows question.

For durable multi-step pipelines:

```bash
npx convex component add @convex-dev/workflow
```

Configure WorkflowManager in `convex/workflows/` with retry behavior.

Verify: Typecheck passes.

### Step 8: Configure AI Dependencies (if requested)

Skip if user answered "No" to AI integration question.

Install Vercel AI SDK with providers:

```bash
bun add ai @ai-sdk/google
```

Document API key environment variables.

Verify: Typecheck passes.

## Package.json Scripts Summary

**Base scripts (always included):**

```json
{
  "scripts": {
    "dev": "vinxi dev",
    "build": "vinxi build",
    "typecheck": "tsgo --noEmit",
    "lint": "oxlint",
    "format": "oxfmt --write .",
    "format:check": "oxfmt --check .",
    "test": "vitest run",
    "check:duplicates": "jscpd app",
    "check:health": "react-doctor"
  }
}
```

**With Convex**, modify dev script and check:duplicates:

```json
{
  "scripts": {
    "dev": "npm-run-all --parallel dev:frontend dev:backend",
    "dev:frontend": "vinxi dev",
    "dev:backend": "convex dev",
    "check:duplicates": "jscpd app convex"
  }
}
```

**With E2E testing**, add:

```json
{
  "scripts": {
    "test:e2e": "playwright test"
  }
}
```

## Project Structure

**Base structure:**

```
app/
├── components/       # React components
│   └── ui/          # shadcn/ui components
├── routes/          # File-based routes
├── lib/             # Utilities
└── styles.css       # Tailwind styles
```

**With Convex**, add:

```
convex/
├── schema.ts        # Database schema
├── auth.ts          # Auth configuration (if Convex Auth)
├── workflows/       # Workflow definitions (if Convex Workflows)
├── _generated/      # Auto-generated types
└── *.ts             # Backend functions
```

**Without Convex**, add server folder:

```
app/
├── server/          # Server functions (API calls, etc.)
```

**With E2E testing**, add:

```
e2e/
└── *.spec.ts        # Playwright tests
```

## Additional Resources

### Reference Files

For detailed configuration examples and patterns:
- **`references/stack-details.md`** - Complete technology breakdown
- **`references/setup-steps.md`** - Detailed acceptance criteria for each setup step

## Key Commands Reference

| Task | Command | Notes |
|------|---------|-------|
| Start dev servers | `bun dev` | |
| Build for production | `bun run build` | |
| Type check | `bun run typecheck` | |
| Lint code | `bun lint` | oxlint |
| Format code | `bun format` | oxfmt |
| Check formatting | `bun run format:check` | CI-friendly |
| Run unit tests | `bun run test` | Use `bun run test`, NOT `bun test` |
| Run E2E tests | `bun run test:e2e` | If E2E enabled |
| Check duplicates | `bun run check:duplicates` | |
| Check code health | `bun run check:health` | |
| Deploy Convex | `npx convex deploy` | If Convex enabled |
