#!/usr/bin/env bash
# One-shot Smart Dev setup on any machine. Safe to re-run (also how you update after a git pull).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)

for c in git jq npm claude; do
  command -v "$c" >/dev/null || { echo "Missing required tool: $c" >&2; exit 1; }
done
command -v backlog >/dev/null || npm i -g backlog.md

# Status line: link ours in, keep any existing one as .bak
mkdir -p ~/.claude
dst=~/.claude/statusline.sh
[[ -e $dst && ! -L $dst ]] && mv "$dst" "$dst.bak" && echo "Old status line saved as $dst.bak"
ln -sfn "$here/statusline.sh" "$dst"
s=~/.claude/settings.json
[[ -f $s ]] || echo '{}' > "$s"
if ! jq -e '.statusLine' "$s" >/dev/null; then
  tmp=$(mktemp)
  jq '.statusLine = {"type":"command","command":"~/.claude/statusline.sh","padding":0}' "$s" > "$tmp" && mv "$tmp" "$s"
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
