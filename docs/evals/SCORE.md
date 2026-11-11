# Eval score sheet

Prepared 2026-11-11. No model run is recorded.

A missing eval is not a passing eval. Do not claim the generated files change
agent behavior, and do not claim a default is better, until each row has a
date, a model name, and a result for both columns.

Run the prompt in `evals/fixture/tasks/<id>/TASK.md` against `evals/fixture/`.
"With guidance" means the agent was also given the files
`generate-agents.sh --language=shell` writes for a fresh directory. "Without
guidance" means those files were not in the context. The fixture's own
`AGENTS.md` stays as it is; it is the input for task 04, not the treatment.

`evals/fixture/check.sh` only checks that the starting defects are still
there. It does not fill this sheet.

| Task | Harness | Model | Date | With guidance | Without guidance |
|------|---------|-------|------|---------------|------------------|
| 01-lint-failure | Claude Code | | | not run | not run |
| 01-lint-failure | Codex | | | not run | not run |
| 01-lint-failure | Cursor | | | not run | not run |
| 02-failing-test | Claude Code | | | not run | not run |
| 02-failing-test | Codex | | | not run | not run |
| 02-failing-test | Cursor | | | not run | not run |
| 03-secret-in-diff | Claude Code | | | not run | not run |
| 03-secret-in-diff | Codex | | | not run | not run |
| 03-secret-in-diff | Cursor | | | not run | not run |
| 04-over-size-cap | Claude Code | | | not run | not run |
| 04-over-size-cap | Codex | | | not run | not run |
| 04-over-size-cap | Cursor | | | not run | not run |
| 05-wrong-command | Claude Code | | | not run | not run |
| 05-wrong-command | Codex | | | not run | not run |
| 05-wrong-command | Cursor | | | not run | not run |
| 06-broken-build | Claude Code | | | not run | not run |
| 06-broken-build | Codex | | | not run | not run |
| 06-broken-build | Cursor | | | not run | not run |
| 07-keep-project-rule | Claude Code | | | not run | not run |
| 07-keep-project-rule | Codex | | | not run | not run |
| 07-keep-project-rule | Cursor | | | not run | not run |
| 08-piped-curl | Claude Code | | | not run | not run |
| 08-piped-curl | Codex | | | not run | not run |
| 08-piped-curl | Cursor | | | not run | not run |

Record a result as `pass` or `fail` plus one sentence naming the files the
agent changed. Leave `not run` until that sentence exists.
