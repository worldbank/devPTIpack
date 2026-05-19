#!/usr/bin/env bash
# Stop hook: detect new merges on worldbank/main and report open-issue status.
#
# Does NOT auto-close anything. Instead:
#   - When worldbank/main advances, shows which referenced issues are still
#     OPEN (unexpected — GitHub auto-close should have handled them), so
#     Claude knows to run the close-issue-on-merge skill if needed.
#   - Always shows the remaining open-issue backlog after a merge.
#
# Silent (exits 0, no output) when main has not advanced since the last run.
#
# State file : .claude/.last-main-sha  (gitignored local state)
# GH token   : ~/.gh-pat-tmp           (same pattern as the rest of the project)

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -f "$REPO_ROOT/DESCRIPTION" ] || exit 0   # guard: only inside devPTIpack

REPO="worldbank/devPTIpack"
STATE_FILE="$REPO_ROOT/.claude/.last-main-sha"

# Read local tracking ref — no network call.
CURRENT_SHA="$(git rev-parse worldbank/main 2>/dev/null)" || exit 0
LAST_SHA="$(cat "$STATE_FILE" 2>/dev/null || echo "")"

# Nothing new → exit silently.
[ "$LAST_SHA" != "$CURRENT_SHA" ] || exit 0

# Persist the new SHA immediately so re-runs within the same turn are no-ops.
echo "$CURRENT_SHA" > "$STATE_FILE"

# Load GH token (same convention used everywhere in this project).
GH_PAT="$HOME/.gh-pat-tmp"
[ -f "$GH_PAT" ] && export GH_TOKEN="$(cat "$GH_PAT")"

# Bail out gracefully if gh is not authenticated.
gh auth status --hostname github.com > /dev/null 2>&1 || {
  printf '[post-merge] worldbank/main advanced but gh auth unavailable — skipping issue check.\n' >&2
  exit 0
}

printf '\n[post-merge] worldbank/main advanced (%s → %s).\n' \
  "${LAST_SHA:0:7}" "${CURRENT_SHA:0:7}" >&2

# ── 1. Report issue status for each newly merged PR ──────────────────────────
#    Does NOT close anything — reports only, so Claude decides.

NEEDS_CLOSE=()

if [ -n "$LAST_SHA" ]; then
  NEW_PRS="$(
    git log "${LAST_SHA}..worldbank/main" --oneline --merges 2>/dev/null \
      | grep -oE '#[0-9]+' | grep -oE '[0-9]+' | sort -u
  )"

  for PR in $NEW_PRS; do
    ISSUES="$(
      gh pr view "$PR" --repo "$REPO" --json body --jq '.body' 2>/dev/null \
        | grep -oiE '(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) #[0-9]+' \
        | grep -oE '[0-9]+' | sort -u
    )"

    [ -n "$ISSUES" ] || continue

    for ISSUE in $ISSUES; do
      STATE="$(
        gh issue view "$ISSUE" --repo "$REPO" --json state --jq '.state' 2>/dev/null
      )"
      if [ "$STATE" = "OPEN" ]; then
        printf '[post-merge] ⚠ Issue #%s still OPEN after PR #%s merged — auto-close may have missed it.\n' \
          "$ISSUE" "$PR" >&2
        NEEDS_CLOSE+=("#$ISSUE (PR #$PR)")
      else
        printf '[post-merge] ✔ Issue #%s closed (PR #%s ok).\n' "$ISSUE" "$PR" >&2
      fi
    done
  done
fi

if [ "${#NEEDS_CLOSE[@]}" -gt 0 ]; then
  printf '[post-merge] Run close-issue-on-merge skill for: %s\n' \
    "$(IFS=', '; echo "${NEEDS_CLOSE[*]}")" >&2
fi

# ── 2. Open-issue backlog ─────────────────────────────────────────────────────

printf '\n[open issues] Remaining open issues in %s:\n' "$REPO" >&2
COUNT=0
while IFS= read -r line; do
  printf '  %s\n' "$line" >&2
  COUNT=$((COUNT + 1))
done < <(
  gh issue list --repo "$REPO" --state open --limit 40 \
    --json number,title \
    --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null
)

[ "$COUNT" -gt 0 ] || printf '  (no open issues or could not fetch)\n' >&2
printf '\n' >&2

exit 0
