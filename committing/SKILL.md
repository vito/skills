---
name: committing
description: How to write commit messages for this project. Use when committing changes.
---

# Committing

This project uses [Conventional Commits](https://www.conventionalcommits.org/).

## Format

```
type(scope): short summary limited to 50 chars

Required descriptive body wrapped at 80 characters. Explain what changed and
why without being verbose.
```

## Types

- `feat` — new feature
- `fix` — bug fix
- `chore` — maintenance (deps, golden files, etc.)
- `style` — formatting, no logic change
- `test` — adding or updating tests
- `refactor` — restructuring without behavior change

## Scope

The scope is optional but preferred when the change is localized. Use
the package or subsystem name, e.g. `fmt`, `lsp`, `parser`.

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
