---
name: committing
description: How to write commit messages for this project. Use when committing changes.
---

# Committing

This project uses [scoped commits](https://scopedcommits.com/) — the style used
by Linux, Git, Go, FreeBSD, and NixOS.

## Format

```
scope: short summary limited to 50 chars

Required descriptive body wrapped at 80 characters. Explain what changed and
why without being verbose.
```

## Scope

The scope leads the subject because it says *where* the change lives, which is
what a contributor, reviewer, or someone bisecting an incident actually needs.
Use the package or subsystem name, e.g. `fmt`, `lsp`, `parser`. Match whatever
convention the surrounding history already uses; nest with `/` when it helps
(e.g. `net/http: ...`). Omit the scope only when no single one fits.

The summary is a plain description of the change. A clear one already conveys
whether something is a fix, a feature, or a refactor — e.g.
`svg: prevent namespaced <style> elements from being stripped` reads plainly as
a bugfix. Keep the summary free of category labels; spend the space on the
description.

## Rules

- First line: imperative mood, lowercase, no period, maximum 50 characters
- Body: required, descriptive but not verbose, wrapped at 80 characters
- Body should be separated from the first line by a blank line
- Body should be a concise paragraph, not bullet points
- Even routine fixes should include a short body explaining why the change
  was made

The 80-character wrapping applies to **commit messages only** — plain text in
a terminal. Do not carry it over to anything rendered as markdown. PR
descriptions, issue comments, and review replies should let prose flow as
unbroken lines per paragraph; hard-wrapping them inserts ugly mid-sentence
breaks in the rendered output.

## No Amending

Never use `git commit --amend`. Always create a new commit. Separate
commits are easier to review, revert, and reason about.

If you have been explicitly told to amend, you can amend.

## Commit from a File

Instead of using `git commit -m`, write your commit message with word wrapping
and proper formatting to a temporary file and use the `-F` flag.

## Granularity

Each commit should contain exactly one logical change. If a task
involves multiple distinct changes (e.g. a refactor, a new feature,
a formatter fix, and a new skill file), split them into separate
commits. Each commit should only stage its relevant files — avoid
`git add .` or staging unrelated changes. A good test: could you
write a clear, single-purpose subject line? If not, split it up.

## Staging

Stage specific files with `git add <file>...`. Do **not** use
`git add -p` — it requires interactive input and will hang.

If you need to commit only part of a file's changes, write the
file so it contains only the changes for the current commit, commit
it, then make the remaining changes afterward.

## CAUTION

If you encounter unknown changes, DO NOT remove them - ask the user first.

## Signoff

Always commit with `-s` to sign off the commit, which is required for DCO
checks.

Never add a `Co-authored-by:` line. Only include the sign-off; do not pollute
commit messages with marketing trailers.
