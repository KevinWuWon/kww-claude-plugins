# convex-chef

Convex backend development guidelines and best practices for Claude Code, extracted from [Chef](https://github.com/get-convex/chef).

## Features

### Convex Development Skill

Comprehensive guidelines for building Convex applications:

- **Function patterns**: query, mutation, action syntax and best practices
- **Schema design**: Tables, indexes, and TypeScript integration
- **Authentication**: @convex-dev/auth patterns
- **File storage**: Upload, retrieve, and manage files
- **Scheduling**: Crons and scheduled functions
- **Performance**: Limits and optimization strategies

**Triggers when you**:
- Write code in the `convex/` directory
- Ask about Convex functions, schemas, or patterns
- Need help with queries, mutations, or actions

### Convex Code Reviewer Agent

Proactive code reviewer that catches common Convex mistakes:

- Using `.filter()` instead of indexes
- Including `_creationTime` in custom indexes
- Missing argument validators
- Using `ctx.db` in actions
- Calling React hooks conditionally
- Wrong function references
- And more...

**Triggers automatically** after writing or editing Convex code.

## Installation

### From Plugin Directory

```bash
claude --plugin-dir /path/to/convex-chef
```

### Add to Project

Copy the plugin to your project:

```bash
cp -r convex-chef /your/project/.claude-plugins/
```

## Usage

The skill and agent activate automatically when relevant. No manual invocation needed.

### Example Workflow

1. Ask Claude to create a Convex query
2. Claude writes the code using the Convex skill guidelines
3. The convex-reviewer agent automatically reviews for issues
4. Any problems are reported with specific fixes

## Skill Reference Files

Detailed documentation in `skills/convex/references/`:

| File | Content |
|------|---------|
| `validators.md` | Complete validator reference table |
| `functions.md` | Function registration and calling patterns |
| `schema.md` | Schema design and index rules |
| `auth.md` | @convex-dev/auth patterns |
| `file-storage.md` | File upload and storage |
| `scheduling.md` | Crons and scheduled functions |
| `limits.md` | Performance limits |
| `examples.md` | Complete real-world examples |

## Credits

Knowledge extracted from [Chef](https://github.com/get-convex/chef), an AI-powered web app builder for Convex by the Convex team.
