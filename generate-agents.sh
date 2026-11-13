#!/usr/bin/env bash
# Entry point. Implementation is lib/golden-agents/part*.sh so each file
# can be published whole.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GOLDEN_AGENTS_ROOT="$ROOT"

# Load part00 first (defaults + run_self_test). Validate before sourcing
# other parts so a truncated path stub never becomes `source` → exit 127.
# shellcheck disable=SC1090
source "$ROOT/lib/golden-agents/part00.sh"

want_self_test=false
want_upgrade=false
for arg in "$@"; do
    case "$arg" in
        --self-test) want_self_test=true ;;
        --upgrade) want_upgrade=true ;;
    esac
done

if [[ "$want_self_test" == "true" || "$want_upgrade" == "true" ]]; then
    run_self_test
fi
if [[ "$want_self_test" == "true" ]]; then
    exit 0
fi

for part in "$ROOT"/lib/golden-agents/part01.sh \
            "$ROOT"/lib/golden-agents/part02.sh \
            "$ROOT"/lib/golden-agents/part03.sh \
            "$ROOT"/lib/golden-agents/part04.sh; do
    # shellcheck disable=SC1090
    source "$part"
done
