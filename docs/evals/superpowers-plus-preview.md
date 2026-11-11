# superpowers-plus upgrade preview

Date: 2026-11-11. Command: `generate-agents.sh --upgrade --path=<superpowers-plus checkout>`.
Neither preview wrote a file. The consumer repo was not modified.

## What the repo actually runs

`AGENTS.md` is golden-agents 1.4.0, languages `shell,javascript`, type `cli-tools`.
Its gates are `shellcheck *.sh`, `bash -n *.sh`, and `bats test/`.
There is no root `package.json`, `Makefile`, `justfile`, or `pyproject.toml`.
`mcp/package.json` has `test`: `node smoke-test.js`. It has no `lint` or `build` script.
`.github/workflows/test.yml` runs `bash tools/test-all.sh` and provisions shellcheck.
Its step names are phrases such as `All bats suites (auto-discovered)`.
None of them is exactly `lint`, `test`, `build`, or `coverage`.
The superpowers bootstrap sits inside the framework markers.

## Round 1

The preview prefixed the three shell commands with `UNVERIFIED: confirm` and
added `UNVERIFIED: confirm` in front of `npm run lint`, `npm run build`, and
`npm test`. Those npm scripts are not this repo's commands. That preview was
rejected.

## Round 2

Upgrade now keeps a command already in the quality-gate block when detection
finds nothing and the command is that language's template, or when it matches
no selected template. A language with no command is omitted.

The second preview keeps `shellcheck *.sh`, `bash -n *.sh`, and `bats test/`.
It does not mention `npm` or `UNVERIFIED`. It names `javascript` under
`Gates left unset`. It still moves the cap from 150 lines to 250, copies
modules into the repo, points module reads at `.golden-agents/modules/`, and
removes the superpowers bootstrap from the framework region.

## Decision

Do not apply from this session. The gate rewrite that made the first preview
unsafe is gone. Applying would still delete the bootstrap that this repo
keeps inside the framework, and it would write the module and rule files.
Use `--superpowers` on a later apply if that bootstrap should be placed
after `<!-- GOLDEN:framework:end -->`.
