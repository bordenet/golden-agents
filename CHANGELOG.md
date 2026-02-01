# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

