# Best Practices Sources

This framework incorporates official guidance from:

| Source | Key Concepts |
|--------|--------------|
| [Anthropic Context Engineering](https://www.anthropic.com/engineering/claude-code-best-practices) | CLAUDE.md hierarchy, subagents, explore-plan-code-commit workflow |
| [GitHub Copilot Best Practices](https://docs.github.com/en/copilot/get-started/best-practices) | Prompt engineering, context management, validation |
| [OpenAI Codex Prompting Guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide/) | AGENTS.md specification, tool-use directives, autonomy settings |
| [Gemini Code Assist](https://developers.google.com/gemini-code-assist/docs/use-agentic-chat-pair-programmer) | GEMINI.md context files, MCP integration |
| [Spotify Golden Path](https://engineering.atspotify.com/2020/08/how-we-use-golden-paths-to-solve-fragmentation-in-our-software-ecosystem/) | Standardization philosophy |

---

## How We Implement Each Source

### Anthropic Context Engineering

| Recommendation | Our Implementation |
|----------------|-------------------|
| **CLAUDE.md hierarchy** | Redirect files (CLAUDE.md, GEMINI.md, etc.) are auto-created and point to `Agents.md` |
| **Subagents for complex tasks** | Progressive loading triggers: `🔴 BEFORE writing ANY .go file → cat ~/.golden-agents/templates/languages/go.md`. Each module is a focused "subagent" |
| **Explore-plan-code-commit** | Workflow checklists in generated output. Optional: superpowers skills for enforcement |

**Example from generated output:**

```markdown
## Progressive Module Loading
🔴 BEFORE writing ANY `.go` file → `cat ~/.golden-agents/templates/languages/go.md`
🔴 WHEN tests fail OR after 2+ failed fix attempts → `cat ~/.golden-agents/templates/workflows/testing.md`
```

### GitHub Copilot Best Practices

| Recommendation | Our Implementation |
|----------------|-------------------|
| **Provide context in comments** | Templates include structured headers with project name, languages, type |
| **Break down complex tasks** | Progressive loading splits guidance into focused modules (~20-30 lines each) |
| **Validate AI suggestions** | Workflow checklists include verification gates before commit/PR |

**Example from generated output:**

```markdown
## Quality Gates
Before ANY commit: lint passes, tests pass, no new warnings
Before ANY PR: all of the above + manual review of changes
```

### OpenAI Codex Prompting Guide

| Recommendation | Our Implementation |
|----------------|-------------------|
| **AGENTS.md specification** | CODEX.md redirect auto-created (AGENTS.md skipped to avoid case-sensitivity conflicts with Agents.md) |
| **Tool-use directives** | Templates include explicit tool preferences (e.g., "use `go test`, not `go run`") |
| **Anti-slop guidance** | Banned phrases list in [`templates/core/anti-slop.md`](../templates/core/anti-slop.md) |

**Example from generated output:**

```markdown
## Banned Phrases
Never use: "I'd be happy to", "Certainly!", "Great question!"
Never use: "seamless", "robust", "cutting-edge", "leverage"
```

### Gemini Code Assist

| Recommendation | Our Implementation |
|----------------|-------------------|
| **GEMINI.md context files** | GEMINI.md redirect auto-created, points to `Agents.md` |
| **MCP integration** | Optional superpowers skill for Perplexity research via MCP |
| **Multi-scope context** | Progressive loading: global rules in `Agents.md`, detailed modules in `~/.golden-agents/templates/` |

**How progressive loading works:**

```
my-project/
├── Agents.md           # Global rules (~60 lines) with loading triggers

~/.golden-agents/templates/    # Shared across all projects
├── languages/go.md            # Go-specific guidance
├── languages/python.md        # Python-specific guidance
└── workflows/security.md      # Security checklist
```

### Spotify Golden Path

| Recommendation | Our Implementation |
|----------------|-------------------|
| **Reduce fragmentation** | One canonical `Agents.md` instead of scattered CLAUDE.md, GEMINI.md, AGENTS.md files |
| **Standardization** | Templates in [`templates/`](../templates/) ensure consistent structure across projects |
| **Opt-in adoption** | `--adopt` and `--migrate` flags preserve existing content while adding framework |

**The problem we solve:**

```
Before:                          After:
├── CLAUDE.md (200 lines)        ├── Agents.md (60 lines)
├── GEMINI.md (150 lines)        ├── CLAUDE.md → "See Agents.md"
├── AGENTS.md (180 lines)        ├── GEMINI.md → "See Agents.md"
└── .cursorrules (100 lines)     └── .ai/
                                     ├── go.md
    630 lines, 4 files               └── security.md
    (duplicated, drifting)
                                     ~100 lines total, no duplication
```

---

## Verification

To verify these implementations yourself:

```bash
# Generate a sample and inspect the output
./generate-agents.sh --language=go,python --dry-run --path=/tmp/test

# Inspect templates directly
ls templates/core/
ls templates/languages/
```

