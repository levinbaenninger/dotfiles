#!/usr/bin/env bash
# PreToolUse hook: reject commits and PR writes that carry AI attribution
# (Co-Authored-By: Claude …, "Generated with Claude Code"). Exit 2 sends the
# message back to the model, which retries without the line.
set -euo pipefail

input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")

if [[ $tool == Bash ]]; then
  text=$(jq -r '.tool_input.command // ""' <<<"$input")
  # Only commands that write commits or PRs; leave grep, git log etc. alone.
  grep -qE 'git (commit|commit-tree|notes)|gh pr (create|edit|comment)|az repos pr' <<<"$text" || exit 0
else
  text=$(jq -c '.tool_input // {}' <<<"$input")
fi

if grep -qiE 'co-authored-by:[^<]*(claude|anthropic|codex|openai|copilot)|generated with \[?claude|noreply@anthropic\.com' <<<"$text"; then
  echo "Blocked: the user does not want AI attribution in commits or PRs. Remove the Co-Authored-By trailer / 'Generated with Claude Code' line and try again." >&2
  exit 2
fi
exit 0
