---
name: start
description: Start or resume the Smart Dev pipeline (explore → stories → spec → build with TDD → review, one stage per session). Use when the user runs /smartdev:start, wants to set up a new project with Smart Dev, or wants to continue pipeline work in a project that has .smartdev/STATE.md.
---

# Smart Dev

## New project (no `.smartdev/STATE.md`)
Run `bash <this skill's base directory>/init.sh "<project name>"` from the project root. It sets up git, the Backlog.md board and `.smartdev/STATE.md`. Then run the explore stage.

## Every session
1. State: it was injected at session start; if not, read `.smartdev/STATE.md`.
2. If it names a task, load only that card: `backlog task <id> --plain`. If the card's status contradicts the stage, tell the user and ask which is right. The board owns task status; STATE.md owns the stage.
3. Read only `stages/<stage>.md` from this skill's directory and follow it.
4. When the stage's "Done when" is met, stop and say: "Stage done. Say **wrap up**, then open a fresh session." Do not start the next stage in this session.

## Rules
- One stage per session. Handoff is files (docs, board cards, code, STATE.md), never chat history.
- Stay lean: read only what the stage needs. If the session gets long, suggest wrap up; the status line turns red at 40% context.
- New ideas or scope mid-session: `backlog task create "<idea>" -s Parked`, tell the user, carry on. Never build them.
- Only the review stage moves a card to Done.
- Fast lane: a small bug fix or tweak skips explore, stories and spec. Use or create one card, follow `stages/build.md`, then `stages/review.md`; both in one session is fine.

## Board commands (Backlog.md)
Columns: `To Do` · `In Progress` · `Review` · `Done` · `Parked`
- list: `backlog task list --plain` (filter: `-s "To Do"`)
- view: `backlog task <id> --plain`
- create: `backlog task create "<title>" -d "<story>" --ac "<criterion>" --ac "..."` (`--dep <id>` for dependencies)
- move: `backlog task edit <id> -s "In Progress"`
- spec: `backlog task edit <id> --plan "<spec>"` (replaces the plan)
- tick criterion: `backlog task edit <id> --check-ac <n>`
- progress note: `backlog task edit <id> --comment "<text>"` (appends); `--notes` replaces the notes section
