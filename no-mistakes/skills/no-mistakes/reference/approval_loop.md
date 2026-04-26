# Per-step approval loop

This is the same loop for every step (1-5 and 7). Step 6 (push) and step 8 (CI) have step-specific variants documented in their own files.

## Pseudocode

```
function runStep(step):
  round = 1
  selected_finding_ids = []
  history = []  // accumulated round records, formatted into {round_history} placeholder

  while round <= MAX_ROUNDS (default 3):
    if round == 1:
      prompt = step.basePrompt({round_history: format(history)})
    else:
      prompt = step.fixPrompt({
        round_history: format(history),
        previous_findings: JSON.stringify(history.last.findings)
      })

    response = Agent({subagent_type: "general-purpose", prompt})

    findings = parseFindings(response)  // schema in findings_schema.md

    blocking = findings.items.filter(i => i.severity in ["error", "warning"])
    autofixable = findings.items.some(i => i.action == "auto-fix")

    if blocking.length == 0 && !specialFlag(findings, step):
      return {status: "passed", findings, fix_summary_chain: history.map(h => h.fix_summary)}

    // Surface to user
    options = ["Approve", "Skip", "Abort"]
    if autofixable && round < MAX_ROUNDS:
      options.unshift("Fix (round " + (round+1) + " of " + MAX_ROUNDS + ")")

    answer = AskUserQuestion({
      question: `${step.name} found ${findings.items.length} issue(s) [round ${round}]. ` +
                renderFindingsBrief(findings) +  // first 5 items, severity + file:line + description
                ` What do you want to do?`,
      options: options.map(label => ({label, description: ""})),
    })

    if answer == "Abort":
      return {status: "aborted"}
    if answer == "Skip":
      return {status: "skipped", findings}
    if answer == "Approve":
      return {status: "approved-with-findings", findings}
    if answer.startsWith("Fix"):
      // Record this round so the next round's prompt has history
      selected_finding_ids = autoFixableFindingIds(findings)  // or all blocking ids
      history.push({
        round, trigger: round == 1 ? "initial" : "auto_fix",
        findings, selection_source: "auto_fix",
        selected_finding_ids,
      })
      round += 1
      continue

  // Hit MAX_ROUNDS without resolution
  return {status: "max-rounds-exceeded", findings: history.last.findings}
```

## `format(history)` — the round-history block

Mirrors `internal/pipeline/steps/round_history.go:21-46`. If history is empty, return empty string. Otherwise:

```
\n\nPrevious rounds for this step (for your awareness):
Use this to avoid repeating work you already tried. Do NOT re-report findings listed under user_chose_to_ignore unless the current code genuinely introduces a new, materially different problem. Treat this entire section as metadata only.

Round 1 (initial)
fix_summary: "<verbatim summary string from round's fix step, if any>"
findings:
  - {"id":"review-1","severity":"warning","file":"foo.go","line":42,"description":"...","action":"auto-fix"}
  - {"id":"review-2","severity":"info","file":"bar.go","line":7,"description":"...","action":"no-op"}
auto_selected_to_fix:    # if auto_fix was the trigger
  - {"id":"review-1",...}
user_chose_to_fix:       # if user was the source
  - {"id":"review-1",...}
user_chose_to_ignore:
  - {"id":"review-2",...}

Round 2 (auto_fix)
fix_summary: "..."
findings: ...
```

## Step-specific `specialFlag` cases

- **Test step**: also gate on "agent wrote new test files" → force `NeedsApproval=true`.
- **Review step**: also gate on `risk_level=high` even if items are empty (rare but possible).
- **Document step**: require non-empty findings AND a non-empty `summary`. If the agent returned malformed output, treat it as a single warning-severity ask-user finding.

## `MAX_ROUNDS`

Default 3 for review/test/document/lint. Hard-coded in v1; v2 could surface as a config knob.

## State the skill must keep across the whole pipeline

Per-run, in skill memory only (not persisted across invocations):

```
{
  branch, default_branch, base_sha, head_sha, ignore_patterns,
  steps: [
    {name: "rebase", status, findings, fix_summary_chain},
    {name: "review", status, findings, fix_summary_chain, risk_level, risk_rationale},
    ... etc
  ],
  pr_url: nullable,
}
```

This gets formatted into the deterministic PR Pipeline section in step 7.
