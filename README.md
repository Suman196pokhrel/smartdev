# Smart Dev

A lightweight Claude Code plugin that runs every project through one pipeline, one stage per session, with state handed off through files.

```
Once per project:  Explore → User stories (+ non-goals)
Per story (loop):  Spec → Build (TDD, commit on every green test) → Review → Done
Every session:     state loads automatically → work one stage → "wrap up" → handoff
```

The overview diagram is `docs/pipeline.excalidraw` (open it in Excalidraw). Regenerate it with `python3 docs/make_diagram.py`.

## Install (new machine)

Needs `git`, `jq`, `npm` and `claude`.

```bash
git clone git@github.com:Suman196pokhrel/smartdev.git ~/DevStuff/projects/smartdev
~/DevStuff/projects/smartdev/install.sh
```

The installer:
- installs [Backlog.md](https://github.com/MrLesk/Backlog.md)
- links the status line (any existing one is saved as `.bak`)
- links the `smartdev` command into `~/.local/bin`
- registers this clone as a plugin marketplace and installs the plugin

Restart Claude Code afterwards.

**Update:** `git pull`, then `/reload-plugins` (or restart). The plugin is read straight from this folder, so local edits apply the same way. Re-running `install.sh` is always safe.

## Use

| You do | What happens |
|---|---|
| `/smartdev:start` in a new project | Sets up git, a Backlog.md board and `.smartdev/STATE.md`, then starts Explore |
| Open any session in that project | The hook loads `STATE.md` (~200 tokens); `/smartdev:start` continues the current stage |
| Say `wrap up` (or `/smartdev:handoff`) | Updates the card, rewrites `STATE.md`, appends a line to `.smartdev/log.md`, commits state |
| `smartdev` (any terminal) | Lists every Smart Dev project on this machine: stage, task, last update |
| `backlog browser` / `backlog board` | View the board on the web or in the terminal (columns: To Do · In Progress · Review · Done · Parked) |

## Rules

- **One stage per session.** Handoff happens through files, never through chat history.
- **Keep context under 40%.** The status line turns yellow at 30% and red at 40%.
- **New ideas go to Parked.** Nothing outside the current story gets built.
- **Only Review marks a card Done.**
- **Fast lane:** small fixes skip explore, stories and spec, and go straight to build and review.

## Where things live (per project)

| File | Holds |
|---|---|
| `.smartdev/STATE.md` | Stage, current task, next action, blockers, numbers, last-session notes. About 20 lines, overwritten each handoff. |
| `.smartdev/log.md` | One line per session, append-only: date, stage moved, task, summary |
| `docs/explore.md` | Problem, users, constraints, how to test, non-goals |
| `backlog/tasks/*.md` | One card per story: description, acceptance criteria, spec (Implementation Plan), notes |

The board owns task status. `STATE.md` owns the pipeline stage and only points at a task ID.

## Layout

```
.claude-plugin/       plugin + marketplace manifests (repo root is the plugin)
skills/start/         pipeline rules, init.sh, STATE template, stages/*.md (only the current stage is read)
skills/handoff/       session close
hooks/                session-start.sh (inject state, register project), keyword.sh ("wrap up" → handoff)
status.sh             the `smartdev` command (all projects at a glance)
statusline.sh         status line with the 30/40% context colours
install.sh            setup and update
```
