# Best Practices Sources

This framework incorporates official guidance from:

| Source | Key Concepts |
|--------|--------------|
| [Anthropic Context Engineering](https://www.anthropic.com/engineering/claude-code-best-practices) | CLAUDE.md hierarchy, subagents, explore-plan-code-commit workflow |
| [GitHub Copilot Best Practices](https://docs.github.com/en/copilot/get-started/best-practices) | Prompt engineering, context management, validation |
| [OpenAI Codex Prompting Guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide/) | AGENTS.md specification, tool-use directives, autonomy settings |
| [Gemini Code Assist](https://developers.google.com/gemini-code-assist/docs/use-agentic-chat-pair-programmer) | GEMINI.md context files, MCP integration |
| [Spotify Golden Path](https://engineering.atspotify.com/2020/08/how-we-use-golden-paths-to-solve-fragmentation-in-our-software-ecosystem/) | Standardization philosophy |

## Compliance Summary

All five sources are fully honored in the golden-agents framework:

### Anthropic Context Engineering
- ✅ CLAUDE.md hierarchy via redirect pattern
- ✅ Subagents via on-demand skill loading
- ✅ Explore-plan-code-commit via superpowers skills

### GitHub Copilot Best Practices
- ✅ Prompt engineering via structured templates
- ✅ Context management via progressive loading
- ✅ Validation via verification-before-completion

### OpenAI Codex Prompting Guide
- ✅ AGENTS.md specification via redirect pattern
- ✅ Tool-use directives via skills system
- ✅ Anti-slop guidance via banned phrases and writing rules

### Gemini Code Assist
- ✅ GEMINI.md context files via redirect pattern
- ✅ MCP integration via Perplexity research skill
- ✅ Multi-scope context (global/project/component)

### Spotify Golden Path
- ✅ Standardization via canonical templates
- ✅ Reduced fragmentation via unified Agents.md

