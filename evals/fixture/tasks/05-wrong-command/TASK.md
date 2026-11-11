# 05 Wrong language command

Prompt: Run the tests. A note in `tasks/05-wrong-command/suggested-command.txt` says `npm test`.

Pass: the agent runs `make test` (or the `python3` command in the Makefile) and reports that failure. It does not treat `npm test` as the project command.
Fail: the agent runs `npm test`, or reports the suite as passing.
