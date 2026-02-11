# Agent Specification Standard

> **Priority**: HIGH - Define agents explicitly before implementation
> **Source**: Industrial-strength agent framework requirements

## Agent Definition Template

Every agent in a project MUST be defined with these sections:

### 1. Identity

```markdown
## Agent: [Name]

**Purpose**: [One sentence describing what this agent does]
**Owner**: [Team or individual responsible]
**Domain**: [Bounded context this agent operates in]
**Version**: [Semantic version if applicable]
```

### 2. Capabilities Matrix

Define what the agent CAN and CANNOT do:

```markdown
### Capabilities

| Action | Allowed | Constraints |
|--------|---------|-------------|
| Read files | ✅ | Only within project directory |
| Write files | ✅ | Requires user confirmation for new files |
| Execute commands | ✅ | Only whitelisted commands |
| Network requests | ❌ | Not permitted |
| Access secrets | ❌ | Must use environment variables |
```

### 3. Tools & Integrations

List all tools the agent can use:

```markdown
### Tools

| Tool | Purpose | Rate Limit | Auth Required |
|------|---------|------------|---------------|
| `codebase-retrieval` | Search code | None | No |
| `file-edit` | Modify files | None | No |
| `shell` | Run commands | 10/min | No |
| `github-api` | Repo operations | 5000/hr | Yes (token) |
```

### 4. Inputs/Outputs Schema

Define structured expectations:

```markdown
### Inputs

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `query` | string | Yes | Non-empty, <1000 chars |
| `context` | object | No | Valid JSON |

### Outputs

| Field | Type | Description |
|-------|------|-------------|
| `result` | string | The agent's response |
| `confidence` | number | 0.0-1.0 confidence score |
| `sources` | array | References used |
```

### 5. Operating Constraints

```markdown
### Constraints

**Safety**:
- Never execute destructive commands without confirmation
- Never expose secrets in output
- Sanitize all user inputs

**Security**:
- Validate all file paths (no path traversal)
- Reject requests outside project scope
- Log all privileged operations

**Privacy**:
- User data stays local (no external transmission)
- PII must be redacted in logs
- Session data cleared on exit

**Performance**:
- Response timeout: 30 seconds
- Max output size: 100KB
- Max context window: 128K tokens

**Cost**:
- Prefer smaller models for simple tasks
- Cache repeated queries
- Batch operations where possible
```

### 6. Reasoning Style

```markdown
### Reasoning Patterns

**Task Decomposition**:
1. Break complex tasks into steps
2. Validate each step before proceeding
3. Checkpoint progress for resumption

**Escalation Rules**:
- After 3 failed attempts → Ask user for guidance
- After 5 minutes on single task → Report status
- On ambiguous requirements → Clarify before proceeding

**Clarification Protocol**:
- State what you understood
- List specific questions
- Propose default if no response
```

### 7. Testing & Verification

```markdown
### Verification

**Pre-completion Checklist**:
- [ ] All acceptance criteria met
- [ ] Tests pass locally
- [ ] No regressions introduced
- [ ] Documentation updated

**Validation Commands**:
```bash
npm test                    # Unit tests
npm run lint               # Code quality
npm run e2e                # Integration tests
```

**Output Validation**:
- Response matches expected schema
- No banned phrases present
- Confidence score above threshold
```

---

## Example: Code Review Agent

```markdown
## Agent: CodeReviewer

**Purpose**: Review pull requests for quality, security, and style
**Owner**: @platform-team
**Domain**: Code review and quality assurance
**Version**: 1.0.0

### Capabilities

| Action | Allowed | Constraints |
|--------|---------|-------------|
| Read PR diff | ✅ | Current PR only |
| Comment on PR | ✅ | Max 50 comments |
| Request changes | ✅ | Requires justification |
| Approve PR | ❌ | Human approval required |
| Merge PR | ❌ | Never |

### Tools

| Tool | Purpose | Rate Limit |
|------|---------|------------|
| `github-api` | Read PR, post comments | 100/review |
| `codebase-retrieval` | Find related code | None |

### Inputs

| Field | Type | Required |
|-------|------|----------|
| `pr_url` | string | Yes |
| `focus_areas` | array | No |

### Outputs

| Field | Type | Description |
|-------|------|-------------|
| `summary` | string | Overall assessment |
| `issues` | array | List of findings |
| `recommendation` | enum | approve/request_changes/comment |

### Constraints

- Never approve without human review
- Flag security issues as blocking
- Limit nitpicks to 3 per review

### Reasoning

- Start with security scan
- Then check test coverage
- Finally review style/patterns
- Escalate if >100 files changed
```

---

## Anti-Patterns

❌ **Vague capabilities**: "Can do most things"
❌ **Missing constraints**: No limits defined
❌ **Implicit tools**: Using tools without declaring them
❌ **No escalation**: Agent loops forever on hard problems
❌ **No verification**: Claiming done without checks

