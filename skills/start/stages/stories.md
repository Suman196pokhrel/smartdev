# Stage: User stories
Input: `docs/explore.md`. Goal: a backlog of small stories, each shippable on its own.

Do:
1. Draft stories as "As a <user>, I can <action> so that <value>". Each fits in one build session; split anything bigger.
2. Give each 2–5 acceptance criteria that describe observable behaviour and can be tested, not implementation.
3. Add a `## Non-goals` section to `docs/explore.md`: what this project will explicitly not do.
4. Show the list to the user in priority order and adjust it with them.
5. Create the cards in that order: `backlog task create "<title>" -d "<story>" --ac "..." --ac "..."`.
6. Ideas the user likes but not for now: create them with `-s Parked`.

Done when: the cards exist and the user approved the order. Next stage: `spec`, task: the first To Do card.
