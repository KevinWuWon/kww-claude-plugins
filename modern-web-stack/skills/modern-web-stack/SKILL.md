---
name: modern-web-stack
description: Scaffold a production-ready web app using TanStack Start with Convex backend, shadcn/ui, Biome, Vitest, and Playwright.
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
| Linting/Formatting | Biome |
| Unit Tests | Vitest |
| E2E Tests | Playwright (optional) |
| Code Quality | jscpd (duplication), knip (dead code) |

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
bunx create-tanstack-app@latest --add-on convex --add-on shadcn
```

Verify:
- `bun dev` starts both TanStack Start and Convex dev servers
- Basic route renders at localhost
- Convex dashboard accessible
- `bun run typecheck` passes

**Without Convex (no data persistence):**

```bash
bunx create-tanstack-app@latest --add-on shadcn
```

Verify:
- `bun dev` starts the dev server
- Basic route renders at localhost
- `bun run typecheck` passes

### Step 2: Configure Biome

Install and configure Biome (replaces ESLint/Prettier):

```bash
bun add -D @biomejs/biome
bunx biome init
```

Add scripts to `package.json`:

```json
{
  "scripts": {
    "lint": "biome check .",
    "format": "biome format --write ."
  }
}
```

Remove any pre-existing ESLint/Prettier configs.

Verify: `bun lint` and `bun format` work, typecheck passes.

### Step 3: Configure Code Quality Tools

Install jscpd (copy-paste detection) and knip (dead code detection):

```bash
bun add -D jscpd knip
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

Create `knip.json` configured for the project structure.

Add scripts:

```json
{
  "scripts": {
    "check:duplicates": "jscpd src convex",
    "check:unused": "knip"
  }
}
```

Verify: Both commands run successfully, typecheck passes.

### Step 4: Set Up Testing Framework

Install Vitest for unit tests:

```bash
bun add -D vitest @vitest/ui
```

Create `vitest.config.ts` for the project.

Add scripts:

```json
{
  "scripts": {
    "test": "vitest"
  }
}
```

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

Verify: Sample tests pass, typecheck passes.

### Step 5: Set Up Convex Auth (if requested)

Skip if user answered "No" to Convex Auth question.

Install and configure Convex Auth:

```bash
npx convex component add @convex-dev/auth
```

Configure auth provider (e.g., Google OAuth) in `convex/auth.ts`.

Document required environment variables in `.env.example`.

Verify: Auth flow works, typecheck passes.

### Step 6: Set Up Convex Workflows (if requested)

Skip if user answered "No" to Convex Workflows question.

For durable multi-step pipelines:

```bash
npx convex component add @convex-dev/workflow
```

Configure WorkflowManager in `convex/workflows/` with retry behavior.

Verify: Typecheck passes.

### Step 7: Configure AI Dependencies (if requested)

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
    "typecheck": "tsc --noEmit",
    "lint": "biome check .",
    "format": "biome format --write .",
    "test": "vitest",
    "check:duplicates": "jscpd src",
    "check:unused": "knip"
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
    "check:duplicates": "jscpd src convex"
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
| Build for production | `bun build` | |
| Type check | `bun typecheck` | |
| Lint code | `bun lint` | |
| Format code | `bun format` | |
| Run unit tests | `bun test` | |
| Run E2E tests | `bun test:e2e` | If E2E enabled |
| Check duplicates | `bun check:duplicates` | |
| Check unused code | `bun check:unused` | |
| Deploy Convex | `npx convex deploy` | If Convex enabled |
