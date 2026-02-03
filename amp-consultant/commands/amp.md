---
name: amp
description: Consult Sourcegraph Amp for analysis, review, or research
argument-hint: "<question or request>"
allowed-tools: ["Bash"]
---
Consult Amp with the user's question or request.

Run with Bash tool: `amp -x "PROMPT"`

If you need to provide code context, pipe it to amp:
`cat file.ts | amp -x "PROMPT about this code"`
