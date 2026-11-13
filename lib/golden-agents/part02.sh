get_lang_commands() {
    local lang="$1"
    case "$lang" in
        go) echo "LINT:golangci-lint run ./..."; echo "BUILD:go build ./..."; echo "TEST:go test -race -coverprofile=coverage.out ./..."; echo "COV:80" ;;
        python) echo "LINT:pylint --fail-under=9.5 ."; echo "BUILD:mypy ."; echo "TEST:pytest --cov=. --cov-report=term-missing"; echo "COV:80" ;;
        javascript) echo "LINT:npm run lint"; echo "BUILD:npm run build"; echo "TEST:npm test"; echo "COV:70" ;;
        dart-flutter) echo "LINT:flutter analyze"; echo "BUILD:flutter build"; echo "TEST:flutter test --coverage"; echo "COV:70" ;;
        shell) echo "LINT:shellcheck *.sh"; echo "BUILD:bash -n *.sh"; echo "TEST:bats test/"; echo "COV:N/A" ;;
        *) echo "LINT:# lint"; echo "BUILD:# build"; echo "TEST:# test"; echo "COV:70" ;;
    esac
}

# ensure_detected_gates
# Reads the project once for exact lint, test, build, and coverage commands.
# Order: package.json scripts, Makefile, justfile, pyproject.toml
# [project.scripts], then GitHub Actions step names. The first match wins.
# A missing Python leaves every gate on the template fallback.
# Prefer python3, then python, then Windows `py -3`.
# Reads from global: OUTPUT_PATH
# Arguments: none
# Returns: 0. Sets DET_LINT, DET_BUILD, DET_TEST, DET_COV and *_SRC.
ensure_detected_gates() {
    if [[ "${GATES_DETECTED:-}" == "1" ]]; then
        return 0
    fi
    GATES_DETECTED=1
    DET_LINT="" DET_BUILD="" DET_TEST="" DET_COV=""
    DET_LINT_SRC="" DET_BUILD_SRC="" DET_TEST_SRC="" DET_COV_SRC=""
    DET_MANIFEST=""
    local py=()
    if command -v python3 >/dev/null 2>&1; then
        py=(python3)
    elif command -v python >/dev/null 2>&1; then
        py=(python)
    elif command -v py >/dev/null 2>&1; then
        py=(py -3)
    else
        return 0
    fi
    local line name cmd src
    while IFS=$'\t' read -r name cmd src; do
        [[ -n "$name" && -n "$cmd" && -n "$src" ]] || continue
        case "$name" in
            lint) [[ -z "$DET_LINT" ]] && { DET_LINT="$cmd"; DET_LINT_SRC="$src"; } ;;
            build) [[ -z "$DET_BUILD" ]] && { DET_BUILD="$cmd"; DET_BUILD_SRC="$src"; } ;;
            test) [[ -z "$DET_TEST" ]] && { DET_TEST="$cmd"; DET_TEST_SRC="$src"; } ;;
            coverage) [[ -z "$DET_COV" ]] && { DET_COV="$cmd"; DET_COV_SRC="$src"; } ;;
            manifest) DET_MANIFEST=1 ;;
        esac
    done < <(ROOT="$OUTPUT_PATH" "${py[@]}" - << 'PY'
import json, os, pathlib, re, sys
root = pathlib.Path(os.environ.get("ROOT", "."))
names = ("lint", "test", "build", "coverage")
found = {}

def add(name, cmd, src):
    if name in names and name not in found and cmd.strip():
        found[name] = (cmd.strip(), src)

saw = False
pkg = root / "package.json"
if pkg.is_file():
    saw = True
    try:
        data = json.loads(pkg.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        data = {}
    scripts = data.get("scripts") if isinstance(data, dict) else None
    if isinstance(scripts, dict):
        for name in names:
            if isinstance(scripts.get(name), str) and scripts[name].strip():
                add(name, "npm run " + name, "package.json")

def make_targets(path, runner):
    global saw
    if not path.is_file():
        return
    saw = True
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = re.match(r"^(lint|test|build|coverage):([^:]|$)", raw)
        if match:
            add(match.group(1), runner + " " + match.group(1), 