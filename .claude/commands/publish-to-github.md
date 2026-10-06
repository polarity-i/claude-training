---
description: Security-scan, then publish this project to GitHub (push, README, Pages, CI/CD workflow, About section)
argument-hint: <github-repo-url>
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, WebFetch
---

Publish this project to the GitHub repository given in `$ARGUMENTS`.

## Step 0: Inputs and prerequisites

- `$ARGUMENTS` must be a GitHub repo URL (`https://github.com/<owner>/<repo>` or `git@github.com:<owner>/<repo>.git`). If it is empty or not a GitHub URL, ask the user for it and stop.
- Parse `<owner>` and `<repo>` (strip `.git` and any trailing slash). The Pages URL will be `https://<owner>.github.io/<repo>/`.
- Run `gh auth status`. If `gh` is missing or not logged in, tell the user to run `gh auth login` themselves and stop. Never ask for or handle tokens or passwords.
- Run `git status` and `git remote -v` to see the current state. Read `CLAUDE.md` so the README and checks match the project's constraints.

## Step 1: Security scan (gate — runs BEFORE anything is pushed)

Nothing leaves the machine until this passes. Scan the working tree **and** git history (`git log --all`), since a secret committed earlier is still exposed once pushed.

1. **Tracked and untracked files.** List what would be published: `git ls-files` plus `git ls-files --others --exclude-standard`. Flag files that should never be published: `.env*`, `*.pem`, `*.key`, `id_rsa*`, `*.p12`, `*.pfx`, `*.keystore`, `credentials*`, `secrets*`, `*.sqlite`, `*.db`, `.DS_Store`, `node_modules/`, `.claude/settings.local.json`, and anything else personal.
2. **Content patterns** (use Grep across the tree, then `git log -p --all` / `git grep` over history for the same patterns):
   - API keys/tokens: `AKIA[0-9A-Z]{16}`, `ghp_`, `gho_`, `github_pat_`, `xox[baprs]-`, `sk-[A-Za-z0-9]{20,}`, `AIza[0-9A-Za-z_-]{35}`, `-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----`
   - Assignments: `(password|passwd|secret|token|api[_-]?key|private[_-]?key)\s*[:=]\s*['"][^'"]{6,}`
   - Email addresses, phone numbers, internal hostnames/IPs, real bank/account/card numbers.
   - Absolute local paths such as `/Users/<name>/` in committed files.
