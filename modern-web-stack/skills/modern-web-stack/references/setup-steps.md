# Modern Web Stack - Setup Steps

Detailed acceptance criteria for each setup step.

## Step 1: Initialize TanStack Start Project

**With Convex (data persistence needed):**

```bash
pnpm dlx @tanstack/cli create <project-name> --add-ons convex,shadcn
```

**Without Convex (no data persistence):**

```bash
pnpm dlx @tanstack/cli create <project-name> --add-ons shadcn
```

**Important:**
- Use `pnpm dlx @tanstack/cli create` (NOT `create-tanstack-app` which creates TanStack Router SPA, not TanStack Start SSR)
- The CLI creates a subdirectory. If already in target directory, move files up:
  ```bash
  mv <project-name>/* <project-name>/.[!.]* . && rmdir <project-name>
  ```
- After project creation, reinitialize shadcn with Base UI primitives:
  ```bash
  pnpm dlx shadcn@latest init --style base-ui-tw
  ```
  Then remove lingering Radix packages:
  ```bash
  pnpm remove $(pnpm ls --depth=0 | grep @radix-ui | awk '{print $1}')
  ```

**Acceptance Criteria:**
- [ ] Project created with TanStack Start and selected add-ons
- [ ] shadcn reinitialized with `--style base-ui-tw` (`@base-ui-components/react` installed)
- [ ] No `@radix-ui/*` packages in `package.json`
- [ ] `pnpm dev` starts the dev server (and Convex if enabled)
- [ ] Basic route renders at localhost:3000
- [ ] `@typescript/native-preview` installed (`pnpm add -D @typescript/native-preview`)
- [ ] `pnpm typecheck` passes (add `"typecheck": "tsgo --noEmit"` if missing)

## Step 2: Configure oxfmt + oxlint

**Commands:**
```bash
pnpm add -D oxfmt oxlint @nkzw/oxlint-config
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

**oxfmt Notes:**
- Defaults to `printWidth: 100` (wider than Prettier's 80, better for TypeScript)
- Supports `.editorconfig` properties
- Built-in import sorting via `experimentalSortImports`
- Built-in Tailwind CSS class sorting via `experimentalTailwindcss`

**oxlint Notes:**
- @nkzw/oxlint-config enforces strict rules — errors only, no warnings
- ESLint plugins can be used via `jsPlugins` field (see https://oxc.rs/docs/guide/usage/linter/js-plugins.html)
- Some plugin names are reserved (react, import, jest, typescript) — use aliases for JS versions

**Acceptance Criteria:**
- [ ] oxfmt and oxlint installed
- [ ] `.oxfmtrc.jsonc` configured with Tailwind class sorting
- [ ] `oxlint.config.ts` configured with @nkzw/oxlint-config
- [ ] `pnpm lint` runs oxlint
- [ ] `pnpm format` runs oxfmt
- [ ] Pre-existing ESLint/Prettier/Biome configs removed
- [ ] Typecheck passes

**package.json scripts to add:**
```json
{
  "lint": "oxlint",
  "format": "oxfmt --write .",
  "format:check": "oxfmt --check ."
}
```

## Step 3: Enable React Compiler

**Commands:**
```bash
pnpm add -D babel-plugin-react-compiler
```

**Configure in `app.config.ts`:**

TanStack Start uses Vinxi (Vite-based). Add the React Compiler babel plugin to the TanStack Start config:

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

**Important:** The React Compiler babel plugin must run first in the babel pipeline.

**Acceptance Criteria:**
- [ ] `babel-plugin-react-compiler` installed
- [ ] React Compiler configured in `app.config.ts`
- [ ] `pnpm dev` starts without errors
- [ ] Optimized components show "Memo" badge in React DevTools
- [ ] Typecheck passes

## Step 4: Configure Code Quality Tools

**Commands:**
```bash
pnpm add -D jscpd react-doctor
```

Install temporal-polyfill for date/time handling:
```bash
pnpm add temporal-polyfill
```

**Acceptance Criteria:**
- [ ] jscpd installed
- [ ] react-doctor installed
- [ ] temporal-polyfill installed
- [ ] `jscpd.json` configured for TypeScript/TSX files
- [ ] `pnpm check:duplicates` runs jscpd
- [ ] `pnpm check:health` runs react-doctor
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
  "check:duplicates": "jscpd app convex",
  "check:health": "react-doctor"
}
```

Without Convex:
```json
{
  "check:duplicates": "jscpd app",
  "check:health": "react-doctor"
}
```

## Step 5: Set Up Testing Framework

**Commands:**
```bash
pnpm add -D vitest @vitest/ui @testing-library/react @testing-library/dom jsdom
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

**If E2E testing requested:**
```bash
pnpm add -D @playwright/test
pnpm dlx playwright install chromium
```

**Acceptance Criteria:**
- [ ] Vitest installed
- [ ] `vitest.config.ts` created with jsdom environment
- [ ] `pnpm test` runs Vitest
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

## Step 6: Set Up Convex Auth (Convex only)

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

## Step 7: Install Convex Workflow (Convex only, optional)

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

## Step 8: Configure AI Dependencies (Optional)

**Commands:**
```bash
pnpm add ai @ai-sdk/google
```

Or other providers:
```bash
pnpm add @ai-sdk/openai
pnpm add @ai-sdk/anthropic
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
    "dev": "pnpm run --parallel dev:frontend dev:backend",
    "dev:frontend": "vinxi dev",
    "dev:backend": "convex dev",
    "build": "vinxi build",
    "typecheck": "tsgo --noEmit",
    "lint": "oxlint",
    "format": "oxfmt --write .",
    "format:check": "oxfmt --check .",
    "test": "vitest run",
    "test:e2e": "playwright test",
    "check:duplicates": "jscpd app convex",
    "check:health": "react-doctor"
  }
}
```

**Without Convex:**

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
    "test:e2e": "playwright test",
    "check:duplicates": "jscpd app",
    "check:health": "react-doctor"
  }
}
```

## Verification Checklist

Run through these commands to verify setup is complete:

```bash
pnpm dev                    # Dev server(s) start
pnpm typecheck          # No type errors
pnpm lint                   # No lint errors
pnpm format                 # Format all files
pnpm format:check       # Verify formatting (CI)
pnpm test               # Unit tests pass
pnpm test:e2e           # E2E tests pass (if E2E enabled)
pnpm check:duplicates   # No problematic duplicates
pnpm check:health       # No code health issues
```
