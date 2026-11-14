#!/usr/bin/env bash
# One-shot Smart Dev setup on any machine. Safe to re-run.
# Usage: ./install.sh [--statusline]   (--statusline replaces an existing Claude Code status line with Smart Dev's)
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)

for c in git jq npm claude; do
  command -v "$c" >/dev/null || { echo "Missing required tool: $c" >&2; exit 1; }
done
(( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 2) )) \
  || { echo "Needs bash 4.2+ (macOS: brew install bash)" >&2; exit 1; }
command -v backlog >/dev/null || npm i -g backlog.md

# Status line: set ours only if none is configured, or if --statusline was passed. Never touches your files.
mkdir -p ~/.claude
s=~/.claude/settings.json
[[ -f $s ]] || echo '{}' > "$s"
cur=$(jq -r '.statusLine.command // ""' "$s")
ours=$(readlink -f "${cur/#\~/$HOME}" 2>/dev/null || true)
if [[ -z $cur || ${1:-} == --statusline ]]; then
  [[ -n $cur ]] && echo "Replacing status line (was: $cur)"
  tmp=$(mktemp)
  jq --arg c "$here/statusline.sh" '.statusLine = {"type":"command","command":$c,"padding":0}' "$s" > "$tmp" && mv "$tmp" "$s"
elif [[ $ours != "$here/statusline.sh" ]]; then
  echo "Kept your existing status line. Re-run with --statusline to use Smart Dev's."
fi

# `smartdev` command: all projects at a glance
mkdir -p ~/.local/bin && ln -sfn "$here/status.sh" ~/.local/bin/smartdev
[[ :$PATH: == *:$HOME/.local/bin:* ]] || echo "Add ~/.local/bin to your PATH to use the smartdev command"

# Plugin: this clone is the marketplace, so `git pull && ./install.sh` updates it
if claude plugin marketplace list 2>/dev/null | grep -q smartdev; then
  claude plugin marketplace update smartdev
  claude plugin update smartdev@smartdev || true
else
  claude plugin marketplace add "$here"
  claude plugin install smartdev@smartdev
fi

echo "Smart Dev installed. Restart Claude Code, then in any project run: /smartdev:start"
