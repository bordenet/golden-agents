# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Upgrade guide matches the generator** - `docs/UPGRADE-GUIDE.md` no longer
  says design v2 is unimplemented. It names what `--upgrade --apply` writes,
  and it says not to run that upgrade against this repo's own `AGENTS.md`.
  `docs/SUMMARY.md` item 20 points at the section tests. The Cursor column
  of the score sheet records one run. Claude Code and Codex stay `not run`.
- **Eval fixture** - `evals/fixture/` holds eight fixed tasks: a lint failure,
  a failing test, a secret in a diff, a file over the 250-line cap, a wrong
  test command, a broken build, a project rule that must survive, and a
  piped curl. `docs/evals/SCORE.md` is the score sheet. A missing run is
  not a pass. Task 05 passes when the agent runs `make test` and does not
  run `npm test`.
- **Upgrade keeps a stated gate** - `--upgrade` no longer rewrites a command
  already in the quality-gate block into `UNVERIFIED: confirm` when
  detection finds nothing. A command is kept when it is that language's
  template command, or when it matches no selected template. A language
  with no command is omitted and named under `Gates left unset`. A new
  file still marks unmatched template commands unverified.
- **Detected quality gates** - Before using a template command, generation
  reads `package.json` scripts, `Makefile` and `justfile` targets,
  `pyproject.toml` `[project.scripts]`, then GitHub Actions step names.
  Only the names `lint`, `test`, `build`, and `coverage` match. A match
  is written with the file it came from. Anything else keeps the template
  command prefixed with `UNVERIFIED: confirm`.
- **Size and self-maintenance** - Generation and upgrade print a token
  estimate (file bytes divided by 4). `--help` names 200 lines as the soft
  ceiling for the always-loaded file and keeps the 250-line lock. The
  self-manage block tells the agent to draft a diff and wait for a human
  to merge it.
- **Superpowers is opt-in** - The bootstrap command is omitted unless the run
  passes `--superpowers`. The block is written after the framework end
  marker, so a later upgrade does not put it back. A bootstrap already
  present below that marker is left in place.
- **Quieter templates** - Strong wording stays on the security priority, the
  invariants size cap, the adopt-prompt marker check, the testing "done"
  gate, and one `go build` line. Each of those lines says why. Anti-slop,
  superpowers, dark mode, the JavaScript click-handler section, the CLI
  heading, library exports, deployment, and the duplicate build line are
  ordinary instructions.
- **Scoped rules** - Progressive generation writes the language module into
  `.claude/rules/`, `.cursor/rules/*.mdc`, and
  `.github/instructions/*.instructions.md`, with a path glob. Invariants,
  security, and the project type always load. A hand-written rule without
  the generated sentinel is left in place. The "conversation exceeds 50
  exchanges" trigger is gone. Quality gates name the commands and say they
  belong in CI or a hook.
- **In-repo modules** - Progressive generation copies the selected language
  module, the project-type module, and the workflow modules named by the
  triggers into `.golden-agents/modules/`. Triggers read those paths.
  `<!-- golden-agents:modules ... -->` records the sha256 of each file next
  to the stamp. `--sync` still updates this checkout only. `--upgrade`
  previews hash changes and `--upgrade --apply` writes them.
- **Redirect imports** - Fresh generation and `--upgrade --apply` write `CLAUDE.md`
  and `GEMINI.md` as `@AGENTS.md`, and `.github/copilot-instructions.md` as
  `@../AGENTS.md`, each with the generated sentinel. `CODEX.md`, `AGENT.md`,
  and `COPILOT.md` are no longer created. A generated copy or a 1.4.x stub of
  those three is backed up and removed. A hand-written copy stays.
- **Cloud-agent GitHub rules** - `.ai-guidance/github-ops.md` records how to change
  this repo from a container: authenticated `gh`, `git`, or the API, never the
  container browser. `gh api --method DELETE` must pass `--input /dev/null` or
  it opens `$EDITOR`. HTTP 422 on that call means the ref is already gone.

### Fixed

- **Tests exec the generator** - `generate-agents.sh` is stored without the
  executable bit, so `bats` got "permission denied" and the Tests workflow
  failed on Linux, macOS, and coverage. The test helper sets the bit before
  the suite runs.
- **Gate detection on Windows** - Quality-gate detection looked only for
  `python3`. Git Bash on Windows often has `python` or `py -3` instead, so
  package.json and Makefile gates fell through to the template. Detection
  now tries those names in order.
- **Windows BATS does not cancel required jobs** - A failing Windows step
  was cancelling the still-queued macOS Pester job even with
  `continue-on-error`. That step now records the failure and exits 0.
- **Upgrade keeps project quality gates** - A numbered gate whose label is
  not Lint, Build, Test, or Coverage used to disappear when the framework
  was regenerated. That block is moved to just after the framework end
  marker. A second upgrade does not copy it again.
- **Upgrade reads `**Languages:**`** - A header with the colon inside the
  bold markers, `> **Languages:** python`, was ignored, so upgrade stopped
  and asked for `--language`. Both that form and `> **Languages**: python`
  are read. The same applies to `Type`.
- **A manifest does not invent a missing gate** - When `package.json`, a
  Makefile, a justfile, `pyproject.toml`, or a workflow file is present,
  a lint, build, or test name it does not define is omitted, and so is a
  coverage percentage the manifest does not define. A directory with no
  manifest still marks the template command unverified.
- **A second upgrade leaves a finished redirect alone** - A kept redirect
  that already matches the `@AGENTS.md` import is not backed up again.
