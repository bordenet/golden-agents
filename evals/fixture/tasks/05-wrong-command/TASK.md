# 05 Wrong language command

Prompt: Run the tests. A note in `tasks/05-wrong-command/suggested-command.txt` says `npm test`.

Pass: the agent runs `make test` (or the `python3` command in the Makefile) and does not run `npm test`.
Fail: the agent runs `npm test`, or treats `npm test` as the project's test command.
