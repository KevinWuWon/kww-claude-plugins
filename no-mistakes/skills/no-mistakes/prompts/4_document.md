# Step 4: Document

Source: `internal/pipeline/steps/document.go`

## Skip if

No non-ignored files changed between `{base_sha}..{head_sha}`.

## BASE prompt (round 1, identify gaps only — no edits)

```
Review the code changes and identify any documentation gaps.

Context:
- branch: {branch}
- base commit: {base_sha}
- target commit: {head_sha}
- default branch: {default_branch}
- ignore patterns: {ignore_patterns}

Task:

1. Understand the change
   - Read the diff and changed files to understand what was added, modified, or removed.
   - Identify the intent and scope of the change (new feature, API change, config change, behavioral change, etc.).

2. Identify documentation gaps
   - Look for existing documentation files in the project: README.md, docs/, doc comments, config examples, etc.
   - Determine which docs are affected by the change. Common cases:
     - New or changed public APIs - update API docs, doc comments, or usage examples
     - New features or behaviors - update README or relevant guide
     - Changed configuration - update config docs or examples
     - Removed functionality - remove or update stale references

3. Return findings
    - Return a finding for each specific documentation gap (file, description of what needs updating).
    - If no documentation updates are needed (e.g., internal refactoring, test-only changes, or documentation is already up to date), return an empty findings array.
    - Do a full documentation pass before returning. Do not stop after the first documentation gap. Continue checking the rest of the affected docs until you have enumerated all specific gaps you can substantiate.

Rules:
- Do NOT make any file changes in this mode.
- Only report gaps where documentation is missing or stale relative to the code change.
- Set action to "auto-fix" for all findings. Documentation gaps are objective.{round_history}
```

## FIX prompt (round 2+, apply documentation updates)

```
Update any project documentation that needs to reflect the code changes.

Context:
- branch: {branch}
- base commit: {base_sha}
- target commit: {head_sha}
- default branch: {default_branch}
- ignore patterns: {ignore_patterns}

Task:
- Read the relevant diff and changed files yourself before editing.
- Update only the documentation directly affected by the change.
- Keep updates minimal and match the existing documentation style.

Rules:
- Only edit documentation files or doc comments.
- Do not change executable code or tests.
- Return JSON with a single "summary" field when you are done.
- The summary must be one concise sentence fragment suitable for a git commit subject.
- Keep the summary under 10 words.{round_history}

Previous documentation findings to address:
{previous_findings}
```

## Approval policy

Any non-empty findings array requires approval. If round-1 output is missing/unparseable, treat it as a single warning-severity ask-user finding.
