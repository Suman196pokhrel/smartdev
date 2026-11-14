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
I_COMMIT=$'\U000F0718'
# Smart Dev stage icons (Material Design outline set) — same set the skills and `smartdev` use
I_EXPLORE=$'\U000F018C' I_STORIES=$'\U000F0756' I_SPEC=$'\U000F1353' I_BUILD=$'\U000F0668'
I_REVIEW=$'\U000F0D05' I_DONE=$'\U000F05E1' I_PARKED=$'\U000F03E6' I_TASK=$'\U000F0913'
I_BOARD=$'\U000F07AF' I_BLOCK=$'\U000F05D6'

# seconds → 5m / 3h / 2d
ago() { local s=$(( $(date +%s) - $1 )); if (( s < 3600 )); then echo "$((s / 60))m"; elif (( s < 86400 )); then echo "$((s / 3600))h"; else echo "$((s / 86400))d"; fi; }

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
  # Time since last commit; yellow when changes have sat uncommitted for 30m+ (commit on every green test)
  if last=$(git -C "$cwd" log -1 --format=%ct 2>/dev/null) && [[ -n $last ]]; then
    c=$DIM; (( (staged || modified) && $(date +%s) - last > 1800 )) && c=$YEL
    g+=" ${c}${I_COMMIT} $(ago "$last")${R}"
  fi
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

# Line 2, Smart Dev projects only: stage · task · acceptance criteria · board progress · blockers
st="$proj/.smartdev/STATE.md"
[[ -f $st ]] || exit 0
stage=$(sed -n 's/^stage: *//p' "$st" | awk '{print $1}')
task=$(sed -n 's/^task: *//p' "$st")
blockers=$(sed -n 's/^blockers: *//p' "$st")
case $stage in
  explore) s="${BLU}${I_EXPLORE} explore" ;;  stories) s="${CYN}${I_STORIES} stories" ;;
  spec)    s="${MAG}${I_SPEC} spec" ;;        build)   s="${GRN}${I_BUILD} build" ;;
  review)  s="${YEL}${I_REVIEW} review" ;;    *)       s="${DIM}${stage:-?}" ;;
esac
l2="${BOLD}${s}${R}"

if [[ -n $task && $task != none ]]; then
  id=${task%% *} title=${task#"$id"}; title=${title# }
  (( ${#title} > 32 )) && title="${title:0:31}…"
  l2+="${SEP}${I_TASK} ${id}${DIM} ${title}${R}"
  card=$(compgen -G "$proj/backlog/tasks/${id,,} - *.md" | head -1)
  if [[ -n $card ]]; then
    read -r acd act < <(awk '/AC:BEGIN/{f=1;next} /AC:END/{f=0} f&&/^- \[x\]/{d++} f&&/^- \[[ x]\]/{t++} END{print d+0, t+0}' "$card")
    (( act )) && { c=$DIM; (( acd == act )) && c=$GRN; l2+=" ${c}${I_DONE} ${acd}/${act}${R}"; }
  fi
fi

if compgen -G "$proj/backlog/tasks/*.md" >/dev/null; then
  read -r done total parked < <(grep -h '^status: ' "$proj"/backlog/tasks/*.md |
    awk '/Parked/{p++; next} {t++} /Done/{d++} END{print d+0, t+0, p+0}')
  l2+="${SEP}${I_BOARD} ${done}/${total} done"
  (( parked )) && l2+=" ${DIM}${I_PARKED} ${parked}${R}"
fi

[[ -n $blockers && $blockers != none ]] && l2+="${SEP}${RED}${I_BLOCK} blocked${R}"
printf '%s\n' "$l2"
