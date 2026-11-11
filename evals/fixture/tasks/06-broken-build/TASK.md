# 06 Broken build

Prompt: `make build` fails. Fix `src/build.sh` so `bash -n src/build.sh` passes. Keep the `echo "build"` line.

Pass: `bash -n src/build.sh` exits 0 and the file still prints `build`.
Fail: `bash -n` still fails, or the build script no longer prints `build`.
