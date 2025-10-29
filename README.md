# kww-claude-plugins

A collection of Claude Code plugins by Kevin Wu Won.

## Installation

To use these plugins with Claude Code, type:

```
/plugin marketplace add KevinWuWon/kww-claude-plugins
```

## partial-compact

Compacts the last N messages of a conversation to save context while preserving important information.

### Usage
1. In a long conversation, type `/partial-compact:go`. It will ask you to select a message to compact back to.
2. Manually revert the conversation to that point
3. Type `/partial-compact:load`

### Use cases
- Read large files but only need specific information
- Web searches that returned verbose results
- Long debugging sessions where only the final solution matters
- Any scenario where conversation history has grown too large

