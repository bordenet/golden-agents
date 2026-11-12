check_existing_guidance() {
    local path="$1"
    local found_files=""

    if [[ -f "$path/CLAUDE.md" ]] && ! is_generated_redirect "$path/CLAUDE.md" "CLAUDE.md"; then
        local size
        size=$(wc -c < "$path/CLAUDE.md" | tr -d ' ')
        found_files="CLAUDE.md ($size bytes)"
    fi

    # Check Agents.md without markers (skip when it is the same file as AGENTS.md,
    # as on case-insensitive filesystems)
    if [[ -f "$path/Agents.md" ]] && ! [[ "$path/Agents.md" -ef "$path/AGENTS.md" ]]; then
        if ! grep -q "$MARKER_START" "$path/Agents.md"; then
            local size
            size=$(wc -c < "$path/Agents.md" | tr -d ' ')
            found_files="${found_files:+$found_files, }Agents.md ($size bytes, no markers)"
        fi
    fi

    # Check AGENTS.md (case variation)
    if [[ -f "$path/AGENTS.md" ]]; then
        if ! grep -q "$MARKER_START" "$path/AGENTS.md"; then
            local size
            size=$(wc -c < "$path/AGENTS.md" | tr -d ' ')
            found_files="${found_files:+$found_files, }AGENTS.md ($size bytes, no markers)"
        fi
    fi

    echo "$found_files"
}

