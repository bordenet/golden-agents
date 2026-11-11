# Design v2

Status: sections A and B are implemented. Sections C-I are not.
No template wording changes are made by this document.
Consumer upgrade steps for the bugfix stack are in `docs/UPGRADE-GUIDE.md`.

Vendor facts below were supplied as verified on 2026-11-10. Re-fetch the linked
pages before implementation if a claim conflicts with the live doc.

Locked and unchanged by this proposal:

- `MAX_GUIDANCE_LINES=250` in `generate-agents.sh`
- `FRAMEWORK_VERSION` is not bumped here
- Items 1-19 stay as committed

## A. Redirect files

Facts:

- Claude Code reads `AGENTS.md` by default only when no `CLAUDE.md` exists above
  the working directory. If `CLAUDE.md` exists, it reads `CLAUDE.md` only. A
  redirect must import with `@AGENTS.md`. A prose link is not an import.
  Imports expand into context, max depth four, and do not reduce context cost.
  https://code.claude.com/docs/en/memory
- Codex reads `AGENTS.md` natively, from project root to cwd, one file per
  directory, 32 KiB default cap (`project_doc_max_bytes`). `CODEX.md` is not
  required. https://developers.openai.com/codex/guides/agents-md
- Copilot docs name `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, and
  `.github/copilot-instructions.md`. `COPILOT.md` and `AGENT.md` do not appear
  in those docs.
  https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions
- Gemini CLI uses `context.fileName` (a list, for example
  `["AGENTS.md","CONTEXT.md","GEMINI.md"]`) and `@file.md` imports inside
  `GEMINI.md`. The setting name is not `contextFileName`.
  https://geminicli.com/docs/cli/gemini-md/
- Cursor reads `AGENTS.md` at the project root as a simple alternative to
  `.cursor/rules`. https://cursor.com/docs/context/rules

Proposal:

- Keep generating `AGENTS.md` as the only full guidance file.
- Keep `CLAUDE.md` only as a one-line import: `@AGENTS.md`, plus the existing
  generated sentinel. Drop the prose "go read AGENTS.md" redirect.
- Stop generating `CODEX.md`, `COPILOT.md`, and `AGENT.md`.
- Keep `GEMINI.md` only when it is an `@AGENTS.md` import, because Gemini's
  default name list includes it. Keep `.github/copilot-instructions.md` as a
  short import-style pointer, not a second copy of the framework.

Tradeoff: fewer files, but a consumer who set Gemini or Copilot to a custom
filename loses that path until they point the setting at `AGENTS.md`. Claude
pays the full `AGENTS.md` token cost through the import. That is the same cost
as today once the prose redirect is replaced by a real import, and it is the
only way Claude sees the file when `CLAUDE.md` exists.

Migration: on upgrade, back up each existing redirect first (item 1 `.bak`
rules). If the file is a generated sentinel or a byte-exact 1.4.x stub, replace
or delete it per the list above. If it has any other content, stop and leave
it. Do not delete `CODEX.md` / `COPILOT.md` / `AGENT.md` that a human wrote.

## B. Template copies instead of `$HOME/.golden-agents`

Today, progressive triggers tell the agent to read
`$HOME/.golden-agents/templates/...`. That path is absent in cloud agents and
CI. `--sync` fast-forwards the golden-agents clone and the next consumer run
picks up those bytes with no review.

Proposal: copy only the modules selected by `--language` and `--type` into the
consumer repo, for example `.golden-agents/modules/<name>.md`, and record
`version` plus a hash of each file next to the item-18 stamp. Triggers point
at those relative paths. `--sync` updates the golden-agents checkout only. It
does not change a consumer until someone runs an explicit upgrade that shows
the hash diff.

Tradeoff: consumer repos gain a few small files and must upgrade on purpose.
They stop depending on a home directory and stop changing because a different
project ran `--sync`.

Migration: upgrade writes the selected modules beside `AGENTS.md` and rewrites
trigger paths inside the framework block. Leave project text outside the
markers alone. Claude treats an import outside the working directory as
external and asks for approval, so the copies must stay inside the consumer
repo. Do not point triggers at `$HOME`.

## C. Scoped rules

Facts and shapes:

- Claude: `.claude/rules/*.md` with `paths:` frontmatter.
- Cursor: `.cursor/rules/*.mdc`. Plain `.md` is ignored. Frontmatter fields
  are `description`, `globs`, and `alwaysApply`.
- Copilot: `.github/instructions/*.instructions.md` with `applyTo:`.

Proposal: for each selected language and project type, emit a scoped rule file
in the formats above whose body is the matching module. Files that should
always load (`invariants`, security) use `alwaysApply: true` or no path
filter. Language modules get a path glob. Delete trigger lines the model
cannot observe. "WHEN conversation exceeds 50 exchanges" is one of those.
Hard gates (lint, test, build) belong in CI or a hook. The prose may name the
command. It should not pretend the model is the enforcer.

Tradeoff: three small formats to keep in sync, and a consumer who does not use
that tool gets an unused directory. The gain is that a Go rule is not loaded
while editing a Markdown file.

Migration: add the rule files on upgrade. Do not delete an existing
`.cursor/rules/*.mdc` or `.claude/rules/*.md` that lacks the generated
sentinel. Old trigger lines inside the framework block are replaced with the
new framework block, which is the current upgrade behavior.

## D. Emphasis

Anthropic's guidance for Opus 4.5 and 4.6 is that the model already attends
to the system prompt, so "CRITICAL: You MUST" should be softened.
https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices

Count in `templates/` at this commit (whole words, case-sensitive). Siren is
U+1F6A8. This doc does not change those files.

| File | CRITICAL | MANDATORY | STOP | Siren |
|------|----------|-----------|------|-------|
| templates/core/anti-slop.md | 1 | 0 | 0 | 0 |
| templates/core/invariants.md | 0 | 0 | 1 | 0 |
| templates/core/superpowers.md | 1 | 0 | 1 | 0 |
| templates/languages/dart-flutter.md | 1 | 0 | 0 | 0 |
| templates/languages/go.md | 1 | 0 | 0 | 0 |
| templates/languages/javascript.md | 1 | 0 | 0 | 1 |
| templates/project-types/cli-tools.md | 0 | 0 | 0 | 1 |
| templates/project-types/web-apps.md | 0 | 1 | 0 | 0 |
| templates/workflows/build-hygiene.md | 2 | 0 | 0 | 0 |
| templates/workflows/deployment.md | 0 | 1 | 0 | 0 |
| templates/workflows/security.md | 1 | 0 | 0 | 0 |
| templates/workflows/testing.md | 1 | 1 | 0 | 1 |
| templates/adopt-prompt.md | 0 | 0 | 1 | 0 |
| Total | 9 | 3 | 3 | 3 |

Keep strong wording only where a wrong action is hard to undo, and put a
one-line reason on that line:

- `templates/workflows/security.md` priority: a leaked secret is not fixed by
  rewriting the sentence later.
- `templates/core/invariants.md` STOP: the size cap exists so agents do not
  grow the file they are reading.
- `templates/adopt-prompt.md` STOP when markers are missing: adopting without
  markers can overwrite project text.
- `templates/workflows/testing.md` "test the code": the gate is "do not claim
  done when tests were not run".
- `templates/languages/go.md` and the matching line in
  `templates/workflows/build-hygiene.md`: `go build` catches compile failures
  that lint does not. Keep one of the two lines, not both at CRITICAL.

Soften or demote the rest to a normal instruction. That includes anti-slop
priority, superpowers bootstrap, dark mode, the JavaScript siren section, the
CLI siren heading, and "CRITICAL FOR LIBRARIES". Those are conventions, not
invariants.

Tradeoff: quieter files are easier to follow and easier to ignore. The
inventory above is the proposed line. Implementation waits for review, and it
edits `templates/` only after that review.

Migration: template edits ship inside the framework block on the next upgrade.
Consumers do not merge template prose by hand.

## E. Superpowers block

Every generated file tells the agent to run
`node ~/.codex/superpowers-augment/superpowers-augment.js bootstrap`. Most
machines do not have that script. The block is inside the framework markers,
so a consumer cannot remove it without the next upgrade putting it back.

Proposal: default off. Add `--superpowers` to place the block outside the
framework markers, after the end marker, so project owners can delete it and
upgrade will not restore it.

Tradeoff: Claude users who want the bootstrap must pass the flag once.
Everyone else stops seeing a command that fails.

Migration: upgrade removes the block from the framework region. If the
consumer passes `--superpowers`, write it below the end marker. If a consumer
already pasted their own bootstrap under the project section, leave that text.

## F. Size

Line count is a weak proxy. Claude's docs describe splitting `CLAUDE.md` and
keeping each file under about 200 lines, with path-scoped rules, because
contradictions are resolved arbitrarily. That 200 is a soft target for this
design discussion. The script lock stays `MAX_GUIDANCE_LINES=250`.

Proposal: measure generated output in tokens as well as lines. Fail a test
when progressive output exceeds 250 lines. Warn in the design and in
`--help` that 200 lines is the soft ceiling for the always-loaded file, and
that overflow belongs in scoped rules (section C), not in a longer
`AGENTS.md`.

Tradeoff: token counts vary by tokenizer. The line ceiling stays the
reproducible check. The 200-line figure is guidance for authors, not a second
constant in the script.

Migration: none until section C exists. Do not lower `MAX_GUIDANCE_LINES`.

## G. Self-maintenance

The self-manage block tells the agent to refactor guidance files when they
exceed 250 lines. An agent that both follows the file and rewrites the file
can change the rules without a review.

Proposal: the agent may draft a diff. It may not apply that diff. A human
merges it. The self-manage text should say that, and it should not say
"no human intervention".

Tradeoff: size overruns sit until someone reviews them. That is the point.

Migration: the self-manage block is already replaced in place on upgrade.
The new wording lands there. Project rules below the end marker are not
edited by the generator.

## H. Quality gates

Gates are currently fixed strings per language (`golangci-lint`, `npm test`,
and so on). A repo that uses `make test` or `uv run pytest` is told to run
the wrong command.

Proposal: before falling back to the template, read in this order:
`package.json` scripts, `Makefile` / `justfile` targets, `pyproject.toml`
`[project.scripts]` and tool config, then CI workflow step names. When a
match is found, emit that command and the file it came from. When nothing
matches, emit the template command prefixed with `UNVERIFIED: confirm`.

Tradeoff: detection will misread a script that is not the real test. The
`UNVERIFIED` prefix makes the guess visible. A wrong detected command is
still a defect, so detection stays conservative: exact script names `lint`,
`test`, `build`, and `coverage` only.

Migration: upgrade regenerates the framework block, so the gates change
there. Project-specific gates below the end marker stay. The first upgrade
after this lands should be reviewed because commands change.

## I. Evidence

Nothing in this repo shows that the generated file changes agent behavior.

Proposal: add a fixture repo and 5 to 10 fixed tasks (one lint failure, one
failing test, one secret in a diff, one file over the size cap, one wrong
language command, and similar). Run each task with and without the generated
files on Claude Code, Codex, and Cursor. Store the score sheet under
`docs/evals/`. Do not claim a default is better until those runs exist.

Tradeoff: the evals cost time and go stale when models change. Date each run
and name the model. A missing eval is not a passing eval.

Migration: none. This does not change consumer files.

## What waits for approval

After this document is accepted:

- `docs/UPGRADE-GUIDE.md` for pre-fix 1.4.x consumers
- A summary table of items 1-19 (status, test, branch, whether `ps1` changed)
- One diff against `main`, then a push of the stacked branches and pull
  requests

`generate-agents.ps1` is a wrapper. Items 18-20 do not change it. It has no
separate defect. It delegates to `generate-agents.sh`. Item 16 still notes
that the wrapper converts only `--path=X` for WSL, not the space form. That
is a note, not a code change.
