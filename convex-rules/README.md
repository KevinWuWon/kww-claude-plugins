# convex-rules

A Claude Code plugin that provides rules and best practices for writing Convex backend code.

## Features

- Guidelines for Convex function syntax (queries, mutations, actions)
- Validator and schema patterns
- TypeScript best practices for Convex
- Query and mutation guidelines
- Scheduling and cron patterns
- File storage patterns

## Installation

```bash
# Test locally
claude --plugin-dir /path/to/convex

# Or add to your project's .claude/plugins
```

## Usage

The skill automatically triggers when:
- Working with files in the `convex/` directory
- Writing Convex queries, mutations, or actions
- Defining Convex schemas
- Asking about Convex patterns or best practices

## Structure

```
convex/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── convex/
│       ├── SKILL.md          # Core guidelines
│       └── examples/
│           └── chat-app.md   # Complete example app
└── README.md
```

## Example

Ask Claude about Convex patterns:
- "How do I define a Convex query?"
- "What's the correct syntax for a mutation?"
- "How do I set up pagination in Convex?"
- "Show me how to use internal functions"