3. **Project-specific rules** (from `CLAUDE.md`):
   - The notification email address must appear **only** inside `FORMSUBMIT_ENDPOINT`. Any other occurrence is a failure. Note that the endpoint itself is public once pushed: FormSubmit endpoints are visible in page source by design, so tell the user plainly that the address will be public and let them decide (consider FormSubmit's random-token alias URL as an alternative).
   - No `localStorage`, `sessionStorage`, `IndexedDB`, `document.cookie`, `alert(`, `confirm(`, `!important`, and no external `http(s)://` resources (CDN, fonts, images) other than the FormSubmit endpoint.
4. **Fix before continuing.** Add a `.gitignore` (at minimum: `.DS_Store`, `.env*`, `*.pem`, `*.key`, `node_modules/`, `.claude/settings.local.json`, `_site/`). If a file is tracked but should be ignored, `git rm --cached` it.
5. **Report** findings as a table (file:line, pattern, severity) without printing the secret values themselves (mask them). 
   - If anything sensitive is found in **history**, do not push. Explain the options (rewrite history with `git filter-repo`, or publish from a fresh history) and ask the user how to proceed. Rotate-the-credential advice always applies.
   - If the tree is clean, say so and continue.

## Step 2: README

Create or update `README.md` (if one exists, preserve user-written content and edit rather than overwrite). Include:

- Title and a one-line description (IT PMO Kanban board for a fictitious bank, demo/training tool).
- Live demo link: `https://<owner>.github.io/<repo>/` and CI status badge: `![CI/CD](https://github.com/<owner>/<repo>/actions/workflows/ci-cd.yml/badge.svg)`.
- Features: four-column board (statuses), add/move/delete tasks, drag and drop, filters and summary, overdue badges, FormSubmit notification on new tasks.
- Tech and constraints: single-file vanilla HTML/CSS/JS, no build, no dependencies, no external resources, no persistence (refresh resets the board).
- Run locally: `open index.html`.
- FormSubmit note: one-time email activation is required before notifications are delivered; until then a warning toast is expected.
- Deployment: GitHub Actions deploys to GitHub Pages on every push to `main`.
- Project structure and licence/disclaimer (fictitious data, demo only).

Derive facts from `index.html` and `CLAUDE.md`; do not invent features.

## Step 3: GitHub Actions CI/CD

Create `.github/workflows/ci-cd.yml` (update if it exists). Requirements:

- Triggers: `push` to `main`, `pull_request` to `main`, and `workflow_dispatch`.
- Top-level `permissions: contents: read`; the deploy job adds `pages: write` and `id-token: write`. Use a `concurrency` group `pages` with `cancel-in-progress: false`.
- **`validate` job** (runs on push and PR), plain shell, no third-party actions beyond `actions/checkout`:
  - `index.html` exists and is non-empty.
  - Fails if `index.html` contains `localStorage`, `sessionStorage`, `indexedDB`, `document.cookie`, `alert(`, `confirm(` or `!important`.
  - Fails if it references external resources (`src=`/`href=`/`url(` pointing at `http(s)://` other than the FormSubmit endpoint).
  - Basic secret scan of the repo (private-key headers, `AKIA…`, `ghp_…`, `github_pat_…`) that fails the build on a hit.
  - Optionally extracts the inline `<script>` and runs `node --check` on it for a syntax check.
- **`deploy` job** (only on push to `main`, `needs: validate`): copy `index.html` into a `_site/` directory (so only the app is published, not `.claude/`, `CLAUDE.md` etc.), then `actions/configure-pages`, `actions/upload-pages-artifact` (path `_site`), and `actions/deploy-pages`, with `environment: github-pages` and the page URL as output. Use current major versions of the official actions.

## Step 4: Commit and push (ask first)

Pushing publishes the code, so **show the user a summary and wait for an explicit yes** before this step: the target repo, the files to be committed (`git status --short`), and the security scan result.

After confirmation:

1. Make sure the branch is `main` (`git branch -M main` if appropriate).
2. Set the remote: if `origin` is missing, `git remote add origin <url>`; if it points elsewhere, ask before changing it.
3. Stage by explicit file name (never blind `git add -A` after the scan), commit with a clear message, and push: `git push -u origin main`. Never force-push; if the push is rejected because the remote has commits, explain and ask how to proceed (e.g. pull/rebase).
4. If the repo does not exist, tell the user to create it (or ask before running `gh repo create`).

## Step 5: GitHub Pages

- Enable Pages with the Actions source (skip if already enabled):
  ```bash
  gh api -X POST repos/<owner>/<repo>/pages -f build_type=workflow
  ```
  If it returns 409 (already exists), run `gh api -X PUT repos/<owner>/<repo>/pages -f build_type=workflow` instead. If it fails for plan/permission reasons (e.g. Pages unavailable on a private repo), report that and tell the user what to change in Settings → Pages.
- Watch the first run: `gh run list --limit 1`, then `gh run watch <id> --exit-status`. If it fails, read `gh run view <id> --log-failed`, fix the workflow, and push again.
- Verify the site responds: `curl -sI https://<owner>.github.io/<repo>/ | head -1` (retry a few times; first deploys can take a minute).

## Step 6: Repo About section

Set the description, homepage (the Pages link) and topics in one go:

```bash
gh repo edit <owner>/<repo> \
  --description "IT PMO Kanban board for a fictitious bank: single-file vanilla HTML/CSS/JS demo" \
  --homepage "https://<owner>.github.io/<repo>/" \
  --add-topic kanban --add-topic pmo --add-topic vanilla-js --add-topic github-pages --add-topic demo
```

Then confirm with `gh repo view <owner>/<repo> --json description,homepageUrl,repositoryTopics`.

## Step 7: Final report

Give the user a short summary:

- Security scan result (and anything they should fix or rotate).
- Repo URL, Pages URL, and latest workflow run status.
- What was created or changed (README, workflow, `.gitignore`, About section).
- Reminders: FormSubmit activation is still pending until the confirmation email link is clicked; the board resets on refresh by design.

## Rules

- Never print, log or commit secret values; mask them in reports.
- Never force-push, delete branches, delete repos or change repo visibility.
- Never skip Step 1 or push while it has unresolved findings.
- Keep to the project's hard constraints in `CLAUDE.md`; don't add dependencies or build tooling.
