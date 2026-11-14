# Stage: Review (fresh eyes)
Input: a card in Review. Read the card (spec and acceptance criteria), then its changes: `git log --oneline --grep "TASK-<n>"` and the diffs of those commits.

Check:
- Every acceptance criterion really works. Run the tests and show the output.
- The code matches the spec, with nothing extra beyond it.
- Bugs, edge cases, error handling, input validation and security.
- The tests would fail if the code broke.

List problems; don't fix them here (fast lane may fix trivial ones).

Result:
- Pass: `backlog task edit <id> -s Done --notes "<2-line summary>"`. Next stage: `spec` with the next To Do card. If none are left, tell the user the backlog is complete.
- Fail: `backlog task edit <id> -s "In Progress" --notes "<numbered fix list>"`. Next stage: `build`, same task.
