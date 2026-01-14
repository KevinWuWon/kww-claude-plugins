---
name: codex
description: Consult OpenAI Codex for analysis, review, or research
argument-hint: "<question or request>"
allowed-tools: ["Bash"]
---
Consult Codex with the user's question or request.

- Run: `codex exec "PROMPT"`

It has access to the filesystem and git so you don't need to read the files for it; it can gather context itself.