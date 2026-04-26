# Step 3: Test

Source: `internal/pipeline/steps/test.go`

## Two paths

If a project test command is configured (e.g. `pnpm run test`), run it directly via Bash and only invoke the agent on failure (in fix mode). Otherwise (no command configured) ask the agent to discover and run the relevant tests itself with the BASE prompt.

The skill should detect a configured test command by checking, in order: project `package.json#scripts.test`, `Makefile` `test` target, `cargo test`, `go test`, `pytest`. If none match cleanly, use the BASE prompt.

## BASE prompt (no test command configured, or initial discovery)

```
You are validating a code change by testing it. Examine the repository and run the appropriate tests yourself.

Context:
- branch: {branch}
- base commit: {base_sha}
- target commit: {head_sha}

Task:
- Understand the change before testing it.
- Run existing tests that are relevant to the change.
- Writing and running new tests if coverage is insufficient.
- Include a concise "testing_summary" sentence describing what you exercised and the overall result.
- Record the exact tests you ran in a "tested" array. Prefer concrete commands or test selectors wrapped in backticks.
- If tests fail, determine whether the problem is a real product/code failure, a setup/environment problem you can fix, or a flaky/infrastructure issue.
- If the issue is setup-related and fixable, fix it and retry the tests.

Rules:
- Do NOT run linters, formatters, or static analysis tools.
- Focus on testing and test-related fixes only.
- Keep "testing_summary" high-signal and natural language. Avoid raw logs and noisy counts.
- Always return a non-empty "tested" array describing what you exercised, even when all tests pass.
- Only report actionable findings: test failures, unfixable setup issues, or flaky tests you identified.
- Do NOT report passing tests (whether existing or new), test counts, coverage summaries, or other non-actionable information.
- If all tests pass and there are no issues, return an empty findings array.
- Set action to "ask-user" only when a test failure seems desired and you question the author's intent of having the test in the first place. Set action to "auto-fix" for objective test failures that can be safely fixed. Set action to "no-op" for informational notes.{round_history}
```

## FIX prompt (round 2+, or when configured test command exits non-zero)

```
Fix the failing tests in this repository. Run the tests, identify failures, and fix either the tests or the code to make them pass.

Context:
- branch: {branch}
- base commit: {base_sha}
- target commit: {head_sha}

Rules:
- Make the minimal change needed.
- Do not refactor beyond what is needed.
- If tests fail, determine whether the problem is a real product/code failure, a setup/environment problem you can fix, or a flaky/infrastructure issue.
- Do NOT run linters, formatters, or static analysis tools.
- Re-run the relevant tests before finishing.
- Return JSON with a single "summary" field when you are done.
- The summary must be one concise sentence fragment suitable for a git commit subject.
- Keep the summary under 10 words.{round_history}{previous_findings_section}
```

## Special: agent wrote new test files

After the agent runs (in either mode), check `git status --porcelain` for new test files (heuristic: paths containing `test`, `spec`, `__tests__`). If any are detected, force `NeedsApproval=true` even if all assertions pass — the user should review the new tests.

## Expected JSON output

Findings object plus optional `testing_summary` and `tested` arrays. See [reference/findings_schema.md](../reference/findings_schema.md).
