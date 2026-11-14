#!/usr/bin/env bash
# `smartdev`: every Smart Dev project on this machine — stage, task, board progress, last session.
reg=~/.local/share/smartdev/projects
[[ -s $reg ]] || { echo "No Smart Dev projects yet (a project registers on its first session)."; exit 0; }

R=$'\e[0m' DIM=$'\e[2m' BOLD=$'\e[1m' RED=$'\e[31m' GRN=$'\e[32m' YEL=$'\e[33m' BLU=$'\e[34m' MAG=$'\e[35m' CYN=$'\e[36m'
icon() {
  case $1 in
    explore) printf '%s' "${BLU}"$'\U000F018C'" explore" ;; stories) printf '%s' "${CYN}"$'\U000F0756'" stories" ;;
    spec)    printf '%s' "${MAG}"$'\U000F1353'" spec   " ;; build)   printf '%s' "${GRN}"$'\U000F0668'" build  " ;;
    review)  printf '%s' "${YEL}"$'\U000F0D05'" review " ;; *)       printf '%-9s' "${1:-?}" ;;
  esac
}
ago() { local s=$(( $(date +%s) - $1 )); if (( s < 3600 )); then echo "$((s / 60))m ago"; elif (( s < 86400 )); then echo "$((s / 3600))h ago"; else echo "$((s / 86400))d ago"; fi; }

printf "\n${DIM}  %-22s %-10s %-34s %-7s %s${R}\n" PROJECT STAGE TASK BOARD "LAST SESSION"
while read -r d; do
  f="$d/.smartdev/STATE.md"
  [[ -f $f ]] || continue  # moved or deleted project
  stage=$(sed -n 's/^stage: *//p' "$f" | awk '{print $1}')
  task=$(sed -n 's/^task: *//p' "$f"); [[ $task == none ]] && task="—"
  (( ${#task} > 33 )) && task="${task:0:32}…"
  upd=$(sed -n 's/^updated: *\([0-9-]* [0-9:]*\).*/\1/p' "$f")
  when=$(t=$(date -d "$upd" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M" "$upd" +%s 2>/dev/null) && ago "$t" || echo "$upd")
  board="—"
  if compgen -G "$d/backlog/tasks/*.md" >/dev/null; then
    board=$(grep -h '^status: ' "$d"/backlog/tasks/*.md | awk '/Parked/{next} {t++} /Done/{n++} END{print n+0 "/" t+0}')
  fi
  flag=""; grep -q '^blockers: *none' "$f" || flag=" ${RED}"$'\U000F05D6'" blocked${R}"
  printf "  ${BOLD}%-22s${R} %s${R}  %-34s %-7s ${DIM}%s${R}%s\n" "$(basename "$d" | cut -c1-22)" "$(icon "$stage")" "$task" "$board" "$when" "$flag"
done < "$reg"
echo
