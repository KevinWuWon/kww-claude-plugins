---
name: codex
description: Consult OpenAI Codex for analysis, review, or research
argument-hint: "<question or request>"
allowed-tools: ["Bash"]
---
Consult Codex with the user's question or request.

If it's a code review request:
- Run with Bash tool: `codex review [<args>] [<prompt>]` where args is --uncommitted | --base | --commit

If it's a general request:
- Run with Bash tool: `codex exec "PROMPT"`