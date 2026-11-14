# Stage: Spec (one story)
Input: one To Do card (the top one unless the user picks another). Read the card, `docs/explore.md` (non-goals) and only the code this story touches.

Write a minimal spec into the card with `backlog task edit <id> --plan "..."`, under ~40 lines:
- Approach: 2–5 lines
- Files to touch
- Data or API changes, if any
- Test list: at least one test per acceptance criterion, plus key edge cases
- Out of scope for this story

If the story turns out too big, split it into new cards instead of writing a big spec.

Done when: the user approves the spec. Next stage: `build`, same task.
