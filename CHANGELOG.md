# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Stamp on upgrade when missing** - `--upgrade` inserts
  `<!-- golden-agents:stamp version=VER updated=TODAY -->` immediately before
  the framework start marker when the file has no stamp. An existing stamp
  still keeps its date and version when the framework block is unchanged, and
  bumps both when that block changes.
- **Clearer redirect preview** - Kept redirects that already exist preview as
  `would rewrite … to @AGENTS.md import (kept redirect; replaces old stub)`.
  Missing kept redirects stay `would write … (@AGENTS.md import)`. Retired
  generated stubs preview as `would remove … (matches old generated stub;
  AGENT.md/CODEX.md/COPILOT.md are retired)` and apply as
  `removed … (matched old generated stub; retired redirect)`.
- **`--self-test`** - Verifies the golden-agents checkout before consumers
  upgrade: each `lib/golden-agents/part*.sh` is at least 1000 bytes, the head
  is not a truncated path stub, `bash -n` passes, and `--version` runs.
  `--upgrade` runs the same checks automatically. `docs/UPGRADE-GUIDE.md`
  section 0 documents the flow.
- **`--no-backup`** - Skips `.bak` / `AGENTS.md.backup` writes for batch
  `--upgrade` / `--adopt` / `--migrate` runs that already made section 2
  timestamped backups.
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

### Changed

- **Upgrade guide** - Documents hand-written lines moving out of markers,
  verify steps for that case, section 7 on mirrors / Copilot /
  context-management / review cost, and the no-manifest
  `UNVERIFIED: confirm` gate note. README Copilot row notes the kept path
  is `.github/copilot-instructions.md`, not `COPILOT.md`.

### Fixed

- **Upgrade keeps hand-written lines inside the managed block** - Non-empty
  lines between the framework markers that do not appear in the upgraded
  file used to disappear silently. They are appended once just after
  `<!-- GOLDEN:framework:end -->`. Preview prints
  `preserving N hand-written line(s) from inside managed block → after end
  marker:` and lists each line. Bootstrap and custom-gate relocates are
  skipped when already present. A second upgrade does not duplicate them.
  Numbered Lint/Build/Test/Coverage gates are no longer relocated; upgrade
  replaces them. `stamp.bats` and `size-limits.bats` assert the managed
  block under that policy.
- **Committed executable bits** - `generate-agents.sh` and
  `lib/golden-agents/part*.sh` are stored with mode `100755` so consumer
  fleet upgrades do not fail with exit 127 on a clean checkout.
- **Gates left unset wording** - Preview text states the language remains
  selected when template gates are omitted because a project manifest defines
  no matching lint/build/test, so a line like `shell` no longer reads as
  "shell is absent from the repo".
- **Tests exec the generator** - Even when a checkout lacks `+x`, `bats` must
  not get "permission denied" or exit 127. The test helper chmods the entry
  and `part*.sh`, and routes through `test/.generate-via-bash` (gitignored).
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
  `--upgrade` keeps the previous stamp date and version when the framework block
  bytes are unchanged, and sets `updated` to today and `version` to
  `FRAMEWORK_VERSION` when those bytes change.
- **Upgrade guide** - `docs/UPGRADE-GUIDE.md` tells a consumer-repo agent how to
  detect 1.4.x (stamp, or Generated by plus framework markers), back up
  guidance files, upgrade without dropping the project section, and stop
  before restoring a stubbed redirect. `docs/SUMMARY.md` lists items 1-21.
- **PowerShell comma lists** - `generate-agents.ps1` restores commas in
  `--language` and `--type` values. PowerShell turns an unquoted
  `--language=go,python` into `--language=go python` before the wrapper sees
  it, and the shell script then rejected that as an unknown language.
- **Stale test totals** - AGENTS.md, docs/USAGE.md, docs/TEST-PLAN.md, and the
  GitHub Actions summary no longer hardcode a BATS count. They say to run
  `bats test/*.bats`. Removed the duplicate Anti-Slop section from this repo's
  AGENTS.md. `--help` now requires Bash 3.2+. Historical changelog counts are
  unchanged.

---

## [1.4.3] - 2026-02-02

### Added

- **Metrics reporting in prompts** - MIGRATION-PROMPT.md now includes:
  - Original file line count
  - 10-word test for evaluating content
  - Target size table (Simple: 0-20, Moderate: 20-50, Complex: 50-100 lines)
  - Metrics summary template for AI to report reduction percentage
- **STDOUT metrics** - `--migrate` now shows source file line count and target range

---

## [1.4.2] - 2026-02-02

### Changed

- **BREAKING: Progressive mode is now the default** - Generates ~60 lines with on-demand template loading
  - Progressive mode uses `$HOME/.golden-agents/templates/` for just-in-time guidance loading
  - Full mode (~800 lines) deprecated - AI assistants cannot follow instructions that long
- **`--full` flag deprecated** - Prints warning about generating unusable output
- **Upgrade auto-converts legacy files** - Files without mode indicator convert to progressive

### Fixed

- Fundamentally broken default mode - 800+ line files defeat the entire purpose of AI guidance
  - AI assistants ignore or misprocess bloated instruction files
  - Progressive loading is the only viable approach at scale

---

## [1.4.1] - 2026-02-02

### Changed

- **Superpowers now optional** - Framework no longer requires obra/superpowers to be installed
  - All generated AGENTS.md files now include inline workflow checklists as fallback
  - Superpowers remains available as an optional enhancement for Claude users
  - Works with any AI assistant (Gemini, Copilot, Cursor, etc.) out of the box

