#!/usr/bin/env bash
# Feeds the project's Smart Dev state into a new session and registers the project for `smartdev`.
# Silent (zero tokens) outside Smart Dev projects.
dir="${CLAUDE_PROJECT_DIR:-$PWD}"
f="$dir/.smartdev/STATE.md"
[[ -f $f ]] || exit 0
reg=~/.local/share/smartdev/projects
mkdir -p "${reg%/*}" && { grep -qxF "$dir" "$reg" 2>/dev/null || echo "$dir" >> "$reg"; }
echo "This is a Smart Dev project. For pipeline work, follow the smartdev:start skill. Current state:"
cat "$f"