# generate_migration_prompt <path>
# Generates a markdown prompt file for LLM-assisted migration.
# Collects content from existing CLAUDE.md, Agents.md, and AGENTS.md files.
# Outputs a structured prompt with instructions for deduplication.
# Arguments:
#   $1 - Directory path containing existing guidance files
# Returns: Migration prompt markdown via stdout
generate_migration_prompt() {
    local path="$1"
    local existing_content=""
    local source_file=""

    # Collect existing content from CLAUDE.md
    if [[ -f "$path/CLAUDE.md" ]] && ! is_generated_redirect "$path/CLAUDE.md" "CLAUDE.md"; then
        source_file="CLAUDE.md"
        existing_content=$(cat "$path/CLAUDE.md")
    fi

    # Collect from Agents.md without markers (once, if it is the same file as AGENTS.md)
    if [[ -f "$path/Agents.md" ]] && ! [[ "$path/Agents.md" -ef "$path/AGENTS.md" ]] \
        && ! grep -q "$MARKER_START" "$path/Agents.md"; then
        local size
        size=$(wc -c < "$path/Agents.md" | tr -d ' ')
        source_file="${source_file:+$source_file + }Agents.md"
        if [[ -n "$existing_content" ]]; then
            existing_content="$existing_content

---

$(cat "$path/Agents.md")"
        else
            existing_content=$(cat "$path/Agents.md")
        fi
    fi

    # Collect from AGENTS.md without markers
    if [[ -f "$path/AGENTS.md" ]] && ! grep -q "$MARKER_START" "$path/AGENTS.md"; then
        local size
        size=$(wc -c < "$path/AGENTS.md" | tr -d ' ')
        source_file="${source_file:+$source_file + }AGENTS.md"
        if [[ -n "$existing_content" ]]; then
            existing_content="$existing_content

---

$(cat "$path/AGENTS.md")"
        else
            existing_content=$(cat "$path/AGENTS.md")
        fi
    fi

    cat << 'PROMPT_EOF'
# Golden Agents Migration Prompt

> **DELETE THIS FILE** after completing the migration.

You are helping migrate project-specific AI guidance into the golden-agents framework.

## Instructions

1. Read the **Existing Content** below (from the old guidance files)
2. Read the **New Framework** in `AGENTS.md` (already generated)
3. Apply the **10-word test** to each piece of content:
   - Can you express this in under 10 words with specific names/paths/commands?
   - YES → Keep it (project-specific)
   - NO → Skip it (framework already covers it)
4. Add ONLY project-specific content to `AGENTS.md` after `<!-- GOLDEN:framework:end -->`
5. **DO NOT** duplicate content already in the framework (quality gates, anti-slop, etc.)
6. **DO NOT** lose any genuinely project-specific information

## Target Sizes

| Project Complexity | Target Size |
|-------------------|-------------|
| Simple (single language, standard tooling) | **0-20 lines** |
| Moderate (multi-language, some custom workflows) | **20-50 lines** |
| Complex (many integrations, strict domain rules) | **50-100 lines** |

**If your project exceeds 100 lines** of genuinely project-specific content:
1. Create a `.ai-guidance/` directory in your repo
2. Split content into topic-specific modules (e.g., `mobile-builds.md`, `security.md`)
3. Add a loading table to AGENTS.md referencing when to load each module
PROMPT_EOF
    echo "4. Keep AGENTS.md under $MAX_GUIDANCE_LINES lines with quick reference + loading instructions"
    echo ""
    echo "## Source Files"
    echo ""
    echo "Migrated from: $source_file"
    local source_lines
    source_lines=$(echo "$existing_content" | wc -l | tr -d ' ')
    echo "Original size: $source_lines lines"
    echo ""
    # The fence must be longer than any backtick run in the content, or an
    # embedded code block closes it early
    local longest_run fence=""
    longest_run=$(printf '%s\n' "$existing_content" | awk '
        { s = $0; while (match(s, /`+/)) { if (RLENGTH > m) m = RLENGTH; s = substr(s, RSTART + RLENGTH) } }
        END { print m + 0 }')
    while [[ ${#fence} -lt 3 || ${#fence} -le $longest_run ]]; do
        fence="${fence}\`"
    done
    echo "## Existing Content"
    echo ""
    echo "${fence}markdown"
    echo "$existing_content"
    echo "$fence"
    echo ""
    echo "## Report Metrics"
    echo ""
    echo "After adding project-specific content to AGENTS.md, report:"
    echo ""
    echo '```'
    echo "MIGRATION SUMMARY"
    echo "━━━━━━━━━━━━━━━━━"
    echo "Original guidance file: $source_lines lines"
    echo "Project-specific content added: ~[Y] lines"
    echo "Reduction: [Z]%"
    echo ""
    echo "Kept [M] project-specific items (paths, commands, policies, domain rules)"
    echo "Skipped [N] generic items (covered by framework)"
    echo '```'
    echo ""
    echo "## Next Steps"
    echo ""
    echo "1. Open \`AGENTS.md\` and find the \`<!-- GOLDEN:framework:end -->\` marker"
    echo "2. Add your project-specific content after that marker"
    echo "3. Report the metrics above"
    echo "4. Delete this \`MIGRATION-PROMPT.md\` file"
    echo "5. Commit the changes"
}

# Parse arguments (value options accept --opt=value and --opt value)
while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        --language|--type|--path|--name)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "Error: $arg requires a value" >&2
                exit 1
            fi
            arg="$arg=$2"
            shift
            ;;
    esac
    case $arg in
        --language=*) LANGUAGES="${arg#*=}" ;;
        --type=*) PROJECT_TYPE="${arg#*=}" ;;
        --path=*) OUTPUT_PATH="${arg#*=}"; PATH_GIVEN=true ;;
        --name=*) PROJECT_NAME="${arg#*=}" ;;
        --progressive) ;; # Already the default, flag accepted for clarity
        --superpowers) SUPERPOWERS=true ;;
        --full)
            FULL=true
            echo "[DEPRECATED] --full mode generates 800+ line files that AI assistants cannot follow." >&2
            echo "[DEPRECATED] Use progressive mode (default) instead." >&2
            ;;
        --sync) SYNC=true ;;
        --dry-run) DRY_RUN=true ;;
        --upgrade) UPGRADE=true ;;
        --apply) APPLY=true ;;
        --migrate) MIGRATE=true ;;
        --adopt) ADOPT=true ;;
        --dedupe) DEDUPE=true ;;
        -h|--help) usage; exit 0 ;;
        -v|--version) version; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; usage; exit 1 ;;
    esac
    shift
