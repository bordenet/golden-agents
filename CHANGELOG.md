# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

