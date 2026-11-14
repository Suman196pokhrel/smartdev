#!/usr/bin/env bash
# Sets up Smart Dev in the current directory: git repo, Backlog.md board with the 5 columns, .smartdev/STATE.md.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
name=${1:-$(basename "$PWD")}
name=${name//[\/&]/-}  # keep sed replacement safe

[[ -f .smartdev/STATE.md ]] && { echo "Smart Dev already set up here."; exit 0; }
command -v backlog >/dev/null || { echo "Backlog.md missing: npm i -g backlog.md" >&2; exit 1; }

git rev-parse --git-dir >/dev/null 2>&1 || git init -q
[[ -f backlog/config.yml ]] || backlog init "$name" --defaults --integration-mode none >/dev/null 2>&1 \
  || { echo "backlog init failed; run it by hand to see why" >&2; exit 1; }
# -i.bak works on both GNU and BSD/macOS sed
sed -i.bak 's/^statuses:.*/statuses: ["To Do", "In Progress", "Review", "Done", "Parked"]/; s/^remote_operations: true/remote_operations: false/' backlog/config.yml && rm backlog/config.yml.bak

mkdir -p .smartdev docs
sed "s/<project>/$name/; s/<updated>/$(date '+%F %R')/" "$here/STATE.template.md" > .smartdev/STATE.md
echo "Smart Dev ready: board in backlog/, state in .smartdev/STATE.md"
