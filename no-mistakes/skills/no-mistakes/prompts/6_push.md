# Step 6: Push

Source: `internal/pipeline/steps/push.go`

This step is **mostly mechanical** — no agent invocation unless something fails. Do it directly with Bash:

1. **Run the project's format command if configured** (e.g. `pnpm run fix`). This is best-effort; warn on failure but do not abort.
2. **Commit any uncommitted agent fixes**:
   ```sh
   git status --porcelain
   # if non-empty:
   git add -A
   git commit -m "no-mistakes: apply agent fixes"
   ```
3. **Resolve upstream**: read the project's `git remote get-url origin` (or the appropriate upstream remote — `origin` is fine for v1).
4. **Determine the upstream branch SHA** with `git ls-remote <upstream> refs/heads/{branch}`.
5. **Push**:
   - If branch exists upstream: `git push --force-with-lease=refs/heads/{branch}:<expected_sha> <upstream> HEAD:refs/heads/{branch}` (use the explicit SHA form so `--force-with-lease` actually protects against races).
   - If branch is new: `git push -u <upstream> HEAD:refs/heads/{branch}` (no force needed).

## Approval policy

**No approval gate.** The user invoked no-mistakes intending to ship; ask once at skill start (or never) rather than mid-pipeline. Just push.

## Failure handling

- Format command failure → log a warning, continue.
- Commit failure → abort the pipeline.
- Push failure (non-fast-forward, etc.) → ask the user via `AskUserQuestion` whether to: re-run the rebase step, force-push anyway, or abort.

No agent invocation is required for this step in v1.
