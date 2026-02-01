# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.1] - 2026-02-01

### Added

- **Cross-platform documentation** - Clear platform support in README and --help
- **Windows installation guide** - WSL, Git Bash, MSYS2, Cygwin instructions
- **Platform support table** - Linux, macOS, Windows WSL, Windows Native

### Documentation

- README: Added Platform Support section at top
- README: Added Windows Installation section with step-by-step instructions
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

- **AI guidance files** - Agents.md, CLAUDE.md, CODEX.md, GEMINI.md, COPILOT.md for this repo
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
  - `--compact` - Generate minimal ~130 line version
  - `--sync` - Update templates from GitHub
  - `--dry-run` - Preview without writing
- **Agents.core.md** - Pre-generated standalone compact version

### Features

- **6:1 compaction ratio** - Compact mode (~130 lines) vs full mode (~800 lines)
- **Self-contained output** - Generated files have no external dependencies
- **Multi-language support** - Combine multiple language templates
- **Superpowers integration** - Bootstrap instructions for obra/superpowers
- **Context engineering** - Based on Anthropic's best practices

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

