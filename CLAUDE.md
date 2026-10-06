# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A single-file IT PMO Kanban board for a fictitious bank. It is an internal demo/training tool. The whole app is `index.html`, with markup, a `<style>` block and a `<script>` block inline.

There is no build, lint or test tooling, and no package manager. To run it, open `index.html` directly (`open index.html`). No server is needed.

## Hard constraints (from the original brief)

- Vanilla HTML/CSS/JS only: no frameworks, no bundler, no npm, no build step.
- No external resources: no CDN, no web fonts, no image files. Use the system font stack and inline SVG or Unicode glyphs.
- No persistence: no `localStorage`, `sessionStorage`, `IndexedDB` or cookies. A refresh resets the board to the seed data, and the header note says so.
- The only network call is the FormSubmit AJAX endpoint (`FORMSUBMIT_ENDPOINT`). The notification email address must appear nowhere else.
- No `alert()`, `confirm()` or `!important`. Use inline error text, toasts and the inline "Delete? Yes / No" toggle instead.
- Corporate blue palette only. Use the CSS custom properties in `:root` for colours and spacing.

## Architecture

- **State is the single source of truth.** `state = { tasks, filters }` holds the data. Transient UI state lives in module-level lets (`confirmingDeleteId`, `draggedId`, `idCounter`).
- **Render from state.** `renderBoard()` rebuilds every column's card list and calls `renderDashboard()`. `renderCard()` returns HTML strings. Do not mutate card DOM directly. Change state, then call `renderBoard()`.
- **Mutations** are `addTask`, `moveTask` and `deleteTask`. All of them re-render.
- **Event delegation.** The board has one set of listeners (click/change for delete and move, plus the drag events), so listeners survive re-renders. Cards and controls are found through `data-action` and `data-id`. The columns carry `data-status`, which is the drop target value.
- **Escaping.** Every user-supplied string must go through `escapeHtml()` before it enters an HTML string. Tests such as `isOverdue` compare ISO `YYYY-MM-DD` strings directly.
- **Add-task flow** (`handleSubmit`): validate, then add the card optimistically and close the modal. After that, `notifyNewTask` runs in try/catch/finally, so a FormSubmit failure only produces a warning toast and never breaks the board.
- **Seed data** is built in `seedTasks()` with dates relative to today. This keeps the overdue badge visible on the demo whenever it is opened.
- The status, priority, project and category option lists (`STATUSES`, `PRIORITIES`, `PROJECTS`, `CATEGORIES`) are used for both select options and validation. The four columns are also hard-coded in the HTML, so adding a status means updating both.

## FormSubmit

`FORMSUBMIT_ENDPOINT` at the top of the script is a placeholder address. FormSubmit needs one-time activation: the first submission emails a confirmation link to that address, and deliveries only start once it is clicked. Until then, or with the placeholder, the request fails and the warning toast shows, which is expected.
