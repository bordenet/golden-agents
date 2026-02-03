# Test Coverage

Golden Agents is tested on every commit. Here's what we verify.

---

## Test Summary

| Category | Tests | What We Verify |
|----------|-------|----------------|
| **Data Safety** | 6 | Your existing content is never lost during migrations or upgrades |
| **Size Limits** | 7 | Generated files stay under 100 lines (usable by AI assistants) |
| **End-to-End Scenarios** | 5 | Complete workflows work from start to finish |
| **Argument Parsing** | 17 | CLI flags work correctly, errors are clear |
| **Mode Detection** | 7 | Correct mode chosen based on existing files |
| **Migrations** | 10 | CLAUDE.md/GEMINI.md content preserved |
| **Adoptions** | 12 | Existing Agents.md content preserved |
| **Upgrades** | 10 | Framework updates don't lose project rules |
| **Deduplication** | 12 | Bloated project sections handled correctly |
| **Generation** | 10 | Core output generation works correctly |
| **Templates** | 8 | Template files are valid and accessible |
| **Sync** | 2 | Template updates from GitHub work |
| **Edge Cases** | 6 | Unicode, spaces in paths, special characters |
| **Windows** | 15 | PowerShell wrapper works correctly |

**Total: 127 tests** (112 BATS + 15 Pester)

---

## Key Guarantees

### 1. Zero Data Loss

Every migration, adoption, and upgrade operation is tested to ensure your existing content is preserved:

- Unique content markers are verified before and after
- Backup files are created automatically
- Backups are verified byte-for-byte identical to originals

### 2. Usable Output Size

Generated files are tested to stay within limits AI assistants can actually follow:

- Progressive mode: **< 100 lines** (hard limit)
- Even with all 5 languages enabled: stays under limit

### 3. Cross-Platform

Tests run on:
- Linux (CI)
- macOS (CI)
- Windows via PowerShell wrapper (Pester tests)

---

## Running Tests Locally

```bash
# Full test suite
bats test/*.bats

# Quick validation
bats test/scenarios.bats test/data-loss.bats test/size-limits.bats
```

---

## CI Status

Tests run automatically on every push and pull request.

[![Tests](https://github.com/bordenet/golden-agents/actions/workflows/test.yml/badge.svg)](https://github.com/bordenet/golden-agents/actions/workflows/test.yml)

