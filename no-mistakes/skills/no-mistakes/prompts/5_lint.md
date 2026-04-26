# Step 5: Lint

Source: `internal/pipeline/steps/lint.go`

## Two paths

If a project lint command is configured (e.g. `pnpm run lint`, `golangci-lint run`, `cargo clippy`), run it via Bash and only invoke the agent on failure (in fix mode). Otherwise use the BASE prompt to ask the agent to detect tools.

## BASE prompt (no lint command configured)

```
Detect the linting and formatting tools for this project and run the relevant checks yourself.

Context:
- branch: {branch}
- base commit: {base_sha}
- target commit: {head_sha}

Task:
- Discover the configured linters and formatters for this repository.
- Only lint or format the relevant changed files when possible.
- Report any issues found as structured findings.

Rules:
- Do not run tests or broader behavioral validation.
- Focus on lint, format, and static-analysis issues only.
- Set action to "auto-fix" for all findings. Lint findings are objective and do not question the author's intent.{round_history}
```

## FIX prompt

```
Fix the lint issues in this repository. Run the linter, identify all issues, and fix them.

Context:
- branch: {branch}
- base commit: {base_sha}
- target commit: {head_sha}

Rules:
- Make the minimal change needed.
- Do not refactor beyond what is needed.
- Do not run tests or broader behavioral validation.
- Re-run the relevant lint or format commands before finishing.
- Return JSON with a single "summary" field when you are done.
- The summary must be one concise sentence fragment suitable for a git commit subject.
- Keep the summary under 10 words.{round_history}{previous_findings_section}
```

## Approval policy

Any blocking findings (severity error/warning) require approval. Auto-fixable=true so the user can accept "Fix" in one click.
