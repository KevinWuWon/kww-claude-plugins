# Modern Web Stack - Technology Details

## Core Framework

### TanStack Start

Full-stack React framework with file-based routing and SSR.

- Routes defined in `app/routes/` directory
- Automatic route type generation
- Built-in devtools for debugging
- Powered by Vinxi (Vite-based)

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

### shadcn/ui

Headless component library built on Radix UI primitives.

- Copy-paste components (you own the code)
- Accessible Radix UI primitives
- Tailwind CSS styling

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

### Bun

JavaScript runtime and package manager.

**Commands:**
- `bun install` - Install dependencies
- `bun add <pkg>` - Add dependency
- `bun add -D <pkg>` - Add dev dependency
- `bun run <script>` - Run package.json script

### Biome

Fast linter and formatter (replaces ESLint + Prettier).

**Configuration:** `biome.json`

### TypeScript

Strict TypeScript configuration.

**Key Settings:**
- `strict: true`
- `noUnusedLocals: true`
- `noUnusedParameters: true`
- Path aliases (`@/*` → `./app/*`)

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

### knip

Dead code detection. **Configuration:** `knip.json`

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
