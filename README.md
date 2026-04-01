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
