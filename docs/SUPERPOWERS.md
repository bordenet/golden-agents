# Superpowers Integration

Golden Agents optionally integrates with skill-based AI workflow tools. **Superpowers is NOT required** — all generated Agents.md files include self-contained workflow checklists that work with any AI assistant.

## Available Skill Frameworks

| Framework | What It Provides | Install |
|-----------|------------------|---------|
| [obra/superpowers](https://github.com/obra/superpowers) | Core skills: brainstorming, TDD, debugging, verification | See setup below |
| [bordenet/superpowers-plus](https://github.com/bordenet/superpowers-plus) | Extended: slop detection, security upgrades, code review | Adds to ~/.codex/skills/ |

## Quick Setup

```bash
# 1. Install obra/superpowers (core skills)
git clone https://github.com/obra/superpowers.git ~/.codex/superpowers

# 2. Create augment adapter (if using Augment)
mkdir -p ~/.codex/superpowers-augment
cat > ~/.codex/superpowers-augment/superpowers-augment.js << 'EOF'
// Adapter for Augment - see obra/superpowers for full implementation
const action = process.argv[2];
if (action === 'bootstrap') console.log('Superpowers loaded');
if (action === 'use-skill') console.log(`Loading skill: ${process.argv[3]}`);
EOF

# 3. (Optional) Add extended skills
git clone https://github.com/bordenet/superpowers-plus.git /tmp/sp-plus
cp -r /tmp/sp-plus/skills/* ~/.codex/skills/
```

## Key Skills

| Skill | When to Use |
|-------|-------------|
| `superpowers:brainstorming` | Before ANY creative/feature work |
| `superpowers:systematic-debugging` | Before fixing bugs |
| `superpowers:test-driven-development` | Before writing implementation |
| `superpowers:verification-before-completion` | Before claiming done |
| `detecting-ai-slop` | Analyze text for AI slop density |
| `security-upgrade` | Scan and fix dependency vulnerabilities |

If not installed, the inline checklists in generated Agents.md provide equivalent guidance.

