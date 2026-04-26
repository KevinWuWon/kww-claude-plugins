# Step 8: CI

Source: `internal/pipeline/steps/ci.go`, `ci_fix.go`

## Skip if

No PR URL was set in step 7.

## Loop overview

Poll CI on the PR until one of: all checks pass, PR merged, PR closed, or timeout (default 4 hours, but for in-line skill default is **30 minutes** since the user is waiting in-chat).

```
loop:
  1. Check PR state (gh pr view --json state,mergeable,mergeStateStatus)
     - merged → exit success
     - closed → exit (warn user)
  2. Check CI checks (gh pr checks <pr_number> --json name,state,bucket)
     - all pass + no merge conflict → exit success
     - any pending → wait poll_interval, loop
     - any failed → either auto-fix (FIX prompt) or surface to user
  3. Sleep poll_interval (start at 10s, back off to 60s after first 5 polls)
```

Ask the user via `AskUserQuestion` once at start whether to enable auto-fix:
```
question: "Watch CI on PR #{number}? Auto-fix failing checks if they appear?"
options:
  - Watch and auto-fix (max 2 attempts) [recommended]
  - Watch only (notify on completion)
  - Skip CI watch
```

## FIX prompt (when CI fails and user opted into auto-fix)

Inputs:
- `pr_number`
- `failing_checks` = comma-separated names from `gh pr checks`
- `merge_conflict` = boolean from `mergeStateStatus == "DIRTY"`
- `ci_logs` = first 32KB of failed-check logs via `gh run view <run_id> --log-failed` for each failing check

Choose intro/rules block based on what's failing:

### Both checks failing AND merge conflict
```
The following CI checks have failed and the PR has merge conflicts with the base branch. Diagnose and fix the CI issues, then rebase onto the base branch and resolve the merge conflicts.

Context:
- branch: {branch}
- base commit: {base_sha}
- target commit: {head_sha}
- PR number: {pr_number}
- failing checks: {failing_checks}
- merge conflict: true

Rules:
- You MUST produce file changes that fix the failing checks. Do not conclude that nothing needs to change.
- If a test fails only on a specific OS (e.g. Windows CRLF, path separators), fix the test to be cross-platform.
- If a test is flaky, make it deterministic.
- Make the minimal change needed.
- Do not refactor beyond what is needed.
- Verify the fix by running the most relevant commands locally before finishing.
- rebase target commit: {rebase_target_sha}

CI logs:
{ci_logs}
```

### Merge conflict only
```
The PR has merge conflicts with the base branch. Rebase onto the base branch and resolve the merge conflicts.

Context:
- branch: {branch}
- base commit: {base_sha}
- target commit: {head_sha}
- PR number: {pr_number}
- failing checks: 
- merge conflict: true

Rules:
- Resolve the merge conflicts by applying the minimal necessary changes.
- Do not make unrelated file edits.
- Verify the rebase completes cleanly before finishing.
- rebase target commit: {rebase_target_sha}
```

### Checks failing only
```
The following CI checks have failed on this PR. Diagnose and fix the issues.

Context:
- branch: {branch}
- base commit: {base_sha}
- target commit: {head_sha}
- PR number: {pr_number}
- failing checks: {failing_checks}
- merge conflict: false

Rules:
- You MUST produce file changes that fix the failing checks. Do not conclude that nothing needs to change.
- If a test fails only on a specific OS (e.g. Windows CRLF, path separators), fix the test to be cross-platform.
- If a test is flaky, make it deterministic.
- Make the minimal change needed.
- Do not refactor beyond what is needed.
- Verify the fix by running the most relevant commands locally before finishing.

CI logs:
{ci_logs}
```

## Post-fix

After the agent finishes:
1. `git status --porcelain` — if empty, fix produced no changes; surface to user as "auto-fix failed" and exit the loop.
2. Otherwise: `git add -A && git commit -m "no-mistakes: apply CI fixes"`, then `git push --force-with-lease`.
3. Resume polling.

Track `last_fixed_checks` (sorted comma-joined names) so the same failure isn't re-attempted while CI re-runs. Increment an attempt counter; stop after 2 auto-fix attempts and surface to user.

## Approval policy

User approval was collected at step start (auto-fix mode toggle). No per-fix approval inside the loop — that defeats the purpose of "watch and auto-fix." But on each terminal exit (failure, timeout, merge conflict that can't be resolved), surface the state to the user with `AskUserQuestion` for next-step decision: retry / give up / open PR in browser.
