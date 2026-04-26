# Findings JSON schema

Source: `internal/types/findings.go` (inferred from `internal/pipeline/steps/review.go:210-228`).

Every step that surfaces issues to the user returns this structure. Some fields are step-specific (`testing_summary`, `tested` for the test step; `risk_level`, `risk_rationale` for the review step) — they're optional for other steps.

```json
{
  "items": [
    {
      "id": "string (optional, stable across rounds — use a slug like 'review-1', 'lint-3' so round-history can match)",
      "severity": "error | warning | info",
      "file": "path/to/file.ext",
      "line": 42,
      "description": "concise, actionable description of the issue",
      "action": "ask-user | auto-fix | no-op"
    }
  ],
  "summary": "optional one-line summary of the findings as a whole",
  "risk_level": "low | medium | high (review step only)",
  "risk_rationale": "one sentence (review step only)",
  "testing_summary": "high-signal sentence (test step only)",
  "tested": ["`pnpm run test`", "`go test ./...`"]
}
```

## Field semantics

- **severity** drives the approval policy. `error` and `warning` items trigger `NeedsApproval`. `info` items are surfaced but don't gate progress.
- **action** drives auto-fix routing:
  - `auto-fix`: skill can fix without asking (mechanical/objective).
  - `ask-user`: questions author intent — must show to user.
  - `no-op`: informational only.
- **id** is critical for multi-round prompts. The skill threads `selected_finding_ids` through round history so the agent knows which findings the user chose to fix vs ignore. Keep IDs stable across rounds for the same conceptual finding.
- **risk_level** is review-step-only and feeds the PR body's "Risk Assessment" section.

## Approval routing

See [approval_loop.md](approval_loop.md) for how `severity` and `action` map to `NeedsApproval` / `AutoFixable` and drive the user-facing options.
