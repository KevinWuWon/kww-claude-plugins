# kww-claude-plugins

A collection of Claude Code plugins by Kevin Wu Won.

## Installation

To use these plugins with Claude Code, type:

```
/plugin marketplace add KevinWuWon/kww-claude-plugins
```

## better-compact

Compacts the last N messages of a conversation to save context while preserving important information.

### Usage
For tail compaction:
1. In a long conversation, type `/better-compact:compact-tail`. It will ask you to select a message to 
   compact back to.
2. Manually revert the conversation to that point using Shift-Shift. Make sure to select the "Restore conversation" option (not "Restore code and conversation")
3. Type `/better-compact:load`

For full compaction:
1. In a long conversation, type `/better-compact:compact-full`.
2. Type `/clear`
3. Type `/better-compact:load`

### Use cases
- Read large files but only need specific information
- Web searches that returned verbose results
- Long debugging sessions where only the final solution matters
- Any scenario where conversation history has grown too large

## split-commit

Splits the HEAD commit into a sequence of smaller commits for better git history and reviewability.

### Usage
1. If you have found yourself a huge number of changes, commit them so it is in your HEAD commit.
2. Type `/split-commit:split-head` and follow the prompts
3. The plugin will analyze your changes and create a sequence of smaller commits, guaranteeing that
   the final result is the same code
