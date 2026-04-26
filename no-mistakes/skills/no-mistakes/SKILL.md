---
name: no-mistakes
description: Run the full pre-merge pipeline on the current git branch — rebase, code review, tests, documentation, lint, push, open/update a PR, and (optionally) watch CI — with auto-fix loops and human approval gates between steps. Use whenever the user says they want to ship a branch, open or update a PR, "run pre-merge checks", "make sure this is ready to merge", "no mistakes", or otherwise asks for a thorough end-to-end pre-merge sweep on a feature branch. Prefer this over running review/test/lint individually when the user's intent is to land the change.
---

# no-mistakes

Runs an opinionated 8-step pre-merge pipeline against the current branch.

## Architecture

Spawn a **fresh general-purpose Agent for each step that needs one**. The prompts in `prompts/<N>_<step>.md` are self-contained — they read the diff, run the relevant commands, and return structured findings. Cross-step context is not preserved between agents; this is intentional. The earlier "one persistent sub-agent + SendMessage" design was unreliable in practice (the persistent agent silently stalled on inbox messages) and the cross-step context win was small because every prompt re-reads what it needs anyway.

```
Agent({subagent_type: "general-purpose", prompt: <step N prompt>})
```

Several steps don't need an agent at all — run them directly with Bash and only invoke an agent on failure (in fix mode):
- Step 1 (Rebase) — pure git
- Step 3 (Test) — the project's configured test command (detected per [prompts/3_test.md](prompts/3_test.md): `package.json#scripts.test`, `Makefile`, `cargo test`, `go test`, `pytest`)
- Step 5 (Lint) — the project's configured lint command (detected per [prompts/5_lint.md](prompts/5_lint.md))
- Step 6 (Push) — pure git
- Step 8 (CI) — `gh pr checks` polling

## The 8 steps

| # | Step | Prompt file | Skip if |
|---|------|-------------|---------|
| 1 | Rebase | [prompts/1_rebase.md](prompts/1_rebase.md) | branch is up to date with `origin/<default>` and `origin/<branch>` |
| 2 | Review | [prompts/2_review.md](prompts/2_review.md) | no reviewable file changes after ignore patterns |
| 3 | Test | [prompts/3_test.md](prompts/3_test.md) | never |
| 4 | Document | [prompts/4_document.md](prompts/4_document.md) | no non-ignored files changed |
| 5 | Lint | [prompts/5_lint.md](prompts/5_lint.md) | never |
| 6 | Push | [prompts/6_push.md](prompts/6_push.md) | nothing to push (HEAD == upstream) |
| 7 | PR | [prompts/7_pr.md](prompts/7_pr.md) | branch is the default branch, or no SCM provider configured |
| 8 | CI | [prompts/8_ci.md](prompts/8_ci.md) | no PR was created/updated in step 7 |

## The per-step approval loop

Steps 1–5 and 7 follow the same loop, fully specified in [reference/approval_loop.md](reference/approval_loop.md):

```
send prompt → parse findings → if blocking, ask user (Approve/Fix/Skip/Abort) → on Fix, send fix prompt → max 3 rounds
```

**Step exceptions:**
- **Step 6 (push)** runs without approval — the user already chose to run no-mistakes, which implies wanting to push. See [prompts/6_push.md](prompts/6_push.md).
- **Step 8 (CI)** asks once at the start whether to enable auto-fix mode, then polls without per-fix approvals. See [prompts/8_ci.md](prompts/8_ci.md).

## Running the skill

1. **Handle uncommitted changes.** Run `git status --porcelain` from the worktree.
   - If clean, continue.
   - If there are uncommitted changes (staged, unstaged, or untracked) **and they were produced by edits in the current conversation**, stage them with `git add` (specific paths, not `-A`/`.` — skip anything that looks like a secret: `.env*`, `*credentials*`, `*.pem`, `*.key`) and create a single commit summarizing the change. Use a HEREDOC commit message ending with the standard `Co-Authored-By: Claude` trailer. Do not amend. Then continue automatically — do not prompt the user.
   - If there are uncommitted changes that did **not** come from this conversation (e.g. pre-existing dirty worktree), stop and ask the user how to proceed. Do not commit them.
2. Run `bash scripts/preflight.sh` from the worktree. It exits non-zero on the default branch or outside a git repo. Parse its JSON output to get all placeholders (`branch`, `default_branch`, `base_sha`, `head_sha`, `upstream`, `review_scope`, `has_diff`, `ignore_patterns`).
3. If `has_diff` is `false`, tell the user there's nothing to ship and exit.
4. Walk through steps 1–8. For each step that requires an agent (Review, Document, fix-mode of Test/Lint, PR-summary), spawn a fresh `Agent({subagent_type: "general-purpose", prompt})` with the step's prompt fully substituted. Bash-only steps (Rebase, Test, Lint, Push, CI poll) run directly. Track per-step status in skill memory.
5. Print the run summary (see "What the user sees" below).

## Placeholders

Substituted into every prompt before sending. Most come from `scripts/preflight.sh`; a few are computed per-round:

| Placeholder | Source |
|-------------|--------|
| `{branch}`, `{default_branch}`, `{base_sha}`, `{head_sha}`, `{upstream}`, `{ignore_patterns}` | preflight JSON |
| `{review_scope}` | preflight JSON, but in fix mode use `current worktree and HEAD changes relative to base commit {base_sha} (starting head {head_sha})` |
| `{round_history}` | empty on round 1; on round 2+ the formatted block — see [reference/approval_loop.md](reference/approval_loop.md) |
| `{previous_findings}` | empty on round 1; on round 2+ the JSON of round N-1's findings |
| `{previous_findings_section}` | empty string on round 1; on round 2+ the literal block `\n\nPrevious <step> findings to address:\n{previous_findings}` |

## What the user sees

Print a single status line as each step starts. Stream the agent's brief progress notes inline. At the end, print one summary block:

```
no-mistakes summary
  rebase    ✓ skipped (already up to date)
  review    ⚠ 2 warnings approved as-is (medium risk)
  test      ✓ passed (4 specs)
  document  ✓ no gaps
  lint      🔧 3 issues auto-fixed (round 2)
  push      ✓ pushed to origin/feature-x
  pr        ✓ https://github.com/.../pull/123
  ci        ✓ all checks passed
```