### Fixed

- Framework was delivering "a dud" for users without superpowers (99% of users)

---

## [1.4.0] - 2026-02-01

### Added

- **Multi-assistant redirect files** - Generator now creates redirect files for all major AI coding assistants:
  - `CLAUDE.md` → Claude Code
  - `CODEX.md` → OpenAI Codex CLI
  - `AGENT.md` → Amp by Sourcegraph
  - `GEMINI.md` → Google Gemini Code Assist
  - `COPILOT.md` → GitHub Copilot
  - `.github/copilot-instructions.md` → GitHub Copilot custom instructions
- **Best practices documentation** - README now cites official guidance from:
  - Anthropic Context Engineering
  - GitHub Copilot Best Practices
  - OpenAI Codex Prompting Guide
  - Gemini Code Assist documentation

### Changed

- Version tests now use flexible pattern matching (no hardcoded version)
- Directory structure in README updated to show all redirect files

### Fixed

- AGENTS.md no longer created as redirect (conflicts with AGENTS.md on case-insensitive filesystems)

### Documentation

- README: Added "Supported AI Coding Assistants" table
- README: Added "Best Practices Sources" section with citations

---

## [1.3.0] - 2026-02-01

### Added

- **GitHub Actions CI/CD** - Automated testing on push/PR to main
  - BATS tests on Linux and macOS
  - BATS tests on Windows via Git Bash
  - Pester tests on all platforms
  - ShellCheck linting
- **PowerShell test suite** - 14 Pester tests for `generate-agents.ps1` wrapper
- **Edge case tests** - 6 new BATS tests for boundary conditions
  - Unicode characters in project names
  - Spaces in paths
  - Special characters in project names
  - Empty/long project names
  - Read-only directory handling
- **Test badge** - README now shows CI status

### Changed

- Improved sync test to handle uncommitted changes gracefully
- Updated TEST-PLAN.md with comprehensive coverage

### Documentation

- README: Added Testing section with test matrix and local run instructions
- README: Updated directory structure to show .github/, docs/, test/ directories

---

## [1.2.1] - 2026-02-01

### Added

- **Cross-platform documentation** - Clear platform support in README and --help
- **Windows installation guide** - WSL, Git Bash, MSYS2, Cygwin instructions
- **Platform support table** - Linux, macOS, Windows WSL, Windows Native
- **PowerShell wrapper** - `generate-agents.ps1` auto-detects WSL or Git Bash

### Documentation

- README: Added Platform Support section at top
- README: Added Windows Installation section with step-by-step instructions
- README: Added PowerShell wrapper option for Windows users
- --help: Added PLATFORM SUPPORT section with requirements
- --help: Added Windows-specific examples

---

## [1.2.0] - 2026-02-01

### Added

- **Safe upgrade system** - `--upgrade` and `--apply` flags for marker-based updates
- **Framework markers** - `<!-- GOLDEN:framework:start -->` and `<!-- GOLDEN:framework:end -->`
- **Backup on upgrade** - Creates `.backup` before modifying files
- **Dry-run by default** - `--upgrade` shows diff without writing

### Changed

- Renamed `seed.sh` to `generate-agents.sh` for clarity
- Improved error messages for upgrade failures

---

## [1.1.0] - 2026-02-01

### Added

- **AI guidance files** - AGENTS.md, CLAUDE.md, CODEX.md, GEMINI.md, COPILOT.md for this repo
- **5 AI assistants** - Support for Claude Code, Augment Code, OpenAI Codex CLI, Gemini, GitHub Copilot

---

## [1.0.0] - 2026-02-01

### Added

- Initial release of Golden Agents Framework
- **Core templates**: superpowers.md, communication.md, anti-slop.md
- **Language templates**: Go, Python, JavaScript, Shell, Dart/Flutter
- **Project type templates**: CLI tools, web apps, mobile apps, genesis tools
- **Workflow templates**: testing, security, deployment, context-management, build-hygiene, session-resumption
- **seed.sh generator** with options:
  - `--language` - Select language templates (comma-separated)
  - `--type` - Select project type template
  - `--sync` - Update templates from GitHub
  - `--dry-run` - Preview without writing

### Features

- **Self-contained output** - Generated files have no external dependencies
- **Multi-language support** - Combine multiple language templates
- **Superpowers integration** - Bootstrap instructions for obra/superpowers
- **Context engineering** - Based on Anthropic's best practices

> **Note:** v1.0.0 shipped with full mode (~800 lines) as default. This was deprecated in v1.4.2
> because AI assistants cannot follow instructions that long. Use progressive mode (default since v1.4.2).

### Templates Included

| Category | Templates |
|----------|-----------|
| Core | superpowers, communication, anti-slop |
| Languages | go, python, javascript, shell, dart-flutter |
| Project Types | cli-tools, web-apps, mobile-apps, genesis-tools |
| Workflows | testing, security, deployment, context-management, build-hygiene, session-resumption |

---

## Future Versions

### Planned for [1.1.0]

- [ ] Rust language template
- [ ] Java/Kotlin language template
- [ ] API-first project type
- [ ] Microservices project type
- [ ] GitHub Actions workflow template

### Planned for [2.0.0]

- [ ] Interactive mode (`seed.sh --interactive`)
- [ ] Project detection (auto-detect language from files)
- [ ] Template inheritance system
- [ ] VS Code extension integration

