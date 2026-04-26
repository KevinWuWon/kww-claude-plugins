# kww-claude-plugins

A collection of Claude Code plugins by Kevin Wu Won.

## Installation

To use these plugins with Claude Code, type:

```
/plugin marketplace add KevinWuWon/kww-claude-plugins
```

## split-commit

Splits the HEAD commit into a sequence of smaller commits for better git history and reviewability.

### Usage
1. If you have found yourself a huge number of changes, commit them so it is in your HEAD commit.
2. Type `/split-commit:split-head` and follow the prompts
3. The plugin will analyze your changes and create a sequence of smaller commits, guaranteeing that
   the final result is the same code

## no-mistakes

Runs an opinionated 8-step pre-merge pipeline (rebase, review, test, document, lint, push, PR, CI)
against the current branch, with auto-fix loops and human approval gates.

Ported from [kunchenguid/no-mistakes](https://github.com/kunchenguid/no-mistakes) — originally a
TUI/daemon, here packaged as a self-contained Claude Code skill.

### Usage
1. From a feature branch with changes ready to ship, ask Claude to run the no-mistakes pipeline.
2. Approve, fix, skip, or abort at each step's gate; auto-fix loops re-run the agent up to 3 rounds.
3. The pipeline pushes, opens/updates a PR with a structured summary, and (optionally) watches CI.
