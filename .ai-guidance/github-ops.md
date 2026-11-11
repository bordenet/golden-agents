# GitHub operations from a cloud agent

Load this before changing this repo on GitHub. Written after a session burned hours deleting six stale branches from a container.

## The container is not the user's machine

A cloud agent runs in a container.

- `gh` is not logged in. `gh auth status` fails until a token is present in that container.
- `git push` to `github.com` has no credentials. The Origin remote on the agent workspace is a different host and does not authenticate GitHub.
- The container browser is a separate Chrome profile. The user's Safari, and Chrome on their Mac, are not that session. A "Sign in" button there means GitHub operations through that window will fail. Do not ask the user to sign in there for repo administration.
- Do not drive a browser to delete branches, edit files, merge pull requests, or "click around" GitHub.

## What the GitHub connection in the container can and cannot do

The GitHub MCP connection authenticates as the repo owner and can commit file contents. Use it for that. It cannot replace `gh` for everything else.

- Updating an existing executable keeps mode `100755`. Creating a new file, or updating a `100644` file, stores `100644`.
- Compare blobs with `git hash-object --no-filters`. A filtered `git hash-object` disagrees with the GitHub blob for CRLF files.
- Writes under `.github/workflows/` return 403 when the token lacks the workflow scope. Do not hand the user a line-by-line paste. If a workflow file must change, give them the full file once, or a pull request they can merge.
- There is no delete-ref tool. Branch deletion is not a file edit.
- `create_pull_request`, `update_pull_request`, and `issue_write` can open a Cursor form instead of calling the API. Do not use them to sneak past a missing API.

## Deleting branches

Do this on a machine where `gh` is already logged in. Never delete `main`.

`gh api` opens `$EDITOR` for a request body when the method is `DELETE`, the command runs in a terminal, and `--input` is omitted. Pass an empty body:

```bash
gh api --method DELETE --input /dev/null \
  "repos/bordenet/golden-agents/git/refs/heads/<branch>"
```

For a branch name that contains `/`, GitHub wants the slash escaped once (`%2F`). `gh api` decodes `%2F` before the request, so a single encoding looks up the wrong ref. Send `%252F` (for example `heads/cursor%252Fsome-branch`) or delete with a client that does not decode the path.

HTTP 422 `Reference does not exist` means that ref is already gone. List branches and stop. Do not retry a missing ref, and do not treat 422 as a reason to switch to the browser.

```bash
gh api repos/bordenet/golden-agents/branches --jq '.[].name'
```

## Shipping a change

1. Edit the tree. Run `bats test/*.bats` on that tree. This repo tests itself.
2. Land with the GitHub API from whatever client is actually authenticated.
3. After a push to `main`, read the Actions run for that commit. A green run on an intermediate commit does not count. The tip does.
4. Confirm the branch list before claiming a cleanup is finished.
