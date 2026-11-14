#!/usr/bin/env bash
# A message that is just "wrap up" (any case, "wrap-up", trailing "!") in a Smart Dev project triggers the handoff.
[[ -f "${CLAUDE_PROJECT_DIR:-$PWD}/.smartdev/STATE.md" ]] || exit 0
p=$(jq -r '.prompt // ""' | tr '[:upper:]\n' '[:lower:] ' | tr -d '[:punct:]' | sed 's/^ *//; s/ *$//')
[[ $p =~ ^wrap\ ?up$ ]] && echo 'The user said the Smart Dev keyword "wrap up". Invoke the smartdev:handoff skill now and follow it.'
exit 0
