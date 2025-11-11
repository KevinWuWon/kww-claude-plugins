---
description: Compress the last N messages of the conversation history
---
Perform a partial compaction of the recent conversation history by writing a summary to ./BETTER_COMPACT_RESULT.md of the most recent N user/system messages.

Look at the recent user messages and user-invoked slash commands in the message history. Ask the user which message X to compact back to (inclusive). Include some likely options in the AskUserQuestion tool, presented in chronological order. Present these options using the verbatim initial few words or slash command name from the user message.

After you write the summary, instruct the user to revert the conversation (but not the code) to message X and instruct the user to run /better-compact:load after they have done so. After reverting, you will no longer see any messages from message X onwards; but any code that was changed in the course of the conversation will remain on disk. The summary provided will be appended to the end of the context. So, next time you will see all the messages before the checkpoint, plus the summary of the last part of the conversation. You must make it very clear in the summary, describe what you have done/changed, what you have learned and any other information that may be useful.

Here are some typical scenarios:

* You read some files, found them very large and most of the content is not relevant to the current task. In this case we can revert back to before you read the files and retain only the useful parts in the summary.
* You searched the web, found the result very large.
    - If you got what you need, we can revert back to before you searched the web and retain the useful part in the summary.
    - If you did not get what you need, revert back and describe in the summary what was tried and what alternative query we could try next.
* You wrote some code. You spent many struggling steps to fix it; the process is not relevant to the ultimate goal, but eventually you got it right. In this case revert back to before you wrote the code and simply state in the summary that the code was written successfully along with lessons learnt.

What not to include:

* If in the conversation, you asked me questions and I answered them and then you proceeded based on that, and this information is not needed for future steps; don't mention that the questions were asked or what the answers were.
* If you learnt something that was relevant for that conversation but unlikely to be relevant for future steps, don't include it in the summary.

Follow this structure (omit sections that do not apply):

<example-structure filename="BETTER_COMPACT_RESULT.md">
# Summary of compacted conversation

The following is a summary of some conversation or work that happened but for which the details have been redacted for the sake of context efficiency.

## What was done
...

## Results
[findings from research; section omitted for implementation work]

## Lessons learnt
[only include lessons that would be relevant for the future of this thread]

## Relevant files (must read)
* some/file.ts:80-100
* some/otherfile.ts
* ...
</example-structure>