done

# Validate --apply requires --upgrade
if [[ "$APPLY" == "true" && "$UPGRADE" != "true" ]]; then
    echo "Error: --apply requires --upgrade" >&2
    exit 1
fi

# Resolve language aliases
if [[ -n "$LANGUAGES" ]]; then
    LANGUAGES=$(resolve_languages "$LANGUAGES")
fi

# Handle sync mode
if [[ "$SYNC" == "true" ]]; then
    sync_templates
    exit 0
fi

# Validate --language and --type against templates/
if [[ -n "$LANGUAGES" ]]; then
    IFS=',' read -ra requested_langs <<< "$LANGUAGES"
    for lang in "${requested_langs[@]}"; do
        if ! is_template languages "$lang"; then
            echo "[ERROR] Unknown language: $lang" >&2
            echo "  Valid languages: $(list_templates languages)" >&2
            echo "  Aliases are listed under LANGUAGE ALIASES in --help." >&2
            exit 1
        fi
    done
fi
if [[ -n "$PROJECT_TYPE" ]] && ! is_template project-types "$PROJECT_TYPE"; then
    echo "[ERROR] Unknown project type: $PROJECT_TYPE" >&2
    echo "  Valid types: $(list_templates project-types)" >&2
    exit 1
fi

# Validate --adopt requires --language
if [[ "$ADOPT" == "true" && -z "$LANGUAGES" ]]; then
    echo "Error: --adopt requires --language" >&2
    exit 1
fi

# Validate --dedupe requires --path
if [[ "$DEDUPE" == "true" && "$PATH_GIVEN" != "true" ]]; then
    echo "Error: --dedupe requires --path" >&2
    exit 1
fi

# Validate (skip language check for upgrade mode and dedupe mode)
if [[ -z "$LANGUAGES" && "$UPGRADE" != "true" && "$DEDUPE" != "true" ]]; then
    echo "[ERROR] --language is required for new file generation" >&2
    echo "" >&2
    echo "Available languages:" >&2
    echo "  go          - Go projects" >&2
    echo "  javascript  - JavaScript/TypeScript/Node.js (aliases: js, node, ts)" >&2
    echo "  python      - Python projects (aliases: py)" >&2
    echo "  shell       - Shell scripts (aliases: bash, sh)" >&2
    echo "  dart-flutter - Dart/Flutter projects (aliases: flutter, dart)" >&2
    echo "" >&2
    echo "Available project types:" >&2
    echo "  cli-tools     - Command-line tools" >&2
    echo "  web-apps      - Web applications" >&2
    echo "  mobile-apps   - Mobile applications" >&2
    echo "  genesis-tools - Genesis framework tools" >&2
    echo "" >&2
    echo "Example: generate-agents.sh --language=go,js --type=web-apps --path=./my-project" >&2
    exit 1
fi

# Redirect files with non-generated content; backed up in --adopt/--migrate, block plain runs
BLOCKING_REDIRECTS=$(find_blocking_redirects "$OUTPUT_PATH")

# Check for existing guidance files (unless --migrate or --upgrade or --adopt or --dedupe or --dry-run is used)
# A blocked plain run writes nothing at all.
if [[ "$MIGRATE" != "true" && "$UPGRADE" != "true" && "$ADOPT" != "true" && "$DEDUPE" != "true" && "$DRY_RUN" != "true" ]]; then
    blocking=""
    for name in AGENTS.md Agents.md; do
        if [[ "$name" == "Agents.md" && "$OUTPUT_PATH/Agents.md" -ef "$OUTPUT_PATH/AGENTS.md" ]]; then
            continue
        fi
        if [[ -f "$OUTPUT_PATH/$name" ]]; then
            if grep -q "$MARKER_START" "$OUTPUT_PATH/$name"; then
                blocking="${blocking}  $name (existing file with markers; use --upgrade)
