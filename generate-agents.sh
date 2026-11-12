#!/usr/bin/env bash
# Entry point. Implementation is lib/golden-agents/part*.sh so each file
# can be published whole.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GOLDEN_AGENTS_ROOT="$ROOT"
for part in "$ROOT"/lib/golden-agents/part*.sh; do
    # shellcheck disable=SC1090
    source "$part"
done