# Step 7: PR

Source: `internal/pipeline/steps/pr.go`, `prsummary.go`

## Skip if

- `{branch}` equals `{default_branch}`.
- No SCM provider detected from the upstream URL (or `gh` CLI not available).

## Detect provider

Use `gh` (GitHub) when `git remote get-url origin` matches `github.com`. v1 only supports GitHub; skip for other providers with a log message.

## Find existing PR

```sh
gh pr list --head {branch} --state open --json number,url,title --limit 1
```

If a PR exists: update its body via `gh pr edit <number> --title "..." --body "..."`. Otherwise create one with `gh pr create`.

## BASE prompt (draft title and body)

Inputs to gather first via Bash:
- `commit_log` = `git log --oneline {base_sha}..{head_sha}`
- `diff_stat` = `git diff --stat {base_sha}..{head_sha}`
- `pipeline_md` = a markdown summary of step results (rebase/review/test/document/lint outcomes; see "Pipeline section" below)

```
Draft a pull request title and summary for the full branch delta.

Context:
- branch: {branch}
- base commit: {base_sha}
- target commit: {head_sha}
- default branch: {default_branch}

Rules:
- Cover the full branch delta, not just the latest commit.
- Title must use conventional commit format: "type(scope): description" or "type: description". Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert. Scope is optional. Do not capitalize the type. Do not use the raw branch name.
- When including a scope, it MUST be a real package/module name that exists in the codebase (for example, a directory under internal/, cmd/, or the equivalent top-level grouping for this project), identified by inspecting the changed paths. Pick the primary module affected by the change, not a secondary or incidental one.
- Keep the scope at a coarse level, not too granular: a codebase typically has fewer than 10 distinct scopes in use across its history. Prefer a broad module name (e.g. "daemon", "pipeline", "cli") over a narrow file or sub-feature name. If you cannot confidently identify a real primary module, omit the scope and use "type: description".
- Body: a "## Summary" section in GitHub-flavored markdown. 1-3 concise bullet points describing what changed and why. Do not include Risk Assessment, Testing, or Pipeline sections - those are appended separately. The body value must be plain markdown text, never a JSON object or serialized JSON string.
- Do not invent tests or behavior.

Commit history:
{commit_log}

Diff stat:
{diff_stat}

Pipeline results (reference these naturally in the summary if relevant):
{pipeline_md}
```

## Expected JSON output

```json
{
  "title": "feat(pipeline): rerun review after auto-fix",
  "body": "## Summary\n\n- ...\n- ..."
}
```

## Pipeline section (appended deterministically)

After the agent returns, the skill appends three deterministic sections to `body`:

```markdown

## Risk Assessment

{emoji} {Risk level capitalized}: {rationale from review step's risk_rationale}

## Testing

- Summary: {testing_summary from test step}
- `{tested[0]}`
- `{tested[1]}`
...
- Outcome: passed across N runs (Ms)

## Pipeline

Updates from [no-mistakes (in-line)](https://github.com/kunchenguid/no-mistakes)

<details>
<summary>{step_status_emoji} **Rebase** - {short_status}</summary>
... per-round details
</details>

<details>
<summary>{step_status_emoji} **Review** - {short_status}</summary>
... per-round details with severity emojis
</details>
... etc per non-PR/CI step
```

Risk emojis: low → ✅, medium → ⚠️, high → 🚨.
Severity emojis: error → 🚨, warning → ⚠️, info → ℹ️.
Step status emojis: passed → ✅, fixed → 🔧, ⚠️ for warnings/issues, ⏭️ skipped, ❌ failed.

Strip any of these section headings the agent might have included before appending the deterministic versions: "Risk Assessment", "Testing", "Tests", "Pipeline".

If the agent's title doesn't match `^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([^)]+\))?!?: .+`, prepend `chore: ` as a fallback.

## Approval policy

**Always show the rendered title + body to the user via `AskUserQuestion`** before running `gh pr create`/`gh pr edit`:

```
options: Approve and post / Edit (pop the body in $EDITOR or accept user-provided edits in chat) / Skip / Abort
```

Save the resulting PR URL for step 8 (CI watch).
