# Modern Web Stack - Setup Steps

Detailed acceptance criteria for each setup step.

## Step 1: Initialize TanStack Start Project

**With Convex (data persistence needed):**

```bash
bunx create-tanstack-app@latest --add-on convex --add-on shadcn
```

**Acceptance Criteria:**
- [ ] Project created with TanStack Start, Convex, and shadcn add-ons
- [ ] `bun dev` starts both TanStack Start and Convex dev servers
- [ ] Basic route renders at localhost
- [ ] Convex dashboard accessible
- [ ] Typecheck passes

**Without Convex (no data persistence):**

```bash
bunx create-tanstack-app@latest --add-on shadcn
```

**Acceptance Criteria:**
- [ ] Project created with TanStack Start and shadcn add-ons
- [ ] `bun dev` starts the dev server
- [ ] Basic route renders at localhost
- [ ] Typecheck passes

## Step 2: Configure Biome

**Commands:**
```bash
bun add -D @biomejs/biome
bunx biome init
```

**Acceptance Criteria:**
- [ ] Biome installed
- [ ] `biome.json` configured with recommended rules
- [ ] `bun lint` runs Biome check
- [ ] `bun format` runs Biome format
- [ ] Pre-existing ESLint/Prettier configs removed
- [ ] Typecheck passes

**package.json scripts to add:**
```json
{
  "lint": "biome check .",
  "format": "biome format --write ."
}
```

## Step 3: Configure Code Quality Tools

**Commands:**
```bash
bun add -D jscpd knip
```

**Acceptance Criteria:**
- [ ] jscpd installed
- [ ] knip installed
- [ ] `jscpd.json` configured for TypeScript/TSX files
- [ ] `knip.json` configured for project structure
- [ ] `bun run check:duplicates` runs jscpd
- [ ] `bun run check:unused` runs knip
- [ ] Typecheck passes

**jscpd.json example:**
```json
{
  "threshold": 0,
  "reporters": ["console"],
  "ignore": ["**/node_modules/**", "**/_generated/**"],
  "absolute": true
}
```

**package.json scripts to add:**

With Convex:
```json
{
  "check:duplicates": "jscpd src convex",
  "check:unused": "knip"
}
```

Without Convex:
```json
{
  "check:duplicates": "jscpd src",
  "check:unused": "knip"
}
```

## Step 4: Set Up Testing Framework

**Commands:**
```bash
bun add -D vitest @vitest/ui
bun add -D @playwright/test
bunx playwright install chromium
```

**Acceptance Criteria:**
- [ ] Vitest installed
- [ ] Playwright installed
- [ ] `vitest.config.ts` configured
- [ ] `playwright.config.ts` configured
- [ ] `bun test` runs Vitest
- [ ] `bun test:e2e` runs Playwright
- [ ] Sample test passes
- [ ] Typecheck passes

**package.json scripts to add:**
```json
{
  "test": "vitest",
  "test:e2e": "playwright test"
}
```

## Step 5: Set Up Convex Auth (Convex only)

Skip if not using Convex.

**Command:**
```bash
npx convex component add @convex-dev/auth
```

**Acceptance Criteria:**
- [ ] Convex Auth installed
- [ ] Auth provider configured in Convex (e.g., Google OAuth)
- [ ] `convex/auth.ts` configured with desired providers
- [ ] Environment variables documented in `.env.example`
- [ ] Typecheck passes

**Required Environment Variables (example for Google):**
- `AUTH_GOOGLE_ID` - Google OAuth client ID
- `AUTH_GOOGLE_SECRET` - Google OAuth client secret

## Step 6: Install Convex Workflow (Convex only, optional)

Skip if not using Convex.

**Command:**
```bash
npx convex component add @convex-dev/workflow
```

**Acceptance Criteria:**
- [ ] Workflow component installed
- [ ] WorkflowManager configured in `convex/workflows/`
- [ ] Retry behavior configured (e.g., 3 attempts, exponential backoff)
- [ ] Typecheck passes

## Step 7: Configure AI Dependencies (Optional)

**Commands:**
```bash
bun add ai @ai-sdk/google
```

Or other providers:
```bash
bun add @ai-sdk/openai
bun add @ai-sdk/anthropic
```

**Acceptance Criteria:**
- [ ] Vercel AI SDK installed
- [ ] Provider package(s) installed
- [ ] API key environment variables documented
- [ ] Typecheck passes

**Required Environment Variables (example for Google):**
- `GOOGLE_GENERATIVE_AI_API_KEY`

## Final package.json Scripts

**With Convex:**

```json
{
  "scripts": {
    "dev": "npm-run-all --parallel dev:frontend dev:backend",
    "dev:frontend": "vinxi dev",
    "dev:backend": "convex dev",
    "build": "vinxi build",
    "typecheck": "tsc --noEmit",
    "lint": "biome check .",
    "format": "biome format --write .",
    "test": "vitest",
    "test:e2e": "playwright test",
    "check:duplicates": "jscpd src convex",
    "check:unused": "knip"
  }
}
```

Note: Install `npm-run-all` for parallel dev servers:
```bash
bun add -D npm-run-all
```

**Without Convex:**

```json
{
  "scripts": {
    "dev": "vinxi dev",
    "build": "vinxi build",
    "typecheck": "tsc --noEmit",
    "lint": "biome check .",
    "format": "biome format --write .",
    "test": "vitest",
    "test:e2e": "playwright test",
    "check:duplicates": "jscpd src",
    "check:unused": "knip"
  }
}
```

## Verification Checklist

Run through these commands to verify setup is complete:

```bash
bun dev           # Dev server(s) start
bun typecheck     # No type errors
bun lint          # No lint errors
bun test          # Unit tests pass
bun test:e2e      # E2E tests pass
bun check:duplicates  # No problematic duplicates
bun check:unused      # No dead code
```
