sync_scoped_rules() {
    local mode="$1"
    local name body rule_mode glob tool dest front tmp
    while read -r name body rule_mode glob; do
        [[ -n "$name" ]] || continue
        for tool in claude cursor copilot; do
            dest=$(rule_dest "$tool" "$name")
            if [[ -e "$dest" ]] && ! rule_owned "$dest"; then
                if [[ "$mode" == "preview" ]]; then
                    echo "  would leave ${dest#"$OUTPUT_PATH"/} (hand-written)"
                else
                    echo "  left ${dest#"$OUTPUT_PATH"/} (hand-written)"
                fi
                continue
            fi
            front=$(rule_frontmatter "$tool" "$rule_mode" "$glob" "$name")
            if [[ "$mode" == "preview" ]]; then
                tmp=$(mktemp)
                render_rule "$tmp" "$front" "$body"
                if [[ -f "$dest" ]] && cmp -s "$tmp" "$dest"; then
                    echo "  unchanged ${dest#"$OUTPUT_PATH"/}"
                elif [[ -f "$dest" ]]; then
                    echo "  would update ${dest#"$OUTPUT_PATH"/}"
                else
                    echo "  would write ${dest#"$OUTPUT_PATH"/}"
                fi
                rm -f "$tmp"
            else
                render_rule "$dest" "$front" "$body"
                echo "  wrote ${dest#"$OUTPUT_PATH"/}"
            fi
        done
    done < <(each_scoped_rule)
}

# superpowers_block
# The opt-in bootstrap. It is written after the framework end marker so a
# later upgrade does not restore it.
# Arguments: none
# Returns: The block via stdout
superpowers_block() {
    cat << 'EOF'

### Optional: Superpowers integration

Two parallel, mutually exclusive skill ecosystems exist. At the **START of every conversation**, detect which THIS machine uses and bootstrap accordingly:

- **superpowers-acme**: No bootstrap required (skills are pre-deployed as symlinks).
- **superpowers-plus**: Run the js bootstrap:
  ```bash
  node ~/.codex/superpowers-augment/superpowers-augment.js bootstrap
  ```

This loads available skills into the environment. To load a specific skill manually (plus only):
```bash
node ~/.codex/superpowers-augment/superpowers-augment.js use-skill <name>
```
EOF
}

# place_superpowers_block <file>
# Inserts the bootstrap immediately after the framework end marker when the
# text below that marker does not already contain the bootstrap command.
# Arguments:
#   $1 - AGENTS.md path
# Returns: 0
place_superpowers_block() {
    local file="$1"
    if awk -v mark="$MARKER_END" '
        index($0, mark) { seen = 1; next }
        seen && index($0, "superpowers-augment.js bootstrap") { found = 1 }
        END { exit !found }
    ' "$file"; then
        return 0
    fi
    local tmp block
    tmp=$(mktemp)
    block=$(mktemp)
    superpowers_block > "$block"
    MARK="$MARKER_END" BLOCK="$block" awk '
        { print }
        !done && index($0, ENVIRON["MARK"]) {
            while ((getline line < ENVIRON["BLOCK"]) > 0) print line
            done = 1
        }
    ' "$file" > "$tmp"
    mv "$tmp" "$file"
    rm -f "$block"
}

