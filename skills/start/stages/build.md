# Stage: Build (TDD)
Input: a card whose plan holds the spec. Move it: `backlog task edit <id> -s "In Progress"`.

For each test in the spec's test list:
1. Write one failing test. Run it and confirm it fails for the right reason.
2. Write the minimum code to pass. Run the relevant tests.
3. Refactor if needed, keeping tests green.
4. Commit: `<type>: <what> (TASK-<n>)`. One small commit per green step.
5. When an acceptance criterion is covered by passing tests: `backlog task edit <id> --check-ac <n>`.

Rules:
- Never change a test just to make it pass. If the test is wrong, say so first.
- Nothing beyond the spec. Extra ideas go to Parked.
- If the spec is wrong, stop and tell the user. Update the plan only after they agree.
- Review fixes: if the card has a fix list in its notes, work through it with the same loop.

Done when: every acceptance criterion is ticked and the full test suite is green (show the output). Move the card to `Review`. Next stage: `review`.
