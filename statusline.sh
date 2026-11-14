#!/usr/bin/env bash
# Claude Code status line. Uses the terminal's 16 ANSI colors, so it follows
# whatever Omarchy theme is active. Icons need a Nerd Font (JetBrainsMono NF).

# Pull every field in one jq call; missing values become "".
IFS=$'\x1f' read -r model effort cwd proj ctx rl5 rl5_reset added removed < <(
  jq -r 'def n: if . == null then "" else floor | tostring end;
  [
    .model.display_name // "Claude",
    .effort.level // "",
    .workspace.current_dir // .cwd // "",
    .workspace.project_dir // .workspace.current_dir // .cwd // "",
    (.context_window.used_percentage | n),
    (.rate_limits.five_hour.used_percentage | n),
    (.rate_limits.five_hour.resets_at | n),
    (.cost.total_lines_added // 0 | n),
    (.cost.total_lines_removed // 0 | n)
  ] | join("\u001f")'
)

# Colors (terminal palette, so they match the theme)
R=$'\e[0m' DIM=$'\e[2m' BOLD=$'\e[1m'
RED=$'\e[31m' GRN=$'\e[32m' YEL=$'\e[33m' BLU=$'\e[34m' MAG=$'\e[35m' CYN=$'\e[36m'
SEP=" ${DIM}│${R} "

# Nerd Font icons, written as UTF-8 bytes so they survive any editor/locale
I_MODEL=$'\xf3\xb0\x9a\xa9' I_LIMIT=$'\xf3\xb1\x8e\xab'
I_DIR=$'\xef\x81\xbb' I_GIT=$'\xee\x9c\xa5' I_DOCKER=$'\xef\x8c\x88'
I_NODE=$'\xee\x9c\x98' I_PY=$'\xee\x9c\xbc' I_GO=$'\xee\x98\xa7' I_RUST=$'\xee\x9e\xa8'
I_BOLT=$'\xef\x83\xa7' I_NEXT='▲'

# green < 50, yellow < 80, red otherwise
level() { if (( $1 >= 80 )); then printf %s "$RED"; elif (( $1 >= 50 )); then printf %s "$YEL"; else printf %s "$GRN"; fi; }
# context: yellow at 30%, red at 40% (Smart Dev rule: hand off before 40%)
ctx_level() { if (( $1 >= 40 )); then printf %s "$RED"; elif (( $1 >= 30 )); then printf %s "$YEL"; else printf %s "$GRN"; fi; }

out="${MAG}${BOLD}${I_MODEL} ${model}${R}"
[[ -n $effort ]] && out+=" ${DIM}${effort}${R}"

# Project name (+ subfolder if you've cd'd deeper)
name=${proj##*/}; [[ $proj == "$HOME" ]] && name="~"
sub=${cwd#"$proj"}; [[ $sub == "$cwd" ]] && sub=""
out+="${SEP}${BLU}${I_DIR} ${name}${R}${DIM}${sub}${R}"

# Git: branch, ahead/behind, staged, modified, untracked (one git call)
if gs=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null); then
  branch=$(awk '/^# branch.head/{print $3}' <<<"$gs")
  read -r ahead behind < <(awk '/^# branch.ab/{gsub(/[+-]/,""); print $3, $4}' <<<"$gs")
  staged=$(grep -cE '^[12u] [^.]' <<<"$gs")
  modified=$(grep -cE '^[12u] .[^.]' <<<"$gs")
  untracked=$(grep -c '^?' <<<"$gs")
  g="${GRN}${I_GIT} ${branch}${R}"
  (( ahead ))     && g+=" ${CYN}⇡${ahead}${R}"
  (( behind ))    && g+=" ${CYN}⇣${behind}${R}"
  (( staged ))    && g+=" ${GRN}+${staged}${R}"
  (( modified ))  && g+=" ${YEL}~${modified}${R}"
  (( untracked )) && g+=" ${DIM}?${untracked}${R}"
  out+="${SEP}${g}"
fi

# Stack badge from files in the project root
stack=""
if   compgen -G "$proj/next.config.*" >/dev/null; then stack="${I_NEXT} next"
elif compgen -G "$proj/vite.config.*" >/dev/null; then stack="${I_BOLT} vite"
elif [[ -f $proj/package.json ]];                 then stack="${I_NODE} node"
elif [[ -f $proj/pyproject.toml || -f $proj/requirements.txt ]]; then stack="${I_PY} py"
elif [[ -f $proj/go.mod ]];                       then stack="${I_GO} go"
elif [[ -f $proj/Cargo.toml ]];                   then stack="${I_RUST} rust"
fi
if compgen -G "$proj/docker-compose*.y*ml" >/dev/null || compgen -G "$proj/compose.y*ml" >/dev/null || [[ -f $proj/Dockerfile ]]; then
  stack+="${stack:+ }${I_DOCKER}"
fi
[[ -n $stack ]] && out+="${SEP}${CYN}${stack}${R}"

# Context window bar
if [[ -n $ctx ]]; then
  filled=$(( (ctx + 10) / 20 )); (( filled > 5 )) && filled=5
  bar=""; for i in 1 2 3 4 5; do if (( i <= filled )); then bar+="▰"; else bar+="▱"; fi; done
  out+="${SEP}$(ctx_level "$ctx")${bar} ${ctx}%${R}"
fi

# 5-hour usage limit (subscribers only); adds reset time once it gets high
if [[ -n $rl5 ]]; then
  r="$(level "$rl5")${I_LIMIT} ${rl5}%${R}"
  (( rl5 >= 75 )) && [[ -n $rl5_reset ]] && r+=" ${DIM}↻ $(date -d "@$rl5_reset" +%H:%M)${R}"
  out+="${SEP}${r}"
fi

# Lines changed this session
(( added || removed )) && out+="${SEP}${GRN}+${added}${R} ${RED}-${removed}${R}"

printf '%s\n' "$out"
