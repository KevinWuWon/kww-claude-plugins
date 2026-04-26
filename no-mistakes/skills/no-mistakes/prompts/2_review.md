# Step 2: Review

Source: `internal/pipeline/steps/review.go`

## Skip if

After applying ignore patterns, no files changed between `{base_sha}..{head_sha}`. In that case emit empty findings with `risk_level: "low"`, `risk_rationale: "no reviewable changes"`, and proceed.

## BASE prompt (round 1)

```
Review the code changes and return structured findings with a risk assessment.

Context:
- branch: {branch}
- base commit: {base_sha}
- target commit: {head_sha}
- review scope: {review_scope}
- default branch: {default_branch}
- ignore patterns: {ignore_patterns}

Task:
- Read the relevant history and diff yourself.
- focus only on changed code.
- Do NOT run tests during review. The pipeline has a dedicated test step after review.
- Analyze for bugs, risks, and code simplification opportunities.
- "Simplification" means reducing code complexity through non-functional refactoring (e.g. deduplication, clearer control flow). It does NOT mean removing features, changing product behavior, or stripping intentional user-facing output.
- Treat security issues, performance regressions, breaking changes, and insufficient error handling as risks.
- Do a full review pass before returning. Do not stop after the first valid finding. Continue inspecting the rest of the changed code until you have enumerated all material issues you can substantiate.

Rules:
- Anchor every finding to a specific file and one-indexed line number in the changed code when possible.
- Use severity "error" for problems that should absolutely not get merged, "warning" for things that are worth addressing but can be done in a follow up, and "info" for things that are nice to have.
- Be concise and actionable. No generic advice like "add more tests".
- Only comment on things that genuinely matter.
- Do NOT report styling, formatting, linting, compilation, or type-checking issues.
- If the change is clean, return an empty findings array.
- For each finding, set the action field to one of:
  - "ask-user": the finding is about functional requirements or product behavior, or otherwise challenges the author's deliberate intent. Even if it seems obviously wrong, we should ask the user for review. Examples: "this feature seems unnecessary", "this hardcoded value should be configurable", "this deletion looks wrong". When in doubt, default to "ask-user".
  - "auto-fix": the finding is a non-funcitonal, non user-visible issue (correctness, error handling, security, performance, mechanical code quality) that can be safely fixed without any discussion about the author's intent.
  - "no-op": the finding is informational and does not require any action (e.g. noting a pattern, acknowledging a tradeoff).

Risk assessment (after listing all findings):
- Set risk_level to "low" if the change is well-bounded, mostly cosmetic, or straightforward with little ambiguity.
- Set risk_level to "medium" if the change has room to improve but is safe to merge first with concerns addressed as follow-ups.
- Set risk_level to "high" if the change should not be merged without explicit human approval - it is fundamental, risky, ambiguous, or has strong negative signals.
- Provide a one-sentence risk_rationale explaining why you chose that risk level.{round_history}
```

## FIX prompt (round 2+, when user picks "Fix")

When fixing, change `{review_scope}` to: `current worktree and HEAD changes relative to base commit {base_sha} (starting head {head_sha})`

```
Investigate previous review findings and address legitimate ones.

Examine the relevant code yourself and apply fixes directly.

Context:
- branch: {branch}
- base commit: {base_sha}
- target commit: {head_sha}
- review scope: {review_scope}
- default branch: {default_branch}
- ignore patterns: {ignore_patterns}

Rules:
- Always start with double checking whether the findings are legitimate.
- Avoid resolving a finding by removing or reverting the author's intentional code in their original 1st commit. If the original change introduced something on purpose, fix it forward (e.g. add validation, handle edge cases, tighten logic) rather than deleting it. Similarly, if the original change intentionally deleted or simplified code, do not restore or re-add the removed code unless the finding is a legitimate correctness, reliability, or security issue and the smallest reasonable fix happens to reintroduce a small amount of previously deleted logic. When in doubt about whether code is intentional, leave it and report the finding as unresolved.
- Do not add code comments explaining your fixes.
- Verify that the issues are resolved before finishing.
- Return JSON with a single "summary" field when you are done.
- The summary must be one concise sentence fragment suitable for a git commit subject.
- Keep the summary under 10 words.{round_history}

Previous review findings to address:
{previous_findings}
```

## Expected JSON output

Round 1: full Findings object (see [reference/findings_schema.md](../reference/findings_schema.md)).
Round 2+ (fix): `{ "summary": "<<10 words>" }`.

## Approval policy

A finding's `severity` of `error` or `warning` triggers approval. After fix mode, re-run the BASE prompt with `{review_scope}` set to fix-mode value to verify resolution.
