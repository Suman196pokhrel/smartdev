#!/usr/bin/env bash
# Does what install.sh used to, so `/plugin install` is the whole install. Silent unless something is missing.
data=${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/smartdev-smartdev}
mkdir -p "$data" ~/.local/bin
# Re-linked every session: ${CLAUDE_PLUGIN_ROOT} moves to a new folder on each plugin update.
ln -sfn "$CLAUDE_PLUGIN_ROOT/statusline.sh" "$data/statusline.sh"
ln -sfn "$CLAUDE_PLUGIN_ROOT/status.sh" ~/.local/bin/smartdev

[[ -f $data/setup-done ]] && exit 0
missing=""
for c in git jq npm; do command -v "$c" >/dev/null || missing+=" $c"; done
(( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 2) )) || missing+=" bash-4.2+ (macOS: brew install bash)"
if [[ -n $missing ]]; then
  echo "Smart Dev plugin setup is waiting on:$missing. Tell the user to install these; setup finishes on the next session."
  exit 0
fi

# Background so the 5s hook timeout never cuts it off; init.sh retries if this fails.
command -v backlog >/dev/null || nohup npm i -g backlog.md >/dev/null 2>&1 &

# Status line: set ours only if none is configured. Write through cat so a symlinked settings.json stays a symlink.
s=~/.claude/settings.json
[[ -f $s ]] || echo '{}' > "$s"
if [[ -z $(jq -r '.statusLine.command // ""' "$s" 2>/dev/null) ]]; then
  tmp=$(mktemp) && jq --arg c "$data/statusline.sh" '.statusLine = {"type":"command","command":$c,"padding":0}' "$s" > "$tmp" 2>/dev/null \
    && cat "$tmp" > "$s"
  rm -f "$tmp"
fi
[[ :$PATH: == *:$HOME/.local/bin:* ]] || echo "Smart Dev: tell the user to add ~/.local/bin to their PATH to use the \`smartdev\` command."
touch "$data/setup-done"
