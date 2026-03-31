# Modern Web Stack - Technology Details

## Core Framework

### TanStack Start

Full-stack React framework with file-based routing and SSR.

- Routes defined in `app/routes/` directory
- Automatic route type generation
- Built-in devtools for debugging
- Powered by Vinxi (Vite-based)

**CLI:** `pnpm dlx @tanstack/cli create`

### React

Latest React with concurrent features and new JSX transform.

## Backend (Optional)

Convex is optional. Use it when the app needs data persistence, auth, or workflows. Skip it for apps that only make API calls without storing data.

### Convex

Real-time backend-as-a-service with TypeScript-first design.

**Key Components:**
- `convex/schema.ts` - Database schema definition
- `convex/_generated/` - Auto-generated types and API
- Queries, mutations, and actions for data operations
- File storage for media assets
- Real-time subscriptions

### Convex Auth

Authentication component for Convex.

**Supported Providers:** Google OAuth, GitHub OAuth, Email/password, Anonymous auth

**Setup:** `npx convex component add @convex-dev/auth`

### Convex Workflow

Durable workflow orchestration for multi-step pipelines.

**Use Cases:** Long-running operations, multi-step pipelines with retry logic, operations exceeding action timeouts

**Setup:** `npx convex component add @convex-dev/workflow`

### Without Convex

TanStack Start provides server functions for API calls without a database:
- Use `app/server/` directory for server-side code
- Call external APIs (AI services, etc.) from server functions
- No data persistence between requests

## UI Layer

### shadcn/ui (Base UI)

Headless component library using Base UI primitives instead of Radix UI.

- Copy-paste components (you own the code)
- `@base-ui-components/react` as the primitive layer (replaces `@radix-ui/*`)
- Tailwind CSS styling

**Setup:** After `pnpm dlx @tanstack/cli create`, reinitialize with Base UI style:
```bash
pnpm dlx shadcn@latest init --style base-ui-tw
```
Remove any `@radix-ui/*` packages that the TanStack CLI may have installed.

**Key Utilities:**
- `class-variance-authority` (CVA) for variant management
- `clsx` + `tailwind-merge` for conditional classes
- `lucide-react` for icons

### Tailwind CSS

Utility-first CSS framework.

- New engine with CSS-first configuration
- oklch color space support
- Native dark mode
- Integration via `@tailwindcss/vite` plugin

## Development Tools

### pnpm

Fast, disk-space-efficient package manager.

**Commands:**
- `pnpm install` - Install dependencies
- `pnpm add <pkg>` - Add dependency
- `pnpm add -D <pkg>` - Add dev dependency
- `pnpm run <script>` - Run package.json script

### oxfmt

Rust-powered JavaScript/TypeScript formatter from the oxc project. Prettier-compatible with built-in import sorting and Tailwind CSS class sorting.

**Configuration:** `.oxfmtrc.jsonc`

**Key Features:**
- Default `printWidth: 100` (better for TypeScript than Prettier's 80)
- Built-in import sorting (`experimentalSortImports`)
- Built-in Tailwind class sorting (`experimentalTailwindcss`)
- Reads `.editorconfig` properties

### oxlint

Rust-powered JavaScript/TypeScript linter from the oxc project. 50-100x faster than ESLint.

**Configuration:** `oxlint.config.ts` (TypeScript config file with `defineConfig`)

**Key Features:**
- @nkzw/oxlint-config provides strict, opinionated defaults
- ESLint plugins can be used via `jsPlugins` field (https://oxc.rs/docs/guide/usage/linter/js-plugins.html)
- Reserved plugin names (react, import, jest, typescript) need aliases for JS versions
- Type-aware linting with `--type-aware --type-check`

### tsgo (TypeScript Native)

Native TypeScript compiler (~10x faster than tsc). Drop-in replacement.

**Package:** `@typescript/native-preview`
**Command:** `tsgo --noEmit` (replaces `tsc --noEmit`)

**Key Settings:**
- `strict: true`
- `noUnusedLocals: true`
- `noUnusedParameters: true`
- Path aliases (e.g. `@/*` → `./app/*`)

### React Compiler

Automatically optimizes React components by memoizing values and callbacks. Eliminates manual `useMemo`, `useCallback`, and `React.memo`.

**Package:** `babel-plugin-react-compiler`
**Configuration:** Add to babel plugins in `app.config.ts` (TanStack Start) or `vite.config.ts` (Vite)
**Verification:** Optimized components show "Memo" badge in React DevTools

## Testing

### Vitest

Unit and integration testing framework.

- Vite-native configuration
- jsdom environment for React testing
- `@testing-library/react` integration

### Playwright

End-to-end testing framework.

**Configuration:** `playwright.config.ts`

## Code Quality

### jscpd

Copy-paste detection. **Configuration:** `jscpd.json`

### react-doctor

React code health analysis from Million.js. Checks for dead code, 47+ best practice rules, and common React anti-patterns. No configuration file needed.

### temporal-polyfill

TC39 Temporal API polyfill for date/time handling (~20kB). Spec-compliant replacement for date-fns/dayjs/moment. Use `Temporal.PlainDate`, `Temporal.ZonedDateTime`, `Temporal.Duration`, etc.

## AI Integration (Optional)

### Vercel AI SDK

Unified API for AI model providers.

**Key Functions:**
- `generateText` - Text generation
- `generateObject` - Structured output with Zod schemas
- Streaming support

**Providers:** `@ai-sdk/google`, `@ai-sdk/openai`, `@ai-sdk/anthropic`

## Deployment

### Vercel

- Native TanStack Start support
- With Convex: Deploy separately via `npx convex deploy`, set `CONVEX_DEPLOY_KEY` in Vercel environment
- Without Convex: Standard Vercel deployment
