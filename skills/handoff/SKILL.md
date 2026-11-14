---
name: handoff
description: Close a Smart Dev session by updating the board card, rewriting .smartdev/STATE.md for the next session, and appending one line to the project log (.smartdev/log.md). Use when the user says "wrap up" or runs /smartdev:handoff in a project with .smartdev/STATE.md.
---

# Smart Dev handoff
Be quick. Ask only if the state is genuinely unclear.

1. **Card:** make the current card's status match reality. If build stopped midway, add a progress note: `backlog task edit <id> --comment "<where it stopped>"`.
2. **Numbers:**
   - stories: count per column from `backlog task list --plain`
   - tests: pass/fail from the last run this session, or "not run"
   - commits: `git log --oneline --since="<updated from STATE.md>" | wc -l`
3. **Rewrite `.smartdev/STATE.md`** in exactly the existing format, 20 lines max:
   - `stage`/`task`: where the next session starts
   - `next`: one concrete first action
   - `blockers`
   - `updated`: now (`date '+%F %R'`), session number +1
   - `## Last session`: 2–4 bullets, written so they make sense a month from now without the chat:
     - decisions made
     - gotchas
     - user corrections, prefixed `correction:`
   - If a correction is a lasting rule, offer to add it to the project's CLAUDE.md.
4. **Log:** append one line to `.smartdev/log.md`:
   `YYYY-MM-DD HH:MM | <project> | <stage worked> → <next stage> | <task or -> | <one-line summary>`
5. **Commit** only the state and board: `git add .smartdev backlog && git commit -m "chore(smartdev): handoff session <n>" -- .smartdev backlog`. Skip this if nothing changed.
6. **Reply** in 5 lines max: what got done · next stage and action · blockers · "Open a fresh session; the state loads automatically."
