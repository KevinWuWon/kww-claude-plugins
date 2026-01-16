# Modern Web Stack - Setup Steps

Detailed acceptance criteria for each setup step.

## Step 1: Initialize TanStack Start Project

**With Convex (data persistence needed):**

```bash
bun create @tanstack/start@latest <project-name> --add-on convex --add-on shadcn
```

**Without Convex (no data persistence):**

```bash
bun create @tanstack/start@latest <project-name> --add-on shadcn
```

**Important:**
- Use `bun create @tanstack/start@latest` (NOT `create-tanstack-app` which creates TanStack Router SPA)
- The CLI creates a subdirectory. If already in target directory, move files up:
  ```bash
  mv <project-name>/* <project-name>/.[!.]* . && rmdir <project-name>
  ```

**Acceptance Criteria:**
- [ ] Project created with TanStack Start and selected add-ons
- [ ] `bun dev` starts the dev server (and Convex if enabled)
- [ ] Basic route renders at localhost:3000
- [ ] `bun run typecheck` passes (add `"typecheck": "tsc --noEmit"` if missing)

## Step 2: Configure Biome

**Commands:**
```bash
bun add -D @biomejs/biome
bunx biome init
```

**Configure `biome.json` (Biome 2.x):**
```json
{
  "$schema": "https://biomejs.dev/schemas/2.3.11/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "files": {
    "ignoreUnknown": false,
    "includes": ["**", "!.claude"]
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true
    }
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "double"
    }
  },
  "css": {
    "parser": {
      "tailwindDirectives": true
    }
  },
  "assist": {
    "enabled": true,
    "actions": {
      "source": {
        "organizeImports": "on"
      }
    }
  }
}
```

**Biome 2.x Notes:**
- Enable `tailwindDirectives: true` in `css.parser` for Tailwind v4 support
- Negation patterns must come AFTER `**` in `includes`
- Run `bunx biome check --write .` to auto-fix

**Acceptance Criteria:**
- [ ] Biome installed
- [ ] `biome.json` configured with Tailwind directives enabled
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
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
});
```

**If E2E testing requested:**
```bash
bun add -D @playwright/test
bunx playwright install chromium
```

**Important:** Use `bun run test` (NOT `bun test`) - the latter invokes Bun's native test runner.

**Acceptance Criteria:**
- [ ] Vitest installed
- [ ] `vitest.config.ts` created with jsdom environment
- [ ] `bun run test` runs Vitest (not Bun's test runner)
- [ ] Playwright installed (if E2E requested)
- [ ] `playwright.config.ts` configured (if E2E requested)
- [ ] Sample test passes
- [ ] Typecheck passes

**package.json scripts to add:**
```json
{
  "test": "vitest run",
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
bun dev                    # Dev server(s) start
bun run typecheck          # No type errors
bun lint                   # No lint errors
bun run test               # Unit tests pass (use 'bun run test', NOT 'bun test')
bun run test:e2e           # E2E tests pass (if E2E enabled)
bun run check:duplicates   # No problematic duplicates
bun run check:unused       # No dead code
```
