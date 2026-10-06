# IT PMO Project Board

![CI/CD](https://github.com/polarity-i/claude-training/actions/workflows/ci-cd.yml/badge.svg)

A single-file Kanban board for an IT PMO at a fictitious bank. It is an internal demo and training tool.

**Live demo:** https://polarity-i.github.io/claude-training/

## Features

- Four columns: **Backlog**, **In Progress**, **Blocked**, **Done**
- Add, move and delete tasks (move via drag and drop or the per-card "Move" menu; delete uses an inline Yes / No confirmation)
- Filter by project, assignee and priority
- Summary bar with task counts and an **Overdue** count, plus an overdue badge on late cards
- Email notification for each new task through [FormSubmit](https://formsubmit.co)

## Tech and constraints

- Vanilla HTML, CSS and JavaScript in one file, `index.html`
- No build step, no dependencies, no frameworks
- No external resources (no CDN, web fonts or images)
- No persistence: refreshing the page resets the board to the seed data

## Run locally

```bash
open index.html
```

No server is needed.

## FormSubmit notifications

`FORMSUBMIT_ENDPOINT` at the top of the script is a placeholder. To receive emails, set it to your own address. FormSubmit needs one-time activation: the first submission sends a confirmation link to that address, and deliveries start once it is clicked. Until then, or with the placeholder, the request fails and the board shows a warning toast. This is expected and does not break the board.

## Deployment

A GitHub Actions workflow (`.github/workflows/ci-cd.yml`) validates `index.html` on every push and pull request. On pushes to `main` it deploys the page to GitHub Pages.

## Project structure

```
index.html                       the whole app
CLAUDE.md                        project guidance for Claude Code
.github/workflows/ci-cd.yml      CI checks and Pages deployment
.claude/commands/                custom Claude Code commands
```

## Disclaimer

All data is fictitious and the project is for demo and training use only.
