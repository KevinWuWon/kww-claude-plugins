# Step 1: Rebase

Source: `internal/pipeline/steps/rebase.go`

## When to skip the agent entirely

Run these `git` commands first; only invoke the agent if conflicts arise:

1. `git fetch origin {default_branch}`
2. If branch differs from default: `git fetch origin {branch}`
3. For each rebase target (`origin/{branch}` then `origin/{default_branch}`, skipping ones not present, ones already-ancestor, or ones that fast-forward cleanly):
   - `git rebase <target>`
   - On conflict: collect conflicted files, abort the rebase (`git rebase --abort`), surface findings to the user via the approval loop. If the user picks `Fix`, send the FIX prompt below.

If all rebases succeed (or were no-ops), the step passes with no agent invocation. Update `{head_sha}` to the new HEAD and proceed.

If the post-rebase diff against `{default_branch}` is empty, the branch was already merged — set `SkipRemaining=true` and stop the pipeline cleanly.

## FIX prompt (sent only when there are merge conflicts)

```
Resolve git rebase conflicts. The rebase of the current branch onto {target_ref} has conflicts.

Current conflicted files:
- {conflict_files_newline_dash_separated}

Instructions:
- Find all conflicting files and resolve the conflict markers (<<<<<<< ======= >>>>>>>).
- After resolving each file, stage it with: git add <file>
- After all conflicts are resolved, run: git rebase --continue
- If additional conflicts arise during rebase --continue, resolve those too.
- Do not modify any files that don't have conflicts.
- Preserve the intent of both the current branch changes and the upstream changes.
- Return JSON with a single "summary" field describing what you resolved.
- Keep the summary under 10 words.{previous_findings_section}
```

## Expected JSON output

```json
{ "summary": "merge conflict in foo.go resolved" }
```

After the agent finishes, verify no rebase is still in progress (check `git rev-parse --git-path rebase-merge` and `rebase-apply`). If a rebase is mid-flight, abort it and treat as a step failure.

## Findings shape (when surfacing conflicts to the user)

```json
{
  "items": [
    {
      "severity": "warning",
      "file": "<path>",
      "description": "merge conflict rebasing onto {target_ref}"
    }
  ],
  "summary": "conflict rebasing onto {targets_comma_separated}"
}
```