"
            else
                blocking="${blocking}  $name (existing file without markers; use --adopt or --migrate)
"
            fi
        fi
    done
    for rel in $BLOCKING_REDIRECTS; do
        blocking="${blocking}  $rel (non-generated content)
"
    done
    if [[ -n "$blocking" ]]; then
        echo "[ERROR] Found existing guidance files. No files were written." >&2
        echo "" >&2
        printf '%s' "$blocking" >&2
        echo "" >&2
        echo "  These files contain project-specific content that would be lost." >&2
        echo "  Use --migrate to safely incorporate this content into the new AGENTS.md." >&2
        echo "  Use --adopt to bring an existing AGENTS.md into the framework." >&2
        echo "" >&2
        echo "  Example: generate-agents.sh --migrate --language=go --path=$OUTPUT_PATH" >&2
        echo "  Example: generate-agents.sh --adopt --language=go --path=$OUTPUT_PATH" >&2
        exit 1
    fi
fi

# Handle migrate mode - generate migration prompt if needed
if [[ "$MIGRATE" == "true" ]]; then
    # Check if there's content to migrate
    existing=$(check_existing_guidance "$OUTPUT_PATH")
    if [[ -n "$existing" ]]; then
        # Extract filename and count lines
        source_file=$(echo "$existing" | cut -d' ' -f1)
        source_lines=$(wc -l < "$OUTPUT_PATH/$source_file" | tr -d ' ')

        echo "[INFO] Found existing guidance: $existing"
        echo "[INFO] Source file: $source_file ($source_lines lines)"

        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would generate migration prompt: $OUTPUT_PATH/MIGRATION-PROMPT.md"
            echo "[DRY RUN] Would add MIGRATION-PROMPT.md to $OUTPUT_PATH/.gitignore"
        else
            mkdir -p "$OUTPUT_PATH"
            echo "[INFO] Generating migration prompt..."

            # Generate the migration prompt
            generate_migration_prompt "$OUTPUT_PATH" > "$OUTPUT_PATH/MIGRATION-PROMPT.md"
            echo "[OK] Created: $OUTPUT_PATH/MIGRATION-PROMPT.md"
            echo "[INFO] Target: reduce to 0-100 lines of project-specific content"

            # Add to .gitignore
            gitignore_add "$OUTPUT_PATH" "MIGRATION-PROMPT.md" || true
            echo "[OK] Added MIGRATION-PROMPT.md to .gitignore"
        fi
    else
        echo "[INFO] No existing guidance files found. Running normal generation."
    fi

    # Normal generation below replaces AGENTS.md, so back up any existing one
    # (with or without markers). Both names may be one file on case-insensitive volumes.
    for name in AGENTS.md Agents.md; do
        if [[ ! -f "$OUTPUT_PATH/$name" ]]; then
            continue
        fi
        if [[ "$name" == "Agents.md" && "$OUTPUT_PATH/Agents.md" -ef "$OUTPUT_PATH/AGENTS.md" ]]; then
            continue
        fi
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would back up $name to $name.<timestamp>.bak"
        else
            backup_file "$OUTPUT_PATH/$name"
        fi
    done

    # Continue with normal generation (framework AGENTS.md)
    # Fall through to normal generation below
fi

