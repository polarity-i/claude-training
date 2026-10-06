#!/bin/bash
# PostToolUse hook: after an edit to index.html, make sure the 10-second
# "IT Project Briefing" popup (Wed 14 Oct 2026, 2pm, Town Hall Meeting Room) is intact.
file=$(jq -r '.tool_input.file_path // empty')
case "$file" in *index.html) ;; *) exit 0 ;; esac

missing=""
grep -q 'id="briefing-popup"' "$file" || missing="popup markup"
grep -q 'BRIEFING_DELAY_MS = 10000' "$file" || missing="$missing 10s timer"
grep -q 'Town Hall Meeting Room' "$file" || missing="$missing venue"

if [ -n "$missing" ]; then
  echo "IT Project Briefing popup is incomplete in index.html (missing:$missing). Restore it." >&2
  exit 2
fi
exit 0
