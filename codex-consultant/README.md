# codex-consultant

Consult OpenAI's Codex CLI for second opinions on code review, architecture analysis, debugging, and technical research.

## Features

- **Agent**: `codex-consultant` - Triggered when you ask Claude to consult Codex
- **Command**: `/codex <question>` - Directly ask Codex a question

## Prerequisites

- [Codex CLI](https://github.com/openai/codex) installed and configured
- Valid OpenAI API key configured in Codex

## Usage

### Via Agent

Ask Claude to consult Codex:

```
"Ask codex what it thinks about this implementation"
"Get codex to review this function"
"What does codex think about this architecture?"
"Get a second opinion from codex"
```

### Via Command

```
/codex What's the best way to handle this error case?
/codex Review the authentication flow in src/auth/
/codex Is there a potential race condition in this code?
```

## How It Works

1. Gathers relevant code context from your project
2. Formulates a comprehensive prompt
3. Executes `codex exec -p "prompt"`
4. Presents Codex's analysis with recommendations

## Configuration

The plugin uses your Codex CLI's default configuration (`~/.codex/config.toml`). To change the model or other settings, update your Codex config.