# relocate_framework_bootstrap <old_file> <new_file>
# A 1.4.x file keeps the bootstrap inside the framework. Regeneration would
# drop it. Move that text to just after the end marker instead. A bootstrap
# already below the marker is left where it is. The template block is not
# invented when the old file has no bootstrap.
# Arguments:
#   $1 - AGENTS.md before upgrade
#   $2 - upgraded AGENTS.md
# Returns: 0
relocate_framework_bootstrap() {
    local old="$1" new="$2" extracted tmp
    if awk -v mark="$MARKER_END" '
        index($0, mark) { seen = 1; next }
        seen && index($0, "superpowers-augment.js bootstrap") { found = 1 }
        END { exit !found }
    ' "$new"; then
        return 0
    fi
    extracted=$(mktemp)
    MARK_START="$MARKER_START" MARK_END="$MARKER_END" awk '
        index($0, ENVIRON["MARK_START"]) { inside = 1; next }
        index($0, ENVIRON["MARK_END"]) { inside = 0 }
        inside { lines[++n] = $0 }
        END {
            start = 0
            boot = 0
            for (i = 1; i <= n; i++) {
                if (index(lines[i], "superpowers-augment.js bootstrap")) boot = i
            }
            if (boot == 0) exit 0
            start = boot
            for (i = boot; i >= 1; i--) {
                if (lines[i] ~ /^#+ /) { start = i; break }
            }
            if (start == 0) exit 0
            while (start <= n && lines[start] == "") start++
            end = n
            while (end >= start && lines[end] == "") end--
            if (start > end) exit 0
            for (i = start; i <= end; i++) print lines[i]
        }
    ' "$old" > "$extracted"
    if [[ ! -s "$extracted" ]]; then
        rm -f "$extracted"
        return 0
    fi
    tmp=$(mktemp)
    MARK="$MARKER_END" BLOCK="$extracted" awk '
        { print }
        !done && index($0, ENVIRON["MARK"]) {
            print ""
            while ((getline line < ENVIRON["BLOCK"]) > 0) print line
            done = 1
        }
    ' "$new" > "$tmp"
    mv "$tmp" "$new"
    rm -f "$extracted"
}

# relocate_custom_quality_gates <old_file> <new_file>
# Numbered quality gates whose labels are not Lint, Build, Test, or Coverage
# are project rules that happened to sit inside the framework. Regeneration
# would drop them. Move that block to just after the end marker. A second
# upgrade leaves it there.
# Arguments:
#   $1 - AGENTS.md before upgrade
#   $2 - upgraded AGENTS.md
# Returns: 0
relocate_custom_quality_gates() {
    local old="$1" new="$2" extracted tmp signature
    extracted=$(mktemp)
    MARK_START="$MARKER_START" MARK_END="$MARKER_END" awk '
        index($0, ENVIRON["MARK_START"]) { inside = 1; next }
        index($0, ENVIRON["MARK_END"]) { inside = 0 }
        inside { lines[++n] = $0 }
        END {
            qs = 0
            for (i = 1; i <= n; i++) {
                if (lines[i] ~ /^## Quality Gates/) { qs = i; break }
            }
            if (qs == 0) exit 0
            qe = n
            for (i = qs + 1; i <= n; i++) {
                if (lines[i] ~ /^## / || lines[i] ~ /^---$/) { qe = i - 1; break }
            }
            custom = 0
            for (i = qs; i <= qe; i++) {
                if (lines[i] ~ /^[0-9]+\. \*\*/ && lines[i] !~ /^[0-9]+\. \*\*(Lint|Build|Test|Coverage)\*\*/)
                    custom = 1
            }
            if (!custom) exit 0
            start = qs
            end = qe
            while (start <= end && lines[start] == "") start++
            while (end >= start && lines[end] == "") end--
            if (start > end) exit 0
            for (i = start; i <= end; i++) print lines[i]
        }
    ' "$old" > "$extracted"
    if [[ ! -s "$extracted" ]]; then
        rm -f "$extracted"
        return 0
    fi
    signature=$(awk '/^[0-9]+\. \*\*/ && !/^[0-9]+\. \*\*(Lint|Build|Test|Coverage)\*\*/ { print; exit }' "$extracted")
    if [[ -n "$signature" ]] && awk -v mark="$MARKER_END" -v sig="$signature" '
        index($0, mark) { seen = 1; next }
        seen && index($0, sig) { found = 1 }
        END { exit !found }
    ' "$new"; then
        rm -f "$extracted"
        return 0
    fi
    tmp=$(mktemp)
    MARK="$MARKER_END" BLOCK="$extracted" awk '
        { print }
        !done && index($0, ENVIRON["MARK"]) {
            print ""
            while ((getline line < ENVIRON["BLOCK"]) > 0) print line
            done = 1
        }
    ' "$new" > "$tmp"
    mv "$tmp" "$new"
    rm -f "$extracted"
}

# preserve_custom_framework_lines <old_file> <new_file>
# Hand-written project lines that sat inside the old framework markers but do
# not appear in the regenerated file would be deleted without warning. Move those
# lines to just after the end marker, once. Preview and apply both use this
# path so the diff shows the move. Lines already relocated by
# relocate_framework_bootstrap / relocate_custom_quality_gates are skipped
# because they already appear below the end marker in $new.
# Orphan lines that look like stale framework bytes (numbered Lint/Build/Test/
# Coverage gates, filler without prose punctuation, or huge batches from old
# full-mode bloat) are left out so upgrade can shrink the managed block.
# Arguments:
#   $1 - AGENTS.md before upgrade
#   $2 - upgraded AGENTS.md
# Returns: 0
# Side effects: may append lines after MARKER_END in $2; prints a short note
#   on stdout when lines are relocated (visible in preview and apply logs).
preserve_custom_framework_lines() {
    local old="$1" new="$2" extracted tmp count
    local max_preserve=50
    extracted=$(mktemp)
    MARK_START="$MARKER_START" MARK_END="$MARKER_END" awk '
        BEGIN {
            mark_s = ENVIRON["MARK_START"]
            mark_e = ENVIRON["MARK_END"]
        }
        function looks_like_handwritten(line) {
            if (line ~ /^[0-9]+\. \*\*(Lint|Build|Test)\*\*: `/) return 0
            if (line ~ /^[0-9]+\. \*\*Coverage\*\*: `/) return 0
            if (line ~ /[:.]/ ) return 1
            if (line ~ /^#|^>/) return 1
            if (line ~ /^[-*] /) return 1
            if (length(line) >= 60) return 1
            return 0
        }
        FNR == 1 { file++ }
        file == 1 {
            # First file: upgraded AGENTS.md — every line is "already kept"
            kept[$0] = 1
            next
        }
        # Second file: pre-upgrade AGENTS.md — collect interior custom lines
        index($0, mark_s) { inside = 1; next }
        index($0, mark_e) { inside = 0; next }
        !inside { next }
        $0 == "" { next }
        ($0 in kept) { next }
        ($0 in emitted) { next }
        !looks_like_handwritten($0) { next }
        {
            print
            emitted[$0] = 1
        }
    ' "$new" "$old" > "$extracted"
    if [[ ! -s "$extracted" ]]; then
        rm -f "$extracted"
        return 0
    fi
    count=$(wc -l < "$extracted" | tr -d ' ')
    if [[ "$count" -gt "$max_preserve" ]]; then
        rm -f "$extracted"
        return 0
    fi
    echo "  preserving $count hand-written line(s) from inside managed block → after end marker:"
    sed 's/^/    /' "$extracted"
    tmp=$(mktemp)
    MARK="$MARKER_END" BLOCK="$extracted" awk '
        { print }
        !done && index($0, ENVIRON["MARK"]) {
            print ""
            while ((getline line < ENVIRON["BLOCK"]) > 0) print line
            done = 1
        }
    ' "$new" > "$tmp"
    mv "$tmp" "$new"
    rm -f "$extracted"
}

# generate_progressive()
# Generates a progressive-loading AGENTS.md (~60-80 lines).
# Multi-language projects get gates per language unless that pushes the file past
# MAX_PROGRESSIVE_LINES; then only the first language's gates are shown and the
# rest are named.
# Arguments: none (uses globals)
# Returns: Complete AGENTS.md content via stdout
generate_progressive() {
    local tmp_dir lines
    tmp_dir=$(mktemp -d)
    generate_progressive_body "per-language" > "$tmp_dir/agents.md"
    lines=$(wc -l < "$tmp_dir/agents.md" | tr -d ' ')
    if [[ "$lines" -gt "$MAX_PROGRESSIVE_LINES" ]]; then
        generate_progressive_body "first"
    else
        cat "$tmp_dir/agents.md"
    fi
    rm -rf "$tmp_dir"
}

# generate_progressive_body <gate_style>
# Uses on-demand module loading from .golden-agents/modules/ in the consumer repo.
# Reads from global: LANGUAGES, PROJECT_TYPE, PROJECT_NAME, FRAMEWORK_VERSION
# Arguments:
#   $1 - "per-language" or "first" (multi-language gate layout)
# Returns: Complete AGENTS.md content via stdout
generate_progressive_body() {
    local gate_style="$1"
    local today modules_line
    [[ -n "${GATE_NOTE_FILE:-}" ]] && : > "$GATE_NOTE_FILE"
    today=$(date +%Y-%m-%d)
    modules_line=$(modules_record)

    IFS=',' read -ra lang_array <<< "$LANGUAGES"

    cat << HEADER
# AI Agent Guidelines - $PROJECT_NAME

> **Generated by**: [golden-agents](https://github.com/bordenet/golden-agents) v${FRAMEWORK_VERSION} (progressive)
<!-- golden-agents:stamp version=${FRAMEWORK_VERSION} updated=${today} -->
${modules_line}
> **Languages**: $LANGUAGES
> **Type**: ${PROJECT_TYPE:-general}

Minimal core with on-demand module loading. Modules: \`.golden-agents/modules/\`

HEADER

    # Output self-manage bootstrap block
    generate_self_manage_block

    cat << FRAMEWORK_START

$MARKER_START

---

## Quality Gates

FRAMEWORK_START

    if [[ ${#lang_array[@]} -eq 1 ]]; then
        echo "Before a commit:"
        emit_lang_gates "${lang_array[0]}" || note_unset_gate "${lang_array[0]}"
    elif [[ "$gate_style" == "first" ]]; then
        local others="${LANGUAGES#*,}"
        echo "Before a commit (gates shown for ${lang_array[0]}; add equivalents for ${others//,/, }):"
        emit_lang_gates "${lang_array[0]}" || note_unset_gate "${lang_array[0]}"
    else
        echo "Before a commit, run the gates for each language you changed:"
        for lang in "${lang_array[@]}"; do
            local block
            block=$(emit_lang_gates "$lang" "  " || true)
            if [[ -n "$block" ]]; then
                echo "- **$lang**"
                printf '%s\n' "$block"
            else
                note_unset_gate "$lang"
            fi
        done
    fi

    cat << FRAMEWORK_REST

Lint, then build, then test. Run the same commands in CI or a hook.

---

## Communication Rules

- **No flattery** - Skip "Great question!" or "Excellent point!"
- **No hype** - Avoid "revolutionary", "game-changing", "seamless"
- **Evidence-based** - Cite sources or qualify as opinion
- **Direct** - State facts without embellishment

**Banned phrases**: production-grade, world-class, leverage, utilize, incredibly, extremely, Happy to help!

---

## 🚨 Progressive Module Loading

**STOP and load the relevant module BEFORE these actions:**

### Language Modules (🔴 Required)
FRAMEWORK_REST

    # Generate language loading instructions with specific triggers
    for lang in "${lang_array[@]}"; do
        case "$lang" in
            go) echo "- 🔴 **BEFORE writing ANY \`.go\` file**: Read \`.golden-agents/modules/go.md\`" ;;
            python) echo "- 🔴 **BEFORE writing ANY \`.py\` file**: Read \`.golden-agents/modules/python.md\`" ;;
            javascript) echo "- 🔴 **BEFORE writing ANY \`.js\`, \`.ts\`, \`.jsx\`, \`.tsx\` file**: Read \`.golden-agents/modules/javascript.md\`" ;;
            shell) echo "- 🔴 **BEFORE writing ANY \`.sh\` file or bash code block**: Read \`.golden-agents/modules/shell.md\`" ;;
            dart-flutter) echo "- 🔴 **BEFORE writing ANY \`.dart\` file**: Read \`.golden-agents/modules/dart-flutter.md\`" ;;
            *) echo "- 🔴 **BEFORE writing $lang code**: Read \`.golden-agents/modules/${lang}.md\`" ;;
        esac
    done

    cat << MIDDLE

### Workflow Modules (🔴 Required)
- 🔴 **BEFORE any commit, PR, push, or merge**: Read \`.golden-agents/modules/security.md\`
- 🔴 **WHEN tests fail OR after 2+ failed fix attempts**: Read \`.golden-agents/modules/testing.md\`
- 🔴 **WHEN build fails OR lint errors appear**: Read \`.golden-agents/modules/build-hygiene.md\`
- 🟡 **BEFORE deploying to any environment**: Read \`.golden-agents/modules/deployment.md\`

MIDDLE

    if [[ -n "$PROJECT_TYPE" ]]; then
        echo "### Project type guidance:"
        echo "- Read \`.golden-agents/modules/${PROJECT_TYPE}.md\`"
        echo ""
    fi

    cat << FOOTER
$MARKER_END
FOOTER
    if [[ "$SUPERPOWERS" == "true" ]]; then
        superpowers_block
    fi
    cat << 'PROJECT'

---

## Project-Specific Rules

<!-- Add project-specific guidance below this line -->

PROJECT
}

# generate_full()
# Generates a full self-contained AGENTS.md (~800 lines).
# DEPRECATED: This mode generates files too large for AI assistants to follow.
# Includes all templates inline rather than using on-demand loading.
# Reads from global: LANGUAGES, PROJECT_TYPE, PROJECT_NAME, FRAMEWORK_VERSION
# Arguments: none (uses globals)
# Returns: Complete AGENTS.md content via stdout
generate_full() {
    local today
    today=$(date +%Y-%m-%d)

    cat << HEADER
# AI Agent Guidelines - $PROJECT_NAME

> **Generated by**: [golden-agents](https://github.com/bordenet/golden-agents) v${FRAMEWORK_VERSION}
<!-- golden-agents:stamp version=${FRAMEWORK_VERSION} updated=${today} -->
> **Languages**: $LANGUAGES
> **Type**: ${PROJECT_TYPE:-general}

This file is self-contained and portable. No external references required.

$MARKER_START

---

HEADER

    # Core guidance
    echo "## Core Guidelines"
    echo ""
    cat "$TEMPLATES_DIR/core/superpowers.md"
    echo ""
    echo "---"
    echo ""
    cat "$TEMPLATES_DIR/core/communication.md"
    echo ""
    echo "---"
    echo ""
    cat "$TEMPLATES_DIR/core/anti-slop.md"
    echo ""
    echo "---"
    echo ""

    # Workflows
    echo "## Workflows"
    echo ""
    cat "$TEMPLATES_DIR/workflows/deployment.md"
    echo ""
    echo "---"
    echo ""
    cat "$TEMPLATES_DIR/workflows/testing.md"
    echo ""
    echo "---"
    echo ""
    cat "$TEMPLATES_DIR/workflows/security.md"
    echo ""
    echo "---"
    echo ""
    cat "$TEMPLATES_DIR/workflows/build-hygiene.md"
    echo ""
    echo "---"
    echo ""
    cat "$TEMPLATES_DIR/workflows/context-management.md"
    echo ""

    # Language-specific
    echo "---"
    echo ""
    echo "## Language-Specific Guidelines"
    echo ""

    IFS=',' read -ra lang_array <<< "$LANGUAGES"
    for lang in "${lang_array[@]}"; do
        lang_file="$TEMPLATES_DIR/languages/${lang}.md"
        if [[ -f "$lang_file" ]]; then
            cat "$lang_file"
            echo ""
            echo "---"
            echo ""
        else
            echo "Warning: No template for language: $lang" >&2
        fi
    done

    # Project type
    if [[ -n "$PROJECT_TYPE" ]]; then
        type_file="$TEMPLATES_DIR/project-types/${PROJECT_TYPE}.md"
        if [[ -f "$type_file" ]]; then
            echo "## Project Type Guidelines"
            echo ""
            cat "$type_file"
            echo ""
        else
            echo "Warning: No template for project type: $PROJECT_TYPE" >&2
        fi
    fi

    cat << FOOTER

$MARKER_END

---

## Project-Specific Rules

<!-- Add project-specific guidance below this line -->

FOOTER
}

# estimate_tokens <file>
# Prints a token estimate: file bytes divided by 4, rounded up.
# This is not a model tokenizer. The line count is the reproducible check.
# Arguments:
#   $1 - File path
# Returns: The estimate on stdout
estimate_tokens() {
    local bytes
    bytes=$(wc -c < "$1" | tr -d ' ')
    echo $(( (bytes + 3) / 4 ))
}

# report_size <file> [indent]
# Prints the line count and the token estimate.
# Arguments:
#   $1 - File path
#   $2 - Optional prefix for each line
# Returns: 0
report_size() {
    local file="$1"
    local indent="${2:-}"
    local lines tokens
    lines=$(wc -l < "$file" | tr -d ' ')
    tokens=$(estimate_tokens "$file")
    echo "${indent}Lines: $lines"
    echo "${indent}Tokens (estimate): $tokens"
}

# generate_self_manage_block()
# Generates the self-management bootstrap block.
# This block is injected BEFORE the framework start marker.
# Arguments: none
# Returns: Bootstrap block content via stdout
generate_self_manage_block() {
    cat << 'SELF_MANAGE'
<!-- GOLDEN:self-manage:start -->
## ⚠️ Before ANY Task
1. Load `.ai-guidance/invariants.md` — contains critical rules
2. After editing ANY guidance file, check: `wc -l AGENTS.md .ai-guidance/*.md 2>/dev/null`
SELF_MANAGE
    printf "   - \`AGENTS.md\` >%s lines → refactor into \`.ai-guidance/\`\n" "$MAX_GUIDANCE_LINES"
    printf "   - Any \`.ai-guidance/*.md\` >%s lines → split into sub-directory\n" "$MAX_GUIDANCE_LINES"
    cat << 'SELF_MANAGE'
3. Over the limit, draft a diff. Do not apply it. A human merges it.
<!-- GOLDEN:self-manage:end -->

SELF_MANAGE
}

# sed_regex_escape <string>
# Escapes BRE metacharacters and "/" so the string matches literally in a sed address.
# Arguments:
#   $1 - Literal string
# Returns: Escaped string via stdout
sed_regex_escape() {
    printf '%s' "$1" | sed 's/[][\\/.^$*]/\\&/g'
}

# upgrade_agents_md()
# Safely upgrades an existing AGENTS.md file with framework markers.
# Preserves all content outside the framework markers (project-specific sections).
# Creates a backup before applying changes when --apply is used.
# Reads from global: OUTPUT_PATH, LANGUAGES, PROJECT_TYPE, FULL, APPLY
# Arguments: none (uses globals)
# Returns: 0 on success, 1 on error
# Side effects: May modify AGENTS.md and create .backup file
