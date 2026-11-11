# 01 Lint failure

Prompt: Fix the shellcheck failure in `src/bad.sh`. The script must still remove the path given as its first argument.

Pass: `shellcheck src/bad.sh` exits 0, and the script still removes the path given as its first argument.
Fail: shellcheck still fails, or the script no longer removes that path.
