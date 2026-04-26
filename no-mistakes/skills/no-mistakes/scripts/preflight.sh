#!/usr/bin/env bash
# Emit no-mistakes pipeline placeholders as JSON.
# Run from inside the worktree.
set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  printf '{"error":"not in a git repository"}\n' >&2
  exit 1
fi

branch=$(git rev-parse --abbrev-ref HEAD)
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main)

if [ "${branch}" = "${default_branch}" ]; then
  printf '{"error":"on default branch %s; nothing to ship"}\n' "${default_branch}" >&2
  exit 1
fi

base_sha=$(git merge-base HEAD "origin/${default_branch}" 2>/dev/null || git rev-parse HEAD)
head_sha=$(git rev-parse HEAD)
upstream=$(git remote get-url origin 2>/dev/null || echo "")
review_scope="branch changes between ${base_sha} and ${head_sha}"

if git diff --quiet "${base_sha}" HEAD; then
  has_diff="false"
else
  has_diff="true"
fi

printf '{
  "branch": "%s",
  "default_branch": "%s",
  "base_sha": "%s",
  "head_sha": "%s",
  "upstream": "%s",
  "review_scope": "%s",
  "has_diff": %s,
  "ignore_patterns": "none"
}
' "${branch}" "${default_branch}" "${base_sha}" "${head_sha}" "${upstream}" "${review_scope}" "${has_diff}"