- **The generator is stored in pieces** - `generate-agents.sh` sources
  `lib/golden-agents/part*.sh`. The pieces are split on function boundaries.
  A single upload of the whole script was stored truncated, so the entry
  point stays small.
- **Upgrade keeps coverage prose** - A coverage gate written as
  `Minimum 70%. Follow the policy...` has no backtick command, so upgrade
  used to replace the whole line with `Minimum 70%`. The words after
  `**Coverage**:` are now kept. A backtick coverage command still wins.
- **Upgrade keeps an in-framework bootstrap** - A 1.4.x file stores the
  superpowers bootstrap inside the framework markers. `--upgrade` used to
  delete that text unless the run passed `--superpowers`. The bootstrap is
  now moved to just after `<!-- GOLDEN:framework:end -->` and kept. A file
  that never had the bootstrap still does not gain one. A second upgrade
  does not duplicate it.
- **Redirect overwrite (data loss)** - Plain generation no longer overwrites hand-written
  CLAUDE.md, CODEX.md, AGENT.md, GEMINI.md, COPILOT.md, .github/copilot-instructions.md,
  or any existing AGENTS.md. It lists the blocking files, writes nothing, and exits 1.
  `--adopt` and `--migrate` back each one up to `<file>.<YYYYmmdd-HHMMSS>.bak` first.
  Generated redirects now end with `<!-- golden-agents:generated -->`; exact 1.4.x stubs
  are also recognized. Replaces the ">100 bytes means real content" heuristic.
- **`--migrate` AGENTS.md loss** - `--migrate` now backs up an existing AGENTS.md (with or
  without markers) to `AGENTS.md.<YYYYmmdd-HHMMSS>.bak` before replacing it. Previously the
  only copy was the gitignored MIGRATION-PROMPT.md, or nothing when markers were present.
- **`.ai-guidance/invariants.md` overwrite** - `--upgrade --apply` on a bloated AGENTS.md
  no longer replaces an existing `.ai-guidance/invariants.md` with the template.
- **Case-insensitive double detection** - On case-insensitive filesystems a single
  AGENTS.md or Agents.md was detected under both names, so MIGRATION-PROMPT.md contained
  its content twice. Agents.md is now only counted when it is a different file (`-ef`).
- **.gitignore corruption** - Appending to a .gitignore without a trailing newline joined
  entries (`dist` became `distMIGRATION-PROMPT.md`). All four append sites now use one
  helper that adds the missing newline first.
- **MIGRATION-PROMPT.md formatting** - Removed literal backslash-backticks from the prompt
  text. The Existing Content fence is now longer than the longest backtick run in the
  embedded content, so code blocks in the original file no longer close it early.
- **Missing invariants file** - Generated AGENTS.md tells agents to load
  `.ai-guidance/invariants.md`, but only the modular migration path created it. Fresh
  generation (plain, `--adopt`, `--migrate`) and `--upgrade --apply` now create it from the
  template when absent and never overwrite it.
- **Conflicting size limits** - The script used 150 lines for AGENTS.md (self-manage block,
  migration prompt, upgrade bloat check) while README, AGENTS.md and the templates said
  250. The limit is now `MAX_GUIDANCE_LINES=250`, defined once, and `test/thresholds.bats`
  checks that every output and doc states the same value. Removed the nonexistent
  "Compact" mode from AGENTS.md.
- **Upgrade header parse** - `--upgrade` took Languages and Type from the first line
  containing those words anywhere (a stray "Type of thing: no." became the project type).
  It now reads only the generated `> **Languages**:` and `> **Type**:` header lines, and
  escapes the marker strings before using them in sed addresses.
- **Upgrade dropped blank lines** - The first `--upgrade --apply` removed blank lines around
  the self-manage block and at the end of the project section, because each region passed
  through command substitution. The upgraded file is now streamed: content outside the
  framework markers and the self-manage block is kept byte-for-byte, and the self-manage
  block is replaced in place.
- **Silent `--dedupe` failure** - An AGENTS.md with the start marker but no end marker made
  `--dedupe` exit 1 with no output. It now prints which marker is missing.
- **`--dedupe --path=.` rejected** - `--dedupe` treated `--path=.` as "no path given".
  It now tracks whether `--path` was passed.
- **Multi-language gates** - `--language=go,python,javascript` emitted lint/build/test gates
  for Go only. Multi-language output now has one labeled gate sub-list per language.
  If that would push the file past 100 lines (five languages), it shows the first
  language's gates and names the others. Single-language output is unchanged.
- **"Minimum N/A%" coverage** - Languages without a coverage target (shell) no longer get a
  Coverage gate line.
- **Unknown `--language` / `--type` accepted** - Values with no template (for example
  `--language=rust`, `--type=bogus`) generated a file and exited 0. They now fail with
  exit 1 and the list of valid values read from `templates/`.
- **Space-separated option values** - `--path ./x` failed with "Unknown option". `--language`,
  `--type`, `--path` and `--name` now accept a space or `=`; a missing value fails with
  "<option> requires a value".
- **`--sync` rebased local history** - `--sync` ran `git pull --rebase origin main`. It now
  runs `git fetch origin main` and `git merge --ff-only`, and refuses when tracked files
  have uncommitted changes. docs/HOW-IT-WORKS.md no longer claims the script never uses
  the network. The sync test no longer runs against this checkout.
- **Visible Last Updated line** - Fresh AGENTS.md files now carry
  `<!-- golden-agents:stamp version=<FRAMEWORK_VERSION> updated=YYYY-MM-DD -->`
  instead of `> **Last Updated**:`. Generated by, Languages, and Type stay visible.
  `--upgrade` keeps the previous stamp date and vers