# Handle adopt mode - bring existing AGENTS.md into framework
if [[ "$ADOPT" == "true" ]]; then
    # Check for existing AGENTS.md (preferred) or Agents.md (legacy) without markers
    existing_agents_file=""
    if [[ -f "$OUTPUT_PATH/AGENTS.md" ]]; then
        existing_agents_file="$OUTPUT_PATH/AGENTS.md"
    elif [[ -f "$OUTPUT_PATH/Agents.md" ]]; then
        existing_agents_file="$OUTPUT_PATH/Agents.md"
    fi

    if [[ -z "$existing_agents_file" ]]; then
        echo "[ERROR] No AGENTS.md found at $OUTPUT_PATH" >&2
        echo "  --adopt requires an existing AGENTS.md file to adopt." >&2
        exit 1
    fi

    if grep -q "$MARKER_START" "$existing_agents_file"; then
        echo "[ERROR] $(basename "$existing_agents_file") already has framework markers" >&2
        echo "  Use --upgrade instead to update framework sections." >&2
        exit 1
    fi

    echo "[INFO] Adopting existing $(basename "$existing_agents_file") into golden-agents framework..."

    # Store original content (read-only; safe to do even in dry-run)
    original_content=$(cat "$existing_agents_file")
    original_lines=$(wc -l < "$existing_agents_file" | tr -d ' ')

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would back up original: $OUTPUT_PATH/AGENTS.md.original"
        if [[ "$existing_agents_file" == "$OUTPUT_PATH/Agents.md" ]]; then
            echo "[DRY RUN] Would remove legacy file: $existing_agents_file"
        fi
        echo "[DRY RUN] Would create: $OUTPUT_PATH/ADOPT-PROMPT.md"
        echo "[DRY RUN] Would add ADOPT-PROMPT.md and AGENTS.md.original to .gitignore"
    else
        mkdir -p "$OUTPUT_PATH"

        # Backup original
        cp "$existing_agents_file" "$OUTPUT_PATH/AGENTS.md.original"
        echo "[OK] Backed up original: $OUTPUT_PATH/AGENTS.md.original"

        # Remove old file if it was lowercase (will be replaced with AGENTS.md)
        if [[ "$existing_agents_file" == "$OUTPUT_PATH/Agents.md" ]]; then
            rm "$existing_agents_file"
        fi

        # Copy ADOPT-PROMPT.md template
        if [[ -f "$TEMPLATES_DIR/adopt-prompt.md" ]]; then
            cp "$TEMPLATES_DIR/adopt-prompt.md" "$OUTPUT_PATH/ADOPT-PROMPT.md"
            echo "[OK] Created: $OUTPUT_PATH/ADOPT-PROMPT.md"
        else
            echo "[WARN] Template not found: $TEMPLATES_DIR/adopt-prompt.md" >&2
        fi

        # Add to .gitignore
        gitignore_add "$OUTPUT_PATH" "ADOPT-PROMPT.md" || true
        gitignore_add "$OUTPUT_PATH" "AGENTS.md.original" || true
        echo "[OK] Added ADOPT-PROMPT.md and AGENTS.md.original to .gitignore"
    fi

    # Generate framework content, then append original
    # We'll set a flag to append after generation
    ADOPT_ORIGINAL_CONTENT="$original_content"
    ADOPT_ORIGINAL_LINES="$original_lines"

    # Fall through to normal generation, which will append the original content
fi

