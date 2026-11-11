# Fix stack

`generate-agents.ps1` is a wrapper. It has no separate defect. It delegates
to `generate-agents.sh`. Item 16: the wrapper converts WSL paths only for
`--path=X`, not for the space form `--path X`. That is a note, not a code change.

The stack is on `main`. The Branch column names the fix branch for each item.

| Item | Status | Test | Branch | ps1 |
|------|--------|------|--------|-----|
| 1 | fixed | SAFE WRITE: plain run refuses real GEMINI.md, CODEX.md, copilot-instructions.md and writes nothing | fix/01-safe-write-redirects | no |
| 2 | fixed | DATA LOSS: --migrate backs up AGENTS.md without markers to timestamped .bak | fix/02-migrate-backup-agents | no |
| 3 | fixed | upgrade keeps a customized .ai-guidance/invariants.md byte-for-byte | fix/03-ai-guidance-no-overwrite | no |
| 4 | fixed | migrate collects a single Agents.md once | fix/04-case-insensitive-dedupe | no |
| 5 | fixed | GITIGNORE: --migrate appends on its own line when file lacks trailing newline | fix/05-gitignore-newline | no |
| 6 | fixed | migration prompt fence is longer than any backtick run in content | fix/06-migration-prompt-fence | no |
| 7 | fixed | fresh generation creates .ai-guidance/invariants.md from the template | fix/07-create-invariants | no |
| 8 | fixed | THRESHOLD: script defines MAX_GUIDANCE_LINES=250 | fix/08-size-threshold-250 | no |
| 9 | fixed | upgrade reads Languages and Type from the generated header lines only | fix/09-upgrade-header-parse | no |
| 10 | fixed | DATA LOSS: upgrade preserves user blank lines byte-for-byte | fix/10-upgrade-blank-lines | no |
| 11 | fixed | dedupe with start marker but no end marker explains the problem | fix/11-dedupe-missing-end-marker | no |
| 12 | fixed | dedupe accepts --path=. for the current directory | fix/12-dedupe-path-dot | no |
| 13 | fixed | multi-language generation emits labeled gates for each language | fix/13-multi-language-gates | no |
| 14 | fixed | shell generation omits the coverage gate instead of printing N/A% | fix/14-coverage-na | no |
| 15 | fixed | unknown --language fails and lists valid languages | fix/15-validate-language-type | no |
| 16 | fixed | space form works for --language, --type, --path and --name | fix/16-space-form-args | no (see note) |
| 17 | fixed | sync refuses to rewrite a clone with local commits | fix/17-sync-ff-only | no |
| 18 | fixed | fresh generation writes a stamp and no Last Updated line | fix/18-stamp-comment | no |
| 19 | fixed | guidance docs do not hardcode a BATS or suite total | fix/19-doc-accuracy | no |
| 20 | design only | docs/DESIGN-v2.md, no behavior change | fix/20-design-v2 | no |
| 21 | docs | docs/UPGRADE-GUIDE.md and this table | fix/21-upgrade-guide | no |
