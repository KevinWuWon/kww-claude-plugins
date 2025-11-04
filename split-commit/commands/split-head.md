---
description: Split the HEAD commit into smaller commits
---
Split the HEAD commit into smaller commits using the following process:

1. If there are any uncommitted changes according to `git status`, stash them
2. Read the HEAD commit code and description to understand what it does and think hard to come up with a sequence of commits it could be split into. Each commit should be a logical unit of work and the code should work and compile after it. If there is a combination of refactor and implementation, the refactoring should come first.
3. Present the sequence of commits to the user for their approval before continuing.
4. Take note of the currently checked out branch with `git branch --show-current`; let's call this <branch_name>
5. Run `git checkout HEAD^`
6. For each eventual commit as decided in step 2, do the following:
   a) Run `git diff HEAD <branch_name>` (skip this for the first iteration because you've already seen this in step 2)
   b) If this is the last commit in the chain, skip the following steps and go to step 7.
   c) Apply the subset of that diff by editing the files on disk.
   d) Run the relevant compilation/linter/formatting commands.
   e) Run `git add <file>` for any new files
   f) Run `git commit -a -m <message>` where <message> describes that commit
7. For the last commit in the eventual chain, we just need to update the files on disk to the final state. Do these steps:
   a) Run `git rev-parse HEAD` to get the SHA
   b) Run `git checkout <branch_name>`
   c) Run `git reset --soft <sha>` where <sha> is that found in step (a)
   d) Run `git commit -a -m <message>` where <message> describes that commit
8. If you stashed anything in step 1, unstash it now.