# Handle dedupe mode - generate deduplication prompt for files WITH markers
if [[ "$DEDUPE" == "true" ]]; then
    # Check for existing AGENTS.md (preferred) or Agents.md (legacy) WITH markers
    existing_agents_file=""
    if [[ -f "$OUTPUT_PATH/AGENTS.md" ]]; then
        existing_agents_file="$OUTPUT_PATH/AGENTS.md"
    elif [[ -f "$OUTPUT_PATH/Agents.md" ]]; then
        existing_agents_file="$OUTPUT_PATH/Agents.md"
    fi

    if [[ -z "$existing_agents_file" ]]; then
        echo "[ERROR] No AGENTS.md found at $OUTPUT_PATH" >&2
        echo "  --dedupe requires an existing AGENTS.md file with framework markers." >&2
        exit 1
    fi

    if ! grep -q "$MARKER_START" "$existing_agents_file"; then
        echo "[ERROR] $(basename "$existing_agents_file") does not have framework markers" >&2
        echo "  Use --adopt instead for files created without golden-agents." >&2
        exit 1
    fi

    if ! grep -qF "$MARKER_END" "$existing_agents_file"; then
        echo "[ERROR] $(basename "$existing_agents_file") has $MARKER_START but no $MARKER_END" >&2
        echo "  Restore the end marker after the framework section, then rerun --dedupe." >&2
        echo "  No files were changed." >&2
        exit 1
    fi

    # Count lines in project-specific section (after MARKER_END)
    marker_end_line=$(grep -n "$MARKER_END" "$existing_agents_file" | head -1 | cut -d: -f1)
    total_lines=$(wc -l < "$existing_agents_file" | tr -d ' ')
    project_lines=$((total_lines - marker_end_line))

    echo "[INFO] Analyzing $(basename "$existing_agents_file") for deduplication..."
    echo "  Total lines: $total_lines"
    echo "  Framework section ends at line: $marker_end_line"
    echo "  Project-specific section: $project_lines lines"
    echo ""

    if [[ $project_lines -le 100 ]]; then
        echo "[OK] Project-specific section is already within target (<100 lines)"
        echo "  No deduplication needed."
        exit 0
    fi

    echo "[WARN] Project-specific section exceeds target (>100 lines)"
    echo "  Target for complex projects: 50-100 lines"
    echo "  Current: $project_lines lines"
    echo ""

    # ADOPT-PROMPT.md template is required regardless of dry-run (read-only check)
    if [[ ! -f "$TEMPLATES_DIR/adopt-prompt.md" ]]; then
        echo "[ERROR] Template not found: $TEMPLATES_DIR/adopt-prompt.md" >&2
        exit 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would create: $OUTPUT_PATH/ADOPT-PROMPT.md"
        echo "[DRY RUN] Would add ADOPT-PROMPT.md to .gitignore"
    else
        # Copy ADOPT-PROMPT.md template (same prompt works for dedupe)
        cp "$TEMPLATES_DIR/adopt-prompt.md" "$OUTPUT_PATH/ADOPT-PROMPT.md"
        echo "[OK] Created: $OUTPUT_PATH/ADOPT-PROMPT.md"

        # Add to .gitignore if not already there
        if [[ -f "$OUTPUT_PATH/.gitignore" ]]; then
            if gitignore_add "$OUTPUT_PATH" "ADOPT-PROMPT.md"; then
                echo "[OK] Added ADOPT-PROMPT.md to .gitignore"
            fi
        else
            gitignore_add "$OUTPUT_PATH" "ADOPT-PROMPT.md"
            echo "[OK] Created .gitignore with ADOPT-PROMPT.md"
        fi
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    NEXT STEPS"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "  1. Open ADOPT-PROMPT.md in your AI assistant"
    echo "  2. Paste the contents of AGENTS.md after the prompt"
    echo "  3. The AI will propose aggressive deduplication"
    echo "  4. Review and approve the proposed changes"
    echo "  5. Apply the minimal result to AGENTS.md"
    echo "  6. Delete ADOPT-PROMPT.md and commit"
    echo ""
    echo "  Target: Reduce project-specific section from $project_lines to <100 lines"
    echo ""
    echo "═══════════════════════════════════════════════════════════════"

    exit 0
fi

# Set project name from directory if not specified
if [[ -z "$PROJECT_NAME" ]]; then
    PROJECT_NAME=$(basename "$(cd "$OUTPUT_PATH" 2>/dev/null && pwd)" 2>/dev/null || echo "Project")
fi

# get_lang_commands <language>
# Returns language-specific lint, build, test commands and coverage target.
# Output format: newline-separated KEY:VALUE pairs
#   LINT:<command>   - Linting command
#   BUILD:<command>  - Build/compile command
#   TEST:<command>   - Test command
#   COV:<percent>    - Coverage target percentage (or "N/A")
# Arguments:
#   $1 - Canonical language name (go, python, javascript, dart-flutter, shell)
# Returns: Key:value pairs via stdout, one per line
