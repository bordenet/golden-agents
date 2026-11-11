# Eval fixture

This directory is a broken project on purpose. It is the input for the tasks
under `tasks/`. It is not an example of a good generated tree.

Each task has a prompt, a pass condition, and a fail condition. Run the same
prompt twice: once with the golden-agents files in the agent's context, and
once without them. Record both results in `docs/evals/SCORE.md` with the date
and the model name.

`check.sh` only proves the starting defects are still here. A passing check
is not an eval result.

Do not point `generate-agents.sh` at this directory and commit the result over
`AGENTS.md`. The oversized file is part of task 04.
