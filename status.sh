#!/usr/bin/env bash
# `smartdev`: every Smart Dev project on this machine with its stage, task and last update.
reg=~/.local/share/smartdev/projects
[[ -s $reg ]] || { echo "No Smart Dev projects yet (a project registers on its first session)."; exit 0; }
printf '%-24s %-8s %-36s %s\n' PROJECT STAGE TASK UPDATED
while read -r d; do
  f="$d/.smartdev/STATE.md"
  [[ -f $f ]] || continue  # moved or deleted project
  printf '%-24s %-8s %-36s %s\n' "$(basename "$d")" "$(sed -n 's/^stage: //p' "$f")" \
    "$(sed -n 's/^task: //p' "$f" | cut -c1-36)" "$(sed -n 's/^updated: //p' "$f")"
done < "$reg